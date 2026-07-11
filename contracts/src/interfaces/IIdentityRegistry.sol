// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title IIdentityRegistry — minimal view surface consumers (e.g. KunaToken) need.
/// @notice Deliberately narrow: policy consumers only ever ask "is this wallet a person?".
interface IIdentityRegistry {
    /// @notice True if `anchor` currently holds a personhood identity (SBT).
    function isPerson(address anchor) external view returns (bool);
}
