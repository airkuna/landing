// Generate a fixed Ed25519 JWK for the MOCK issuer (dev only) and a secp256k1
// EIP-712 signer key. Prints env you can paste into .dev.vars / wrangler secrets.
// NEVER use these in production — the real issuer is Certilia; the real signer
// key lives in KMS/HSM (ADR 0003).
import { generateKeyPair, exportJWK } from "jose";
import { generatePrivateKey, privateKeyToAccount } from "viem/accounts";

const { publicKey, privateKey } = await generateKeyPair("EdDSA", { crv: "Ed25519", extractable: true });
const priv = await exportJWK(privateKey);
const pub = await exportJWK(publicKey);
priv.kid = pub.kid = "mock-issuer-1";
priv.alg = pub.alg = "EdDSA";
pub.use = "sig";

const signerKey = generatePrivateKey();
const signer = privateKeyToAccount(signerKey);

console.log("# --- mock issuer (dev only) ---");
console.log(`MOCK_ISSUER_JWK='${JSON.stringify(priv)}'`);
console.log(`# public JWKS entry: ${JSON.stringify(pub)}`);
console.log("");
console.log("# --- EIP-712 oracle signer (dev only; prod -> KMS/HSM) ---");
console.log(`SIGNER_KEY=${signerKey}`);
console.log(`# signer address (addSigner this): ${signer.address}`);
