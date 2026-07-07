// eID id_token verification. Borrows the prod pattern from
// domovina-api/supabase/functions/certilia/index.ts (JWKS + iss + aud):
//   - prod: fetch Certilia OIDC discovery → remote JWKS → jwtVerify(iss, aud)
//   - mock: verify against the embedded mock-issuer public key (self-contained e2e)
//
// The OIB never leaves this module except as a nullifier (see nullifier.ts).
import {
  createRemoteJWKSet,
  importJWK,
  jwtVerify,
  type JWTPayload,
  type JWTVerifyGetKey,
  type KeyLike,
} from "jose";
import { acrToLoa, MOCK_AUDIENCE, MOCK_ISSUER_URL, type Config } from "./config.ts";

export interface VerifiedIdentity {
  oib: string;
  loa: number;
  firstName?: string;
  lastName?: string;
  acr?: string;
}

// prod: cached remote JWKS + canonical issuer from discovery (issuer in the token
// is discovery.issuer, NOT the base URL — same caveat as domovina-api).
let _jwks: JWTVerifyGetKey | null = null;
let _issuer: string | null = null;
async function getProdOidc(cfg: Config) {
  if (_jwks && _issuer) return { jwks: _jwks, issuer: _issuer };
  const discoveryUrl = `${cfg.certiliaIssuer}/oauth2/oidcdiscovery/.well-known/openid-configuration`;
  const disc = await fetch(discoveryUrl).then((r) => r.json());
  if (!disc?.jwks_uri || !disc?.issuer) throw new Error("certilia_discovery_failed");
  _jwks = createRemoteJWKSet(new URL(disc.jwks_uri));
  _issuer = disc.issuer as string;
  return { jwks: _jwks, issuer: _issuer };
}

// mock: import the embedded public key once.
let _mockKey: KeyLike | Uint8Array | null = null;
async function getMockKey(cfg: Config) {
  if (_mockKey) return _mockKey;
  const jwk = JSON.parse(cfg.mockIssuerJwk);
  // strip the private scalar so we only ever hold the public key here
  const pub = { kty: jwk.kty, crv: jwk.crv, x: jwk.x, alg: jwk.alg, kid: jwk.kid };
  _mockKey = await importJWK(pub, "EdDSA");
  return _mockKey;
}

export async function verifyIdToken(idToken: string, cfg: Config): Promise<VerifiedIdentity> {
  let payload: JWTPayload;
  if (cfg.mode === "prod") {
    const { jwks, issuer } = await getProdOidc(cfg);
    ({ payload } = await jwtVerify(idToken, jwks, { issuer, audience: cfg.certiliaClientId }));
  } else {
    const key = await getMockKey(cfg);
    ({ payload } = await jwtVerify(idToken, key, { issuer: MOCK_ISSUER_URL, audience: MOCK_AUDIENCE }));
  }

  // Certilia prod: OIB arrives as `sub` (11 digits), not `pin`. Same order as domovina-api.
  const oib = (payload.pin ?? (payload as Record<string, unknown>).oib ?? payload.sub) as
    | string
    | undefined;
  if (!oib) throw new Error("no_oib_claim");

  const acr = payload.acr as string | undefined;
  return {
    oib,
    loa: acrToLoa(acr),
    firstName: (payload.given_name ?? (payload as Record<string, unknown>).firstname) as string | undefined,
    lastName: (payload.family_name ?? (payload as Record<string, unknown>).lastname) as string | undefined,
    acr,
  };
}
