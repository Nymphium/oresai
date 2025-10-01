module Fwd = Domains.Values

module Model = struct
  module Url = Morph.Hom (struct
      module M = Fwd.Url

      let typ = Caqti_type.string
    end)
end
