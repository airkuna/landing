// nullifier = HMAC-SHA256(OIB, PEPPER) — deterministic per person, non-reversible.
// This is the ONLY thing derived from the OIB that ever leaves this boundary; the
// raw OIB is never returned, logged, or persisted (whitepaper §7, ADR 0001/0003).
// Same primitive domovina-api already runs in prod (oib_hash = HMAC-SHA256(oib,key)).

const enc = new TextEncoder();

/** Returns the nullifier as a 0x-prefixed 32-byte hex string (bytes32 for the contract). */
export async function computeNullifier(oib: string, pepper: string): Promise<`0x${string}`> {
  const key = await crypto.subtle.importKey(
    "raw",
    enc.encode(pepper),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, enc.encode(oib));
  const hex = [...new Uint8Array(sig)].map((b) => b.toString(16).padStart(2, "0")).join("");
  return `0x${hex}`;
}

/** Basic Croatian OIB sanity check (11 digits). Does not validate the checksum. */
export function looksLikeOib(oib: string): boolean {
  return /^\d{11}$/.test(oib);
}
