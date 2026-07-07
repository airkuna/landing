// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IVerifier} from "../interfaces/IVerifier.sol";

/// @title EIP712Verifier — verifier C (reference) and the foundation for the mesh (D, ADR 0002).
/// @notice Accepts an attestation signed by an M-of-N set of authorized signers. Each signer is
///         an off-chain verifier that validated a live eID (Certilia) OIDC id_token (JWKS/iss/aud)
///         and computed nullifier = HMAC(OIB, pepper). In Phase 2 (ADR 0002/0004) each signer is a
///         hardware-attested Android node; here they are simply N addresses with an M threshold.
///         We deliberately use M SEPARATE ECDSA signatures (not threshold ECDSA/MPC) — simpler, and
///         it routes around nChain threshold-ECDSA patents (see docs/15 §E).
/// @dev    Reference only — unaudited.
contract EIP712Verifier is IVerifier {
    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _ATTESTATION_TYPEHASH =
        keccak256("Attestation(address anchor,bytes32 nullifier,uint16 loa,uint64 expiry)");

    bytes32 public immutable domainSeparator;

    address public admin; // airKUNA DAO Safe (manages the signer set)
    uint256 public threshold; // M
    mapping(address signer => bool authorized) public isSigner;
    uint256 public signerCount; // N

    event SignerAdded(address indexed signer);
    event SignerRemoved(address indexed signer);
    event ThresholdChanged(uint256 threshold);
    event AdminTransferred(address indexed admin);

    error NotAdmin();
    error Expired();
    error NotEnoughSigners();
    error SignersNotSorted(); // enforce strictly increasing to dedupe cheaply
    error UnauthorizedSigner();
    error BadThreshold();

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    constructor(address admin_, uint256 threshold_) {
        admin = admin_;
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
    /// @param attestation abi.encode(bytes32 nullifier, uint16 loa, uint64 expiry)
    /// @param proof       abi.encode(bytes[] signatures) — each a 65-byte ECDSA sig over the digest.
    ///                    Signers MUST be sorted strictly ascending by recovered address (dedupe).
    function verify(address anchor, bytes calldata attestation, bytes calldata proof)
        external
        view
        returns (bytes32 nullifier, uint16 loa)
    {
        uint64 expiry;
        (nullifier, loa, expiry) = abi.decode(attestation, (bytes32, uint16, uint64));
        if (block.timestamp > expiry) revert Expired();

        bytes32 structHash = keccak256(abi.encode(_ATTESTATION_TYPEHASH, anchor, nullifier, loa, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        bytes[] memory sigs = abi.decode(proof, (bytes[]));
        if (sigs.length < threshold) revert NotEnoughSigners();

        address last = address(0);
        uint256 valid;
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = _recover(digest, sigs[i]);
            if (signer <= last) revert SignersNotSorted(); // strictly increasing → no duplicates
            if (!isSigner[signer]) revert UnauthorizedSigner();
            last = signer;
            unchecked { valid++; }
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
        return ecrecover(digest, v, r, s);
    }

    // --- admin: manage the signer set (airKUNA DAO Safe) ---

    function addSigner(address signer) external onlyAdmin {
        if (!isSigner[signer]) {
            isSigner[signer] = true;
            unchecked { signerCount++; }
            emit SignerAdded(signer);
        }
    }

    function removeSigner(address signer) external onlyAdmin {
        if (isSigner[signer]) {
            isSigner[signer] = false;
            unchecked { signerCount--; }
            emit SignerRemoved(signer);
        }
    }

    function setThreshold(uint256 threshold_) external onlyAdmin {
        if (threshold_ == 0 || threshold_ > signerCount) revert BadThreshold();
        threshold = threshold_;
        emit ThresholdChanged(threshold_);
    }

    function transferAdmin(address admin_) external onlyAdmin {
        admin = admin_;
        emit AdminTransferred(admin_);
    }
}
