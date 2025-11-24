# PROJECT CONTEXT & ARCHITECTURAL GUIDELINES

You are an expert Senior Software Architect and Frontend Engineer.
Your goal is to implement a frontend application using **TypeScript + Vite + React Router v7** with a specific directory structure.
The project integrates **Connect (gRPC)** for SSR data fetching, with Protocol Buffer definitions managed at the project root.

## 1. Project Structure

The project follows a specific flat structure where the root acts as the main package.
**Strictly adhere to this layout:**

```text
/(root)
├── .env                # Environment variables (Node.js)
├── .envrc              # Direnv configuration
├── buf.yaml            # Buf v2 Module Config
├── buf.gen.yaml        # Buf v2 Generation Config
├── protos/             # Source .proto files (Symlinked to ../protos)
├── package.json        # Main dependencies (Vite, React, Connect)
├── tsconfig.json
├── vite.config.ts
└── app/                # Main Application Source
    ├── gen/            # Protobuf output target (Generated TS)
    ├── routes/         # React Router v7 Routes (CSR + SSR)
    └── server/         # SSR-only utilities & gRPC Client setup
````

## 2\. Tech Stack

  * **Environment:** `direnv` for env management.
  * **Framework:** Vite + React Router v7 (SSR/Framework Mode).
  * **Schema Tools:** **Buf (v2)**.
  * **RPC Runtime:**
      * `@connectrpc/connect-node` (SSR/Server-side).
      * `@connectrpc/connect` (Client - strict type usage only).
      * **Protocol:** gRPC (HTTP/2) for backend communication.
  * **Language:** TypeScript.

## 3\. Implementation Rules

### A. Schema & Generation (Root Level)

1.  **Source:** `.proto` files are in `(root)/protos/`.
2.  **Config:** `buf.yaml` and `buf.gen.yaml` (v2) are in `(root)/`.
3.  **Generation Strategy:**
      * Configure `buf.gen.yaml` to output generated files to **`app/gen/`**.
      * **Plugins:** Use `local` plugins (installed in `package.json` devDependencies):
          * `protoc-gen-es`
          * `protoc-gen-connect-es`
      * **Command:** Run `buf generate` from the root.

### B. Server-Side gRPC (BFF Layer)

1.  **Location:** All gRPC client logic must reside in **`app/server/`**.
2.  **Transport:** Use `createGrpcTransport` from `@connectrpc/connect-node`.
      * **Protocol:** Must use `httpVersion: "2"` to communicate with standard gRPC backends.
      * **Endpoint:** Read from `process.env.GRPC_ENDPOINT` (managed via `.env` / `.envrc`).
3.  **Isolation:** Files in `app/server/` should ideally have `.server.ts` extension or be imported **only** by `loader`/`action` functions to prevent browser bundling errors.

### C. Data Flow

1.  **Loaders (`app/routes/**`):**
      * Import the gRPC client from `~/server/client.server`.
      * Fetch data via gRPC.
      * **Boundary:** Convert/Simplify the response to a Plain Object (POJO) if necessary.
2.  **Components:**
      * Receive data via `useLoaderData`.
      * **Constraint:** The browser bundle must **NEVER** include `@connectrpc/connect-node` or generated client implementations, only the *types*.

## 4\. Coding Standards

  * **Imports:** Use path aliases (e.g., `~/*` mapping to `app/*`) for clean imports.
      * Example: `import { User } from "~/gen/user_pb";`
  * **Env Vars:** `.env` is loaded via envrc with direnv.
  * **Buf Config:** Always use `version: v2`.

## 5\. Example Pattern

**1. Buf Config (`root/buf.gen.yaml`)**

```yaml
version: v2
plugins:
  - local: protoc-gen-es
    out: app/gen
    opt: target=ts
  - local: protoc-gen-connect-es
    out: app/gen
    opt: target=ts
```

**2. gRPC Client (`app/server/client.server.ts`)**

```typescript
import { createGrpcTransport } from "@connectrpc/connect-node";
import { createPromiseClient } from "@connectrpc/connect";
import { UserService } from "~/gen/user_connect"; 

const transport = createGrpcTransport({
  baseUrl: process.env.GRPC_ENDPOINT ?? "http://localhost:50051",
  httpVersion: "2",
});

export const userClient = createPromiseClient(UserService, transport);
```

**3. Route Loader (`app/routes/home.tsx`)**

```typescript
import type { Route } from "./+types/home";
import { userClient } from "~/server/client.server";

// SSR (Node.js)
export async function loader({ params }: Route.LoaderArgs) {
  const { user } = await userClient.getUser({ id: "123" });
  // Return plain JSON
  return { user };
}

// CSR (Browser)
export default function Home({ loaderData }: Route.ComponentProps) {
  return <h1>{loaderData.user?.name}</h1>;
}
```

## 6\. Instruction for Agent (Step-by-Step)

1.  **Environment Setup:**
      * Verify `package.json` contains `protoc-gen-es`, `protoc-gen-connect-es`, `@bufbuild/buf`.
      * Ensure `.envrc` is present (or `.env` created).
2.  **Schema Generation:**
      * Create/Verify `buf.yaml` (v2) and `buf.gen.yaml` (v2) at root.
      * Configure output to `app/gen`.
      * Run generation command to populate `app/gen`.
3.  **Server Implementation:**
      * Create `app/server/client.server.ts`.
      * Implement `createGrpcTransport` (HTTP/2).
4.  **Route Integration:**
      * Create a sample route in `app/routes/` that consumes the gRPC client.
      * Ensure imports use `~` aliases correctly.
