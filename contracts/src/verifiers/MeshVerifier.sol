// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {IdentityRegistry} from "../IdentityRegistry.sol";
import {VerifierNodeRegistry} from "./VerifierNodeRegistry.sol";

/// @title MeshVerifier — verifier D (Android mesh): M-of-N attestations from ACTIVE registry nodes.
/// @notice The Faza 2 continuation of EIP712Verifier (docs/18: "A2 → D je kontinuum: isti
///         EIP712Verifier, samo raste broj potpisnika") with two upgrades:
///
///         1. **Live signer set.** Instead of a local `isSigner` mapping, every signature must
///            recover to a node that is ACTIVE in `VerifierNodeRegistry` AT VERIFICATION TIME —
///            ejecting/deactivating a node invalidates its signatures in the same block, with no
///            cached set to desynchronize. The IdentityRegistry stays verifier-agnostic: this is
///            just another IVerifier that governance can `setVerifier` to.
///
///         2. **Replay protection.** The signed struct gains a `uint64 nonce` field which MUST
///            equal the person's current `IdentityRegistry.identities[nullifier].reverifiedAt`.
///            Every successful registry mutation for that person (claim / migrateAnchor /
///            reverify) advances `reverifiedAt` to `block.timestamp`, so a consumed attestation
///            can never be presented twice — the registry's own per-nullifier timestamp IS the
///            consumed-marker.
///
///         Encoding contract (deviation from EIP712Verifier, for off-chain signers):
///         - typehash:    Attestation(address anchor,bytes32 nullifier,uint16 loa,uint64 expiry,uint64 nonce)
///                        (EIP712Verifier's struct + trailing `uint64 nonce`)
///         - attestation: abi.encode(bytes32 nullifier, uint16 loa, uint64 expiry, uint64 nonce)
///         - proof:       abi.encode(bytes[] signatures) — unchanged (65-byte ECDSA, low-s,
///                        sorted strictly ascending by recovered address)
///         - domain:      name "airKUNA PersonhoodVerifier", version "1" — same family as
///                        EIP712Verifier; separators still differ via `verifyingContract`, and the
///                        different typehash rules out any cross-verifier signature reuse.
/// @dev    Why this replay design (and not a stored consumed-digest set): `IVerifier.verify` is
///         `view` — a verifier cannot write storage, so consumption must be derived from state
///         that the flow already mutates. `reverifiedAt` is exactly that, and doc 18 nodes carry a
///         read-only Gnosis RPC by design, so reading the current value before signing is a
///         zero-infrastructure change for the off-chain signer.
/// @dev    Otvorena odluka: atestacija nakon `revoke` — brisanjem identiteta `reverifiedAt` se
///         vraća na 0, pa neistekla claim-atestacija (nonce 0) načelno vrijedi opet; kratki
///         `expiry` (docs/18: ~600 s) je trenutna mitigacija.
/// @dev    Reference only — unaudited.
contract MeshVerifier is IVerifier {
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _ATTESTATION_TYPEHASH =
        keccak256("Attestation(address anchor,bytes32 nullifier,uint16 loa,uint64 expiry,uint64 nonce)");

    /// @dev secp256k1 group order / 2 — EIP-2 low-s bound (same hardening as EIP712Verifier).
    uint256 private constant _SECP256K1N_HALF = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    bytes32 public immutable domainSeparator;
    VerifierNodeRegistry public immutable nodeRegistry;
    IdentityRegistry public immutable identityRegistry;

    address public admin; // airKUNA DAO Safe (sets the threshold)
    address public pendingAdmin; // two-step transfer target (0 = none)
    uint256 public threshold; // M

    event ThresholdChanged(uint256 threshold);
    event AdminTransferStarted(address indexed pendingAdmin);
    event AdminTransferred(address indexed admin);

    error NotAdmin();
    error NotPendingAdmin();
    error Expired();
    error NonceMismatch();
    error NotEnoughSigners();
    error SignersNotSorted(); // enforce strictly increasing to dedupe cheaply
    error InactiveNode();
    error BadThreshold();
    error ThresholdUnsatisfiable();
    error ZeroAddress();
    error BadSignature();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    /// @dev Like EIP712Verifier, the constructor threshold is not checked against the (typically
    ///      still empty) active-node count — the mesh deploys first, nodes are admitted after.
    constructor(
        address admin_,
        VerifierNodeRegistry nodeRegistry_,
        IdentityRegistry identityRegistry_,
        uint256 threshold_
    ) {
        if (admin_ == address(0) || address(nodeRegistry_) == address(0) || address(identityRegistry_) == address(0)) {
            revert ZeroAddress();
        }
        if (threshold_ == 0) revert BadThreshold();
        admin = admin_;
        nodeRegistry = nodeRegistry_;
        identityRegistry = identityRegistry_;
        threshold = threshold_;
        domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("airKUNA PersonhoodVerifier")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    /// @inheritdoc IVerifier
    /// @param attestation abi.encode(bytes32 nullifier, uint16 loa, uint64 expiry, uint64 nonce)
    ///                    where nonce == identityRegistry.identities[nullifier].reverifiedAt.
    /// @param proof       abi.encode(bytes[] signatures) — each a 65-byte ECDSA sig over the digest.
    ///                    Signers MUST be sorted strictly ascending by recovered address (dedupe)
    ///                    and MUST be ACTIVE nodes in the VerifierNodeRegistry (live check).
    function verify(address anchor, bytes calldata attestation, bytes calldata proof)
        external
        view
        returns (bytes32 nullifier, uint16 loa)
    {
        uint64 expiry;
        uint64 nonce;
        (nullifier, loa, expiry, nonce) = abi.decode(attestation, (bytes32, uint16, uint64, uint64));
        if (block.timestamp > expiry) revert Expired();

        (,,, uint64 reverifiedAt) = identityRegistry.identities(nullifier);
        if (nonce != reverifiedAt) revert NonceMismatch();

        bytes32 structHash = keccak256(abi.encode(_ATTESTATION_TYPEHASH, anchor, nullifier, loa, expiry, nonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        bytes[] memory sigs = abi.decode(proof, (bytes[]));
        if (sigs.length < threshold) revert NotEnoughSigners();

        address last = address(0);
        uint256 valid;
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = _recover(digest, sigs[i]);
            if (signer <= last) revert SignersNotSorted(); // strictly increasing → no duplicates
            if (!nodeRegistry.isActive(signer)) revert InactiveNode();
            last = signer;
            unchecked {
                valid++;
            }
        }
        if (valid < threshold) revert NotEnoughSigners();
    }

    function _recover(bytes32 digest, bytes memory sig) private pure returns (address) {
        require(sig.length == 65, "bad sig len");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }
        if (uint256(s) > _SECP256K1N_HALF) revert BadSignature(); // EIP-2 low-s only
        address signer = ecrecover(digest, v, r, s);
        if (signer == address(0)) revert BadSignature();
        return signer;
    }

    // --- admin (airKUNA DAO Safe) ---

    /// @notice Set M. Same ThresholdUnsatisfiable-style invariant as EIP712Verifier, but against
    ///         the LIVE active-node count. Note the registry does not know this threshold, so DAO
    ///         ejections can still push activeNodeCount below M — verify() is then unsatisfiable
    ///         until the DAO lowers the threshold or admits nodes (fail-closed by design).
    function setThreshold(uint256 threshold_) external onlyAdmin {
        if (threshold_ == 0) revert BadThreshold();
        if (threshold_ > nodeRegistry.activeNodeCount()) revert ThresholdUnsatisfiable();
        threshold = threshold_;
        emit ThresholdChanged(threshold_);
    }

    /// @notice Two-step admin transfer (the KunaToken lesson — EIP712Verifier's one-shot
    ///         `transferAdmin` can brick the signer set on a typo).
    function transferAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) revert ZeroAddress();
        pendingAdmin = newAdmin;
        emit AdminTransferStarted(newAdmin);
    }

    function acceptAdmin() external {
        if (msg.sender != pendingAdmin) revert NotPendingAdmin();
        admin = msg.sender;
        delete pendingAdmin;
        emit AdminTransferred(msg.sender);
    }
}
