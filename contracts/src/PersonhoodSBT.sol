// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IPersonhoodSBT} from "./interfaces/IPersonhoodSBT.sol";

/// @title PersonhoodSBT — soulbound personhood badge (EIP-5484), minimal reference.
/// @notice Non-transferable ERC-721-style token. tokenId = uint256(nullifier) so it is
///         deterministic per person. Only the IdentityRegistry may mint/move/burn.
///         `moveTo` is the ONLY ownership change and exists solely for eID-based recovery
///         (ADR 0001 migrateAnchor); ordinary transfers always revert (soulbound).
/// @dev    Reference only — unaudited. In production prefer OpenZeppelin ERC-721 + a
///         soulbound override + AccessControl.
contract PersonhoodSBT is IPersonhoodSBT {
    string public constant name = "Proof of Croatian Personhood";
    string public constant symbol = "POCP";

    /// @dev EIP-5484 burn authorization. Here: Both (issuer=registry and owner may burn).
    enum BurnAuth { IssuerOnly, OwnerOnly, Both, Neither }

    address public immutable registry;

    mapping(uint256 tokenId => address owner) private _owner;
    mapping(address owner => uint256 count) private _balance;

    /// @dev EIP-5484
    event Issued(address indexed from, address indexed to, uint256 indexed tokenId, BurnAuth burnAuth);
    /// @dev ERC-721 (emitted on mint, recovery-move, burn) for indexer compatibility.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    error OnlyRegistry();
    error Soulbound();
    error AlreadyMinted();
    error NotMinted();

    modifier onlyRegistry() {
        if (msg.sender != registry) revert OnlyRegistry();
        _;
    }

    constructor(address registry_) {
        registry = registry_;
    }

    // --- registry-only lifecycle ---

    function mint(address to, bytes32 nullifier) external onlyRegistry returns (uint256 tokenId) {
        tokenId = uint256(nullifier);
        if (_owner[tokenId] != address(0)) revert AlreadyMinted();
        _owner[tokenId] = to;
        unchecked { _balance[to] += 1; }
        emit Transfer(address(0), to, tokenId);
        emit Issued(address(0), to, tokenId, BurnAuth.Both);
    }

    function moveTo(bytes32 nullifier, address newOwner) external onlyRegistry {
        uint256 tokenId = uint256(nullifier);
        address from = _owner[tokenId];
        if (from == address(0)) revert NotMinted();
        unchecked { _balance[from] -= 1; _balance[newOwner] += 1; }
        _owner[tokenId] = newOwner;
        emit Transfer(from, newOwner, tokenId);
    }

    function burn(bytes32 nullifier) external onlyRegistry {
        uint256 tokenId = uint256(nullifier);
        address from = _owner[tokenId];
        if (from == address(0)) revert NotMinted();
        unchecked { _balance[from] -= 1; }
        delete _owner[tokenId];
        emit Transfer(from, address(0), tokenId);
    }

    // --- views ---

    function ownerOfNullifier(bytes32 nullifier) external view returns (address) {
        return _owner[uint256(nullifier)];
    }

    function ownerOf(uint256 tokenId) external view returns (address o) {
        o = _owner[tokenId];
        if (o == address(0)) revert NotMinted();
    }

    function balanceOf(address o) external view returns (uint256) {
        return _balance[o];
    }

    function burnAuth(uint256) external pure returns (BurnAuth) {
        return BurnAuth.Both;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // ERC-165, ERC-721 (0x80ac58cd), EIP-5484 (0x0489b56f)
        return interfaceId == 0x01ffc9a7 || interfaceId == 0x80ac58cd || interfaceId == 0x0489b56f;
    }

    // --- soulbound: all holder-initiated transfers revert ---

    function transferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function approve(address, uint256) external pure {
        revert Soulbound();
    }

    function setApprovalForAll(address, bool) external pure {
        revert Soulbound();
    }
}
