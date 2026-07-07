# verifier-a2 — thin EIP-712 oracle (eID → onchain personhood)

Verifier **A2** from ADR 0002 / `docs/18`: a single off-chain service that validates a
live eID id_token (Certilia in prod; a **mock issuer** for the MVP), derives
`nullifier = HMAC(OIB, pepper)` behind the pepper boundary, and signs an **EIP-712
attestation** that `IdentityRegistry.claim(...)` verifies via `EIP712Verifier`.

With one signer this is `EIP712Verifier` at N=1, M=1. Adding signers later (the Android
mesh, ADR 0002/0004) is the **same contract** — just more entries in the signatures
array. No interface change.

> The raw OIB never leaves this service — it is hashed the instant it arrives and never
> returned, logged, or stored (whitepaper §7, ADR 0001/0003). `PEPPER`/`SIGNER_KEY` are
> DEV-embedded in mock mode only; in prod they live behind KMS/HSM.

## Routes

| Route | Body | Returns |
|---|---|---|
| `GET /health` | — | `{ ok, mode, chainId, verifyingContract, signer }` |
| `POST /issue` *(mock only)* | `{ oib, ime?, prezime?, acr? }` | `{ idToken }` |
| `POST /verify` | `{ idToken, anchor, chainId?, verifyingContract? }` | `{ attestation, proof, nullifier, loa, signer }` |

`attestation = abi.encode(bytes32 nullifier, uint16 loa, uint64 expiry)`,
`proof = abi.encode(bytes[] signatures)` — feed both straight into `claim()`.

## Run locally (Bun)

```bash
bun install
bun run dev          # http://localhost:8787, MODE=mock (zero setup)
```

Then, from the repo root, prove the whole flow end-to-end against a local EVM:

```bash
# terminal 1: a local chain (same EVM as Chiado)
anvil

# terminal 2: the verifier
cd services/verifier-a2 && bun run dev

# terminal 3: deploy + mock issuer → verify → claim → SBT; dup reverts; migrate works
cd services/verifier-a2 && bun run e2e
```

Point the same e2e at **Gnosis Chiado** with a funded EOA:

```bash
RPC_URL=https://rpc.chiadochain.net PRIVATE_KEY=0x<funded> \
  VERIFIER_URL=http://localhost:8787 bun run e2e
```

## Deploy (Cloudflare Worker)

```bash
wrangler secret put PEPPER
wrangler secret put SIGNER_KEY          # oracle key; its address must be addSigner'd
wrangler secret put MOCK_ISSUER_JWK     # mock mode only
# set VERIFYING_CONTRACT + CHAIN_ID in wrangler.toml [vars]
wrangler deploy
```

## Going to prod (real Certilia)

Set `MODE=prod`, `CERTILIA_ISSUER`, `CERTILIA_CLIENT_ID`. The verifier then fetches the
Certilia OIDC discovery + JWKS and validates `iss`/`aud` exactly like
`domovina-api/supabase/functions/certilia` (the borrowed pattern). Everything else is
unchanged. Move `PEPPER`/`SIGNER_KEY` into KMS/HSM (ADR 0003).

## Files

- `src/config.ts` — env + DEV-only mock defaults, `acrToLoa`
- `src/nullifier.ts` — `HMAC-SHA256(OIB, pepper)` → bytes32
- `src/certilia.ts` — id_token verify (prod JWKS / mock key), OIB + LoA extraction
- `src/eip712.ts` — attestation signing + ABI encoding (matches `EIP712Verifier.sol`)
- `src/mock-issuer.ts` — DEV issuer, signs a test PID id_token
- `src/app.ts` — Worker-compatible fetch handler (routes)
- `src/server.ts` — Bun local server
- `scripts/genkey.ts` — generate mock issuer JWK + signer key
- `scripts/e2e.ts` — full deploy→claim→dup→migrate demonstration
