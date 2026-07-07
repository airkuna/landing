// EIP-712 attestation signing + ABI encoding, matching EIP712Verifier.sol exactly.
//
//   domain  = EIP712Domain("airKUNA PersonhoodVerifier", "1", chainId, verifyingContract)
//   struct  = Attestation(address anchor, bytes32 nullifier, uint16 loa, uint64 expiry)
//   attestation = abi.encode(bytes32 nullifier, uint16 loa, uint64 expiry)
//   proof       = abi.encode(bytes[] signatures)   // each 65-byte r||s||v
//
// With N=1 this is verifier A2 (thin oracle); adding signers later (mesh, ADR 0002/
// docs/18) is the SAME contract — just more entries in the signatures array.
import { encodeAbiParameters, type Address, type Hex } from "viem";
import { privateKeyToAccount } from "viem/accounts";

export const DOMAIN_NAME = "airKUNA PersonhoodVerifier";
export const DOMAIN_VERSION = "1";

export const ATTESTATION_TYPES = {
  Attestation: [
    { name: "anchor", type: "address" },
    { name: "nullifier", type: "bytes32" },
    { name: "loa", type: "uint16" },
    { name: "expiry", type: "uint64" },
  ],
} as const;

export interface AttestationFields {
  anchor: Address;
  nullifier: Hex; // bytes32
  loa: number; // uint16
  expiry: bigint; // uint64 unix seconds
}

export interface SignedAttestation {
  attestation: Hex; // abi.encode(nullifier, loa, expiry)
  proof: Hex; // abi.encode(bytes[] sigs)
  signer: Address;
  fields: { nullifier: Hex; loa: number; expiry: string; anchor: Address };
}

/** Sign one attestation with the oracle key and package {attestation, proof} for claim(). */
export async function signAttestation(
  signerKey: Hex,
  chainId: number,
  verifyingContract: Address,
  fields: AttestationFields,
): Promise<SignedAttestation> {
  const account = privateKeyToAccount(signerKey);

  const signature = await account.signTypedData({
    domain: {
      name: DOMAIN_NAME,
      version: DOMAIN_VERSION,
      chainId,
      verifyingContract,
    },
    types: ATTESTATION_TYPES,
    primaryType: "Attestation",
    message: {
      anchor: fields.anchor,
      nullifier: fields.nullifier,
      loa: fields.loa,
      expiry: fields.expiry,
    },
  }); // 0x + r(32) + s(32) + v(1) = 65 bytes, exactly what EIP712Verifier._recover expects

  const attestation = encodeAbiParameters(
    [{ type: "bytes32" }, { type: "uint16" }, { type: "uint64" }],
    [fields.nullifier, fields.loa, fields.expiry],
  );
  const proof = encodeAbiParameters([{ type: "bytes[]" }], [[signature]]);

  return {
    attestation,
    proof,
    signer: account.address,
    fields: {
      nullifier: fields.nullifier,
      loa: fields.loa,
      expiry: fields.expiry.toString(),
      anchor: fields.anchor,
    },
  };
}
