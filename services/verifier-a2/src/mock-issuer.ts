// Mock eID issuer (DEV ONLY) — stands in for Certilia so the MVP e2e runs with no
// state infrastructure (docs/18 "Mock harness"). Issues a signed test PID
// {ime, prezime, OIB} as an OIDC id_token (EdDSA), with iss/aud/acr that the
// verifier checks exactly like a real Certilia token.
import { importJWK, SignJWT } from "jose";
import { MOCK_AUDIENCE, MOCK_ISSUER_URL, type Config } from "./config.ts";

export interface MockPid {
  oib: string;
  ime?: string;
  prezime?: string;
  acr?: string; // default eIDAS High
}

let _signKey: Awaited<ReturnType<typeof importJWK>> | null = null;
async function getSignKey(cfg: Config) {
  if (_signKey) return _signKey;
  const jwk = JSON.parse(cfg.mockIssuerJwk);
  _signKey = await importJWK(jwk, "EdDSA");
  return _signKey;
}

/** Issue a mock Certilia-style id_token. sub = OIB (mirrors Certilia prod). */
export async function issueMockPid(pid: MockPid, cfg: Config): Promise<string> {
  const key = await getSignKey(cfg);
  return await new SignJWT({
    given_name: pid.ime,
    family_name: pid.prezime,
    acr: pid.acr ?? "https://eidas.europa.eu/LoA/high",
  })
    .setProtectedHeader({ alg: "EdDSA", kid: "mock-issuer-1" })
    .setIssuer(MOCK_ISSUER_URL)
    .setAudience(MOCK_AUDIENCE)
    .setSubject(pid.oib) // OIB in `sub`, exactly like Certilia
    .setIssuedAt()
    .setExpirationTime("10m")
    .sign(key);
}
