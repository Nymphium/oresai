# Data Hierarchy

This document outlines the data hierarchy of the Oresai application, based on the OCaml source code in the `domains/objects` directory.

## Core Entities

The application revolves around four main entities:

1.  **Organization**: A top-level entity that groups users and documents.
2.  **User**: An individual user account.
3.  **User Profile**: Contains additional information about a user.
4.  **Document**: A document created by a user within an organization.

## Entity Relationships

The entities are related as follows:

- A **User** can be a member of an **Organization**.
- A **User** has one **User Profile**.
- A **Document** belongs to one **Organization**.
- A **Document** has one **Author**, who is a **User**.

## Detailed Entity Definitions

### Organization

- **File**: `domains/objects/organization.ml`
- **Type**: `Organization.t`

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Unique identifier for the organization. |
| `name` | `string` | Name of the organization (1-100 characters). |
| `created_at` | `int64` | Unix timestamp of when the organization was created. |

### User

- **File**: `domains/objects/user.ml`
- **Type**: `User.t`

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Unique identifier for the user. |
| `name` | `string` | Name of the user (0-100 characters). |
| `email` | `string` | Email address of the user (must be a valid email format). |
| `created_at` | `int64` | Unix timestamp of when the user was created. |

### User Profile

- **File**: `domains/objects/user_profile.ml`
- **Type**: `User_profile.t`

| Field | Type | Description |
| :--- | :--- | :--- |
| `user_id` | `int` | Foreign key referencing the `User.id`. |
| `nickname` | `string` | Nickname of the user (1-100 characters). |
| `profile` | `string` | A short bio or profile description (0-500 characters). |
| `birth_date` | `int64` | Unix timestamp of the user's birth date. |

### Document

- **File**: `domains/objects/document.ml`
- **Type**: `Document.t`

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | Unique identifier for the document. |
| `organization` | `int` | Foreign key referencing the `Organization.id`. |
| `title` | `string` | Title of the document (1-255 characters). |
| `author_id` | `int` | Foreign key referencing the `User.id` of the author. |
| `content` | `string` | The main content of the document (1-1,000,000 characters). |
| `created_at` | `int64` | Unix timestamp of when the document was created. |
| `updated_at` | `int64` | Unix timestamp of when the document was last updated. |

## Type System (`util.ml`)

The type system uses two main functors to create validated types:

- **`Iso`**: Creates an isomorphic type, essentially a type alias. This is used for creating distinct types for IDs and timestamps to improve type safety.
- **`Hom`**: Creates a type with an associated validator. The `from` function for a `Hom`-based type will return a `Result` type, either with the valid value or a `ConvertError`. This is used to enforce constraints on string lengths, formats, etc.
