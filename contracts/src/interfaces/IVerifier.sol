// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title IVerifier — pluggable eID→onchain attestation verifier (ADR 0002)
/// @notice One implementation per source: A zkTLS/Certilia, B NFC eOI, C EIP-712 oracle, D Android mesh.
///         The registry is verifier-agnostic; it only trusts whatever verifier its governance installs.
interface IVerifier {
    /// @notice Verify an eID attestation and return the person's nullifier + assurance level.
    /// @dev    MUST revert if the attestation is invalid, expired, or not bound to `anchor`.
    ///         The nullifier MUST be deterministic per person (nullifier = HMAC(OIB, pepper)),
    ///         computed off-chain; the contract never sees the raw OIB. Binding to `anchor`
    ///         prevents an attestation from being replayed to claim a different wallet.
    /// @param anchor          The Safe/EOA the caller wants to bind this identity to.
    /// @param attestation     Opaque attestation payload (encoding is verifier-specific).
    /// @param proof           Opaque proof/signature (zk proof, EIP-712 sigs, etc.).
    /// @return nullifier      Deterministic per-person identifier (non-reversible).
    /// @return loa            Level of assurance (e.g. eIDAS: 1=low, 2=substantial, 3=high).
    function verify(address anchor, bytes calldata attestation, bytes calldata proof)
        external
        view
        returns (bytes32 nullifier, uint16 loa);
}
