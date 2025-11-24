# PROJECT CONTEXT & ARCHITECTURAL GUIDELINES

You are an expert Senior Software Architect and Frontend Engineer.
Your goal is to build a **Monorepo** project using **pnpm workspaces**.
The project consists of central Protocol Buffer definitions (at the root) and a main frontend application using **Vite + React Router v7**.

## 1. Monorepo Structure

The **Schema Definitions (`protos`) and Buf Configuration** reside at the **Project Root**, acting as the contract for the entire repository.
The **Generated Code** is output into a shared package (`packages/api-schema`).

```text
root/
├── buf.yaml            # Buf v2 Module Config
├── buf.gen.yaml        # Buf v2 Generation Config
├── protos/             # Source .proto files
├── pnpm-workspace.yaml
├── package.json
├── packages/
│   └── api-schema/     # OUTPUT TARGET for generated code
│       ├── src/        # (Generated TS files go here)
│       └── package.json
└── apps/
    └── web/            # Main Application (Vite + React Router v7)
        ├── app/
        │   ├── routes/
        │   └── grpc/   # SSR gRPC Client setup
        └── package.json
````

## 2\. Tech Stack

  * **Manager:** pnpm (Workspaces enabled).
  * **Schema Tools:** **Buf (v2)** (Root-level configuration).
  * **Code Generators:**
      * `@connectrpc/protoc-gen-connect-es`
      * `@bufbuild/protoc-gen-es`
  * **App Package (`apps/web`):**
      * Framework: Vite + React Router v7 (SSR/Framework Mode).
      * Communication: `@connectrpc/connect-node` (Server-side only) using **gRPC Protocol**.
      * Dependency: Depends on `packages/api-schema` via `workspace:*`.

## 3\. Detailed Implementation Rules

### A. Schema & Generation (Root Level)

1.  **Source:** `.proto` files are in `root/protos/`.
2.  **Config:** `buf.yaml` and `buf.gen.yaml` (v2) are in `root/`.
3.  **Generation Strategy:**
      * Configure `buf.gen.yaml` to output files to `packages/api-schema/src`.
      * **Plugins:** Use `local` plugins (installed in root `package.json` devDependencies) to ensure version consistency.
      * **Command:** Run `pnpm exec buf generate` from the root.

### B. Package: `packages/api-schema`

1.  **Role:** Container for the generated TypeScript code.
2.  **Content:** It should contain mostly the `src/` folder (generated) and a `package.json`.
3.  **Exports:** `package.json` must export the generated code (e.g., `"main": "./src/index.ts"`).
4.  **Package Name:** `@my-org/api-schema`.

### C. Package: `apps/web` (The BFF & UI)

1.  **Dependencies:**
      * `"@my-org/api-schema": "workspace:*"`
      * `@connectrpc/connect`, `@connectrpc/connect-node`, `@bufbuild/protobuf`.
2.  **Network Architecture (Crucial):**
      * **Backend:** External gRPC server (Default: `localhost:50051`).
      * **SSR (BFF):** Node.js environment using **Connect Node Transport** configured for **gRPC (HTTP/2)**.
      * **CSR:** Receives JSON only via React Router loaders.
3.  **Client Setup (`apps/web/app/grpc/client.server.ts`):**
      * Import Service definitions from `@my-org/api-schema`.
      * Use `createGrpcTransport` (NOT `createConnectTransport`) with `httpVersion: "2"`.
      * **Must** be a `.server.ts` file to prevent bundling in the browser.

## 4\. Coding Standards

  * **File Naming:** Any file importing `@connectrpc/connect-node` or `http2` MUST end in `.server.ts`.
  * **Environment:** Use `process.env.GRPC_ENDPOINT` in `apps/web`.
  * **Buf Config:** Always use `version: v2`.

## 5\. Example Pattern

**1. Root Buf Config (`root/buf.gen.yaml`)**

```yaml
version: v2
plugins:
  - local: protoc-gen-es
    out: packages/api-schema/src
    opt: target=ts
  - local: protoc-gen-connect-es
    out: packages/api-schema/src
    opt: target=ts
```

**2. App Client (`apps/web/app/grpc/client.server.ts`)**

```typescript
import { createGrpcTransport } from "@connectrpc/connect-node";
import { createPromiseClient } from "@connectrpc/connect";
import { UserService } from "@my-org/api-schema"; 

const transport = createGrpcTransport({
  baseUrl: process.env.GRPC_ENDPOINT ?? "http://localhost:50051",
  httpVersion: "2", // Required for standard gRPC backends
});

export const userClient = createPromiseClient(UserService, transport);
```

**3. App Route (`apps/web/app/routes/home.tsx`)**

```typescript
import type { Route } from "./+types/home";
import { ConnectError, Code } from "@connectrpc/connect";
import { userClient } from "~/grpc/client.server";

// SSR Loader (Node.js)
export async function loader({ params }: Route.LoaderArgs) {
  try {
    const response = await userClient.getUser({ id: "123" });
    return { user: response.user }; 
  } catch (err) {
    if (err instanceof ConnectError && err.code === Code.NotFound) {
        throw data("User Not Found", { status: 404 });
    }
    throw data("Internal Error", { status: 500 });
  }
}

export default function Home({ loaderData }: Route.ComponentProps) {
  return <h1>Hello, {loaderData.user?.name}</h1>;
}
```

## 6\. Instruction for Agent (Step-by-Step)

1.  **Project Initialization:**
      * Create `pnpm-workspace.yaml`.
      * Create `package.json` at root.
      * Create directories `packages/api-schema` and `apps/web`.
2.  **Schema Setup (Root):**
      * Place `protos/` at root.
      * Install `@bufbuild/buf`, `@connectrpc/protoc-gen-connect-es`, `@bufbuild/protoc-gen-es` in **Root** `devDependencies`.
      * Create `buf.yaml` (v2) at root (modules: `protos`).
      * Create `buf.gen.yaml` (v2) at root (output: `packages/api-schema/src`).
      * Initialize `packages/api-schema/package.json`.
      * Run `pnpm exec buf generate` to verify generation into the package.
3.  **App Setup:**
      * Initialize `apps/web` with Vite + React Router v7.
      * Add `"@my-org/api-schema": "workspace:*"` to dependencies.
      * Install `@connectrpc/connect` and `@connectrpc/connect-node`.
4.  **Integration:**
      * Implement `app/grpc/client.server.ts`.
      * Create a route loader and test the flow.
