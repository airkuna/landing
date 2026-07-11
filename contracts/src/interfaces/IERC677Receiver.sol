// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title IERC677Receiver — callback for ERC-677 `transferAndCall` recipients.
/// @notice Same shape as the LINK/Monerium-EURe callback. Declared WITHOUT a return value on
///         purpose: void receivers (Chainlink style) and bool-returning receivers both satisfy
///         this call (extra return data is ignored), while requiring a bool would break the
///         void ones. A reverting receiver still reverts the whole transfer.
interface IERC677Receiver {
    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external;
}
