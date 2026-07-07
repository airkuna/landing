// Local Bun server for verifier A2. Reads config from process.env (see .dev.vars.example).
//   bun run src/server.ts        (or: bun run dev  for --hot)
import { handle } from "./app.ts";

const port = Number(process.env.PORT ?? 8787);

Bun.serve({
  port,
  fetch(request) {
    return handle(request, process.env as Record<string, string | undefined>);
  },
});

console.log(`verifier-a2 listening on http://localhost:${port} (mode=${process.env.MODE ?? "mock"})`);
