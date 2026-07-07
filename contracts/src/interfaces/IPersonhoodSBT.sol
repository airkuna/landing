// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title IPersonhoodSBT — minimal interface the registry uses to mint/burn the soulbound badge.
interface IPersonhoodSBT {
    /// @notice Mint the personhood SBT for `to`. tokenId is derived from the nullifier.
    /// @dev    MUST be callable only by the IdentityRegistry.
    function mint(address to, bytes32 nullifier) external returns (uint256 tokenId);

    /// @notice Move the SBT to a new owner (anchor migration / eID recovery). Same tokenId.
    function moveTo(bytes32 nullifier, address newOwner) external;

    /// @notice Burn the SBT (e.g. revocation).
    function burn(bytes32 nullifier) external;

    function ownerOfNullifier(bytes32 nullifier) external view returns (address);
}
