// verifier A2 — Worker-compatible fetch handler. Same code runs on Cloudflare
// (export default { fetch }) and locally under Bun (src/server.ts).
//
// Routes:
//   GET  /health              → liveness + effective mode/chain/signer
//   POST /issue   (mock only) → { oib, ime?, prezime?, acr? } -> { idToken }
//   POST /verify              → { idToken, anchor, chainId?, verifyingContract? }
//                               -> { attestation, proof, signer, fields }
//
// /verify is the A2 oracle: validate the eID token (JWKS/iss/aud), derive the
// nullifier behind the pepper boundary, sign an EIP-712 attestation. The raw OIB
// is never returned or logged.
import { privateKeyToAccount } from "viem/accounts";
import { getAddress, isAddress, type Address } from "viem";
import { loadConfig, type EnvLike } from "./config.ts";
import { verifyIdToken } from "./certilia.ts";
import { computeNullifier, looksLikeOib } from "./nullifier.ts";
import { signAttestation } from "./eip712.ts";
import { issueMockPid } from "./mock-issuer.ts";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function handle(request: Request, env: EnvLike): Promise<Response> {
  const url = new URL(request.url);
  const cfg = loadConfig(env);

  try {
    if (request.method === "GET" && url.pathname === "/health") {
      const signer = privateKeyToAccount(cfg.signerKey).address;
      return json({
        ok: true,
        mode: cfg.mode,
        chainId: cfg.chainId,
        verifyingContract: cfg.verifyingContract ?? null,
        signer,
        attestationTtlSec: cfg.attestationTtlSec,
      });
    }

    if (request.method === "POST" && url.pathname === "/issue") {
      if (cfg.mode !== "mock") return json({ error: "mock_issuer_disabled" }, 403);
      const { oib, ime, prezime, acr } = (await request.json().catch(() => ({}))) as Record<string, string>;
      if (!oib || !looksLikeOib(oib)) return json({ error: "bad_oib", detail: "expect 11 digits" }, 400);
      const idToken = await issueMockPid({ oib, ime, prezime, acr }, cfg);
      return json({ idToken });
    }

    if (request.method === "POST" && url.pathname === "/verify") {
      const body = (await request.json().catch(() => ({}))) as Record<string, string>;
      const { idToken, anchor } = body;
      if (!idToken) return json({ error: "missing_id_token" }, 400);
      if (!anchor || !isAddress(anchor)) return json({ error: "bad_anchor" }, 400);

      const verifyingContract = (body.verifyingContract ?? cfg.verifyingContract) as string | undefined;
      const chainId = body.chainId ? Number(body.chainId) : cfg.chainId;
      if (!verifyingContract || !isAddress(verifyingContract)) {
        return json({ error: "missing_verifying_contract" }, 400);
      }

      // 1. Verify the eID token (signature + iss + aud). Never trust the client.
      const identity = await verifyIdToken(idToken, cfg);

      // 2. Derive the nullifier behind the pepper boundary (raw OIB stops here).
      const nullifier = await computeNullifier(identity.oib, cfg.pepper);

      // 3. Sign the EIP-712 attestation bound to `anchor`.
      const expiry = BigInt(Math.floor(Date.now() / 1000) + cfg.attestationTtlSec);
      const signed = await signAttestation(
        cfg.signerKey,
        chainId,
        getAddress(verifyingContract) as Address,
        { anchor: getAddress(anchor) as Address, nullifier, loa: identity.loa, expiry },
      );

      return json({
        attestation: signed.attestation,
        proof: signed.proof,
        signer: signed.signer,
        loa: identity.loa,
        chainId,
        verifyingContract: getAddress(verifyingContract),
        // NOTE: nullifier is a non-reversible commitment; safe to expose. OIB is not.
        nullifier,
        expiry: signed.fields.expiry,
      });
    }

    if (request.method === "GET" && url.pathname === "/") {
      return json({ service: "airkuna-verifier-a2", routes: ["/health", "POST /issue", "POST /verify"] });
    }

    return json({ error: "not_found" }, 404);
  } catch (e) {
    const msg = String((e as Error)?.message ?? e);
    // Do not echo internals that could contain token contents.
    return json({ error: "verify_failed", detail: msg }, 400);
  }
}

// Cloudflare Worker entrypoint.
export default {
  fetch(request: Request, env: EnvLike): Promise<Response> {
    return handle(request, env);
  },
};
