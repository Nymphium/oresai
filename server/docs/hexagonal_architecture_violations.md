# Hexagonal Architecture Violations Report

This document outlines the violations of the hexagonal architecture principles found in the project's codebase.

## Summary

A clear violation was identified where the **infrastructure layer (`infra`) directly depends on the application layer (`app`)**. This is against the core principle of hexagonal architecture, where dependencies should always point inwards (from outer layers like `infra` to inner layers like `domains`).

## Violation Details

### 1. Invalid Dependency in `infra/dune`

The `dune` file for the `infra` library explicitly declares a dependency on `oresai.app.usecases`.

**File:** `infra/dune`
```dune
(library
 (name infra)
 (public_name oresai.infra)
 (libraries oresai.let oresai.domains oresai.app.usecases))
```

This declaration allows modules in the `infra` layer to access and use modules from the `app` layer, which is a structural violation of the dependency rule.

### 2. Usage of Application Layer Type in Infrastructure Code

The most direct evidence of this violation was found in `infra/services/context.ml`, where a type defined in the application layer is used.

**File:** `infra/services/context.ml`
```ocaml
let conn : (Caqti_eio.connection, Errors.t) Caqti_eio.Pool.t Eio.Fiber.key =
  Eio.Fiber.create_key ()
;;
```

Here, `Errors.t` is a type defined in `app/usecases/errors.ml`. The infrastructure layer, which is responsible for database connections (`Caqti_eio.connection`), should not have direct knowledge of types defined in the application layer.

## Architectural Principles and Correction Proposal

### Correct Dependency Flow

In a hexagonal architecture:
- The **`domains`** layer should be at the core, containing the business logic and entities. It should not depend on any other layer.
- The **`app`** layer (use cases) depends on `domains`. It orchestrates the business logic to fulfill specific application needs.
- The **`infra`** and **`interface`** layers are on the outside. They depend on the `app` and `domains` layers (specifically, on the ports/interfaces defined in the inner layers).

The dependency `infra` -> `app` is a violation of this principle.

### Proposed Correction

1.  **Decouple the Error Types:**
    - The `infra` layer should not directly use `Errors.t` from the `app` layer.
    - Instead, the database connection pool in `infra/services/context.ml` should use an error type defined within the `domains` layer (e.g., `Domains.Errors.t`) or a generic error type.

2.  **Modify `infra/services/context.ml`:**
    - Change the type definition to remove the dependency on `app`'s `Errors.t`. For example:
      ```ocaml
      (* Before *)
      let conn : (Caqti_eio.connection, Errors.t) Caqti_eio.Pool.t Eio.Fiber.key = ...

      (* After (Example using a domain error) *)
      let conn : (Caqti_eio.connection, Domains.Errors.t) Caqti_eio.Pool.t Eio.Fiber.key = ...
      ```

3.  **Remove Invalid Dependency from `infra/dune`:**
    - After refactoring the code to remove the direct dependency, update `infra/dune` to remove `oresai.app.usecases` from the list of libraries.
      ```dune
      (* Before *)
      (libraries oresai.let oresai.domains oresai.app.usecases)

      (* After *)
      (libraries oresai.let oresai.domains)
      ```

By implementing these changes, the project structure will better align with the principles of hexagonal architecture, leading to a more maintainable and decoupled codebase.
