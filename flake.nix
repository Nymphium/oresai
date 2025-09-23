{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
    opam-repository = {
      url = "github:ocaml/opam-repository";
      flake = false;
    };

    flake-utils.url = "github:numtide/flake-utils";

    opam-nix = {
      url = "github:tweag/opam-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        opam-repository.follows = "opam-repository";
      };
    };
  };
  outputs =
    {
      flake-utils,
      opam-nix,
      nixpkgs,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        formatter = pkgs.nixfmt-rfc-style;

        base = {
          devShells.default = pkgs.mkShellNoCC {
            packages = [
              formatter
              pkgs.buf
              pkgs.actionlint
              pkgs.nil

              pkgs.postgresql
              pkgs.atlas
            ];
          };
        };

        server =
          let
            src = ./server;

            on = opam-nix.lib.${system};
            localPackages =
              with builtins;
              filter (f: !isNull f) (
                map (
                  f:
                  let
                    f' = match "(.*)\.opam$" f;
                  in
                  if isNull f' then null else elemAt f' 0
                ) (attrNames (readDir src))
              );

            devPackagesQuery = {
              ocaml-lsp-server = "*";
              utop = "*";
            };

            scope =
              let
                localPackagesQuery =
                  with builtins;
                  listToAttrs (
                    map (p: {
                      name = p;
                      value = "*";
                    }) localPackages
                  );
                query = {
                  ocaml-system = "*";
                  ocamlformat = "*";
                  # If you want to specify a version from .ocamlformat file, uncomment the line below
                  # pkgs.callPackage ./nix/ocamlformat.nix { };
                }
                // devPackagesQuery
                // localPackagesQuery;
              in
              on.buildOpamProject' {
                inherit pkgs;
                resolveArgs = {
                  with-test = true;
                  with-doc = true;
                };
              } src query;

            devPackages = with builtins; attrValues (pkgs.lib.getAttrs (attrNames devPackagesQuery) scope);

            packages.server =
              with builtins;
              listToAttrs (
                map (p: {
                  name = p;
                  value = scope.${p};
                }) localPackages
              );

            devShells = rec {
              ci = pkgs.mkShell {
                inputsFrom = builtins.map (p: scope.${p}) localPackages ++ [ base.devShells.default ];
                packages = [
                  scope.ocamlformat
                ];
              };
              default = pkgs.mkShell {
                inputsFrom = [ ci ];
                packages = devPackages;
              };
            };
          in
          {
            inherit devShells packages;
          };
      in
      {
        legacyPackages = pkgs;
        packages = {
          server = server.packages;
        };

        inherit formatter;
        devShells = base.devShells // {
          server = server.devShells;
        };
      }
    );
}
