// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";
import {MeshVerifier} from "../src/verifiers/MeshVerifier.sol";

/// @dev Shared test helpers: builds EIP-712 attestations + signatures the way the
///      off-chain verifier A2 does (and the mesh D nodes do), so registry/verifier
///      tests share one signing path.
abstract contract Base is Test {
    // MUST match EIP712Verifier._ATTESTATION_TYPEHASH.
    bytes32 internal constant ATTESTATION_TYPEHASH =
        keccak256("Attestation(address anchor,bytes32 nullifier,uint16 loa,uint64 expiry)");
    // MUST match MeshVerifier._ATTESTATION_TYPEHASH (the A2 struct + trailing uint64 nonce).
    bytes32 internal constant MESH_ATTESTATION_TYPEHASH =
        keccak256("Attestation(address anchor,bytes32 nullifier,uint16 loa,uint64 expiry,uint64 nonce)");

    /// @dev abi-encoded attestation payload (matches EIP712Verifier.verify decode).
    function _attestation(bytes32 nullifier, uint16 loa, uint64 expiry) internal pure returns (bytes memory) {
        return abi.encode(nullifier, loa, expiry);
    }

    /// @dev The EIP-712 digest a signer signs.
    function _digest(EIP712Verifier v, address anchor, bytes32 nullifier, uint16 loa, uint64 expiry)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(ATTESTATION_TYPEHASH, anchor, nullifier, loa, expiry));
        return keccak256(abi.encodePacked("\x19\x01", v.domainSeparator(), structHash));
    }

    /// @dev abi-encoded MESH attestation payload (matches MeshVerifier.verify decode).
    function _meshAttestation(bytes32 nullifier, uint16 loa, uint64 expiry, uint64 nonce)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(nullifier, loa, expiry, nonce);
    }

    /// @dev The EIP-712 digest a mesh node signs (nonce = registry's current reverifiedAt).
    function _meshDigest(MeshVerifier v, address anchor, bytes32 nullifier, uint16 loa, uint64 expiry, uint64 nonce)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(MESH_ATTESTATION_TYPEHASH, anchor, nullifier, loa, expiry, nonce));
        return keccak256(abi.encodePacked("\x19\x01", v.domainSeparator(), structHash));
    }

    function _sign(uint256 pk, bytes32 digest) internal returns (bytes memory) {
        (uint8 vv, bytes32 r, bytes32 s) = vm.sign(pk, digest);
        return abi.encodePacked(r, s, vv); // r,s,v — matches EIP712Verifier._recover
    }

    /// @dev proof = abi.encode(bytes[] sigs) for a single signer.
    function _singleProof(uint256 pk, bytes32 digest) internal returns (bytes memory) {
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = _sign(pk, digest);
        return abi.encode(sigs);
    }

    /// @dev proof for N signers, in the order given (NOT sorted — caller controls order).
    function _proof(uint256[] memory pks, bytes32 digest) internal returns (bytes memory) {
        bytes[] memory sigs = new bytes[](pks.length);
        for (uint256 i = 0; i < pks.length; i++) {
            sigs[i] = _sign(pks[i], digest);
        }
        return abi.encode(sigs);
    }

    /// @dev proof for N signers, sorted strictly ascending by recovered address (the happy path).
    function _sortedProof(uint256[] memory pks, bytes32 digest) internal returns (bytes memory) {
        // insertion sort by vm.addr(pk)
        for (uint256 i = 1; i < pks.length; i++) {
            uint256 key = pks[i];
            uint256 j = i;
            while (j > 0 && vm.addr(pks[j - 1]) > vm.addr(key)) {
                pks[j] = pks[j - 1];
                j--;
            }
            pks[j] = key;
        }
        return _proof(pks, digest);
    }
}
