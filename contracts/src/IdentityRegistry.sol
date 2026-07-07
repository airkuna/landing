// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IVerifier} from "./interfaces/IVerifier.sol";
import {IPersonhoodSBT} from "./interfaces/IPersonhoodSBT.sol";

/// @title IdentityRegistry — one person, one identity, many wallets (ADR 0001).
/// @notice Uniqueness is enforced at the NULLIFIER level (nullifier = HMAC(OIB, pepper)),
///         not the wallet level: any number of Safes derive from the same OIB → same
///         nullifier → a second claim reverts. The raw OIB never reaches this contract.
///         Verification is delegated to a pluggable IVerifier (ADR 0002).
/// @dev    Reference only — unaudited. `governance` is expected to be an airKUNA DAO Safe
///         multisig. In production use OZ AccessControl + timelocks + audits.
contract IdentityRegistry {
    struct Identity {
        address anchor; // the wallet currently holding this person's SBT
        uint16 loa; // level of assurance from the verifier
        uint64 verifiedAt; // first claim
        uint64 reverifiedAt; // last (re)verification
    }

    /// @notice nullifier => identity. Presence of a non-zero anchor means "claimed".
    mapping(bytes32 nullifier => Identity) public identities;
    /// @notice reverse lookup: anchor => nullifier (0 if this wallet is not an anchor).
    mapping(address anchor => bytes32 nullifier) public anchorToNullifier;

    IPersonhoodSBT public immutable sbt;

    // --- governance-controlled config ---
    address public governance; // airKUNA DAO Safe multisig
    IVerifier public verifier; // currently trusted verifier (A/B/C/D per ADR 0002)
    uint16 public minLoA; // minimum accepted assurance (e.g. 2 = substantial)

    event Claimed(bytes32 indexed nullifier, address indexed anchor, uint16 loa);
    event AnchorMigrated(bytes32 indexed nullifier, address indexed oldAnchor, address indexed newAnchor);
    event Reverified(bytes32 indexed nullifier, uint64 at);
    event VerifierChanged(address indexed verifier);
    event MinLoAChanged(uint16 minLoA);
    event GovernanceTransferred(address indexed newGovernance);

    error NotGovernance();
    error AlreadyClaimed();
    error NotClaimed();
    error AnchorInUse();
    error NullifierMismatch();
    error AssuranceTooLow();
    error ZeroAddress();

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }

    constructor(address governance_, IVerifier verifier_, IPersonhoodSBT sbt_, uint16 minLoA_) {
        if (governance_ == address(0) || address(sbt_) == address(0)) revert ZeroAddress();
        governance = governance_;
        verifier = verifier_;
        sbt = sbt_;
        minLoA = minLoA_;
    }

    // --- user actions ---

    /// @notice Claim a personhood SBT for `anchor` by presenting an eID attestation.
    ///         Fails if this person (nullifier) already has an identity, or if `anchor`
    ///         is already an anchor for someone else.
    function claim(address anchor, bytes calldata attestation, bytes calldata proof) external {
        if (anchor == address(0)) revert ZeroAddress();
        (bytes32 nullifier, uint16 loa) = verifier.verify(anchor, attestation, proof);
        if (loa < minLoA) revert AssuranceTooLow();
        if (identities[nullifier].anchor != address(0)) revert AlreadyClaimed();
        if (anchorToNullifier[anchor] != bytes32(0)) revert AnchorInUse();

        identities[nullifier] =
            Identity({anchor: anchor, loa: loa, verifiedAt: uint64(block.timestamp), reverifiedAt: uint64(block.timestamp)});
        anchorToNullifier[anchor] = nullifier;
        sbt.mint(anchor, nullifier);
        emit Claimed(nullifier, anchor, loa);
    }

    /// @notice Recovery: move an existing identity to a new anchor by re-verifying the SAME eID.
    ///         This is how a lost wallet is recovered — the eID is the recovery key (ADR 0001).
    function migrateAnchor(address newAnchor, bytes calldata attestation, bytes calldata proof) external {
        if (newAnchor == address(0)) revert ZeroAddress();
        if (anchorToNullifier[newAnchor] != bytes32(0)) revert AnchorInUse();
        (bytes32 nullifier, uint16 loa) = verifier.verify(newAnchor, attestation, proof);
        if (loa < minLoA) revert AssuranceTooLow();

        Identity storage id = identities[nullifier];
        address oldAnchor = id.anchor;
        if (oldAnchor == address(0)) revert NotClaimed();

        delete anchorToNullifier[oldAnchor];
        anchorToNullifier[newAnchor] = nullifier;
        id.anchor = newAnchor;
        id.loa = loa;
        id.reverifiedAt = uint64(block.timestamp);
        sbt.moveTo(nullifier, newAnchor);
        emit AnchorMigrated(nullifier, oldAnchor, newAnchor);
    }

    /// @notice Refresh liveness/assurance without changing the anchor (proof of continued personhood).
    function reverify(bytes calldata attestation, bytes calldata proof) external {
        address anchor = msg.sender;
        bytes32 expected = anchorToNullifier[anchor];
        if (expected == bytes32(0)) revert NotClaimed();
        (bytes32 nullifier, uint16 loa) = verifier.verify(anchor, attestation, proof);
        if (nullifier != expected) revert NullifierMismatch();
        if (loa < minLoA) revert AssuranceTooLow();
        Identity storage id = identities[nullifier];
        id.loa = loa;
        id.reverifiedAt = uint64(block.timestamp);
        emit Reverified(nullifier, uint64(block.timestamp));
    }

    // --- views (safe: never expose OIB, only the nullifier commitment) ---

    function isPerson(address anchor) external view returns (bool) {
        return anchorToNullifier[anchor] != bytes32(0);
    }

    function identityOf(address anchor) external view returns (Identity memory) {
        return identities[anchorToNullifier[anchor]];
    }

    // --- governance (airKUNA DAO Safe) ---

    function setVerifier(IVerifier verifier_) external onlyGovernance {
        verifier = verifier_;
        emit VerifierChanged(address(verifier_));
    }

    function setMinLoA(uint16 minLoA_) external onlyGovernance {
        minLoA = minLoA_;
        emit MinLoAChanged(minLoA_);
    }

    function transferGovernance(address newGovernance) external onlyGovernance {
        if (newGovernance == address(0)) revert ZeroAddress();
        governance = newGovernance;
        emit GovernanceTransferred(newGovernance);
    }
}
