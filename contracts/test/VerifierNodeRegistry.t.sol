// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {VerifierNodeRegistry} from "../src/verifiers/VerifierNodeRegistry.sol";

contract VerifierNodeRegistryTest is Test {
    VerifierNodeRegistry internal reg;

    address internal governance = address(0xDA0);
    address internal treasury = address(0x7EA);
    address internal operator = address(0x0B1);
    address internal outsider = address(0xBEEF);

    address internal key1 = address(0x1001);
    address internal key2 = address(0x1002);

    uint256 internal constant MIN_STAKE = 1 ether;
    uint256 internal constant UNSTAKE_DELAY = 7 days;
    bytes32 internal constant ATT_REF = keccak256("android-key-attestation-chain");

    event NodeRegistered(address indexed signingKey, address indexed operator, bytes32 attestationRef, uint256 stake);
    event NodeActivated(address indexed signingKey);
    event NodeDeactivated(address indexed signingKey);
    event NodeEjected(address indexed signingKey, uint256 slashed);
    event StakeAdded(address indexed signingKey, uint256 amount);
    event StakeWithdrawn(address indexed signingKey, address indexed operator, uint256 amount);
    event MinStakeChanged(uint256 minStake);
    event UnstakeDelayChanged(uint256 unstakeDelay);
    event TreasuryChanged(address indexed treasury);
    event GovernanceTransferStarted(address indexed pendingGovernance);
    event GovernanceTransferred(address indexed newGovernance);

    function setUp() public {
        vm.warp(1_000_000);
        reg = new VerifierNodeRegistry(governance, treasury, MIN_STAKE, UNSTAKE_DELAY);
        vm.deal(operator, 100 ether);
    }

    function _status(address key) internal view returns (VerifierNodeRegistry.NodeStatus) {
        return reg.statusOf(key);
    }

    function _register(address key) internal {
        vm.prank(operator);
        reg.register{value: MIN_STAKE}(key, ATT_REF);
    }

    function _registerActive(address key) internal {
        _register(key);
        vm.prank(governance);
        reg.activate(key);
    }

    // --- constructor ---

    function test_constructor_zeroGovernance_reverts() public {
        vm.expectRevert(VerifierNodeRegistry.ZeroAddress.selector);
        new VerifierNodeRegistry(address(0), treasury, 0, 0);
    }

    function test_constructor_zeroTreasury_reverts() public {
        vm.expectRevert(VerifierNodeRegistry.ZeroAddress.selector);
        new VerifierNodeRegistry(governance, address(0), 0, 0);
    }

    // --- register ---

    function test_register_pending() public {
        vm.expectEmit(true, true, false, true);
        emit NodeRegistered(key1, operator, ATT_REF, MIN_STAKE);
        _register(key1);

        (address op, bytes32 attRef, uint64 registeredAt, uint64 statusChangedAt, VerifierNodeRegistry.NodeStatus st, uint256 stake)
        = reg.nodes(key1);
        assertEq(op, operator);
        assertEq(attRef, ATT_REF);
        assertEq(registeredAt, uint64(block.timestamp));
        assertEq(statusChangedAt, uint64(block.timestamp));
        assertEq(uint8(st), uint8(VerifierNodeRegistry.NodeStatus.Pending));
        assertEq(stake, MIN_STAKE);
        assertEq(reg.nodeCount(), 1);
        assertEq(reg.activeNodeCount(), 0);
        assertFalse(reg.isActive(key1));
        assertEq(address(reg).balance, MIN_STAKE);
    }

    function test_register_zeroKey_reverts() public {
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.ZeroAddress.selector);
        reg.register{value: MIN_STAKE}(address(0), ATT_REF);
    }

    function test_register_zeroAttestation_reverts() public {
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.NoAttestation.selector);
        reg.register{value: MIN_STAKE}(key1, bytes32(0));
    }

    function test_register_duplicate_reverts() public {
        _register(key1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.AlreadyRegistered.selector);
        reg.register{value: MIN_STAKE}(key1, ATT_REF);
    }

    function test_register_stakeBelowMin_reverts() public {
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.StakeTooLow.selector);
        reg.register{value: MIN_STAKE - 1}(key1, ATT_REF);
    }

    function test_register_noStakeNeeded_whenMinStakeZero() public {
        vm.prank(governance);
        reg.setMinStake(0);
        vm.prank(operator);
        reg.register(key1, ATT_REF); // no value at all
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Pending));
    }

    // --- activate (pending → active, offline → active) ---

    function test_activate_pendingToActive() public {
        _register(key1);
        vm.expectEmit(true, false, false, true);
        emit NodeActivated(key1);
        vm.prank(governance);
        reg.activate(key1);
        assertTrue(reg.isActive(key1));
        assertEq(reg.activeNodeCount(), 1);
    }

    function test_activate_onlyGovernance() public {
        _register(key1);
        vm.prank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotGovernance.selector);
        reg.activate(key1);
    }

    function test_activate_unknown_reverts() public {
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.UnknownNode.selector);
        reg.activate(key1);
    }

    function test_activate_alreadyActive_reverts() public {
        _registerActive(key1);
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.activate(key1);
    }

    function test_activate_offlineToActive_reactivation() public {
        _registerActive(key1);
        vm.prank(governance);
        reg.deactivate(key1);
        assertEq(reg.activeNodeCount(), 0);

        vm.prank(governance);
        reg.activate(key1);
        assertTrue(reg.isActive(key1));
        assertEq(reg.activeNodeCount(), 1);
    }

    function test_activate_belowCurrentMinStake_reverts() public {
        _register(key1);
        vm.prank(governance);
        reg.setMinStake(2 ether); // raised after registration
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.StakeTooLow.selector);
        reg.activate(key1);

        // top up re-qualifies
        vm.prank(operator);
        reg.addStake{value: 1 ether}(key1);
        vm.prank(governance);
        reg.activate(key1);
        assertTrue(reg.isActive(key1));
    }

    // --- deactivate (active → offline) ---

    function test_deactivate_byGovernance() public {
        _registerActive(key1);
        vm.expectEmit(true, false, false, true);
        emit NodeDeactivated(key1);
        vm.prank(governance);
        reg.deactivate(key1);
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Offline));
        assertEq(reg.activeNodeCount(), 0);
        assertFalse(reg.isActive(key1));
    }

    function test_deactivate_byOperator() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Offline));
    }

    function test_deactivate_byOutsider_reverts() public {
        _registerActive(key1);
        vm.prank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotAuthorized.selector);
        reg.deactivate(key1);
    }

    function test_deactivate_pending_reverts() public {
        _register(key1);
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.deactivate(key1);
    }

    function test_deactivate_unknown_reverts() public {
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.UnknownNode.selector);
        reg.deactivate(key1);
    }

    // --- eject (terminal + slash) ---

    function test_eject_active_slashesToTreasury() public {
        _registerActive(key1);
        uint256 treasuryBefore = treasury.balance;
        vm.expectEmit(true, false, false, true);
        emit NodeEjected(key1, MIN_STAKE);
        vm.prank(governance);
        reg.eject(key1);

        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Ejected));
        assertEq(reg.activeNodeCount(), 0);
        assertEq(treasury.balance, treasuryBefore + MIN_STAKE);
        (,,,,, uint256 stake) = reg.nodes(key1);
        assertEq(stake, 0);
    }

    function test_eject_pending() public {
        _register(key1);
        vm.prank(governance);
        reg.eject(key1);
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Ejected));
        assertEq(reg.activeNodeCount(), 0); // was never active — no underflow
    }

    function test_eject_offline() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.prank(governance);
        reg.eject(key1);
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Ejected));
    }

    function test_eject_onlyGovernance() public {
        _registerActive(key1);
        vm.prank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotGovernance.selector);
        reg.eject(key1);
    }

    function test_eject_terminal_cannotReactivate() public {
        _registerActive(key1);
        vm.prank(governance);
        reg.eject(key1);

        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.activate(key1);

        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.eject(key1); // double-eject blocked too
    }

    function test_eject_terminal_keyCannotReregister() public {
        _registerActive(key1);
        vm.prank(governance);
        reg.eject(key1);

        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.AlreadyRegistered.selector);
        reg.register{value: MIN_STAKE}(key1, ATT_REF);
    }

    function test_eject_zeroStake_noTransfer() public {
        vm.prank(governance);
        reg.setMinStake(0);
        vm.prank(operator);
        reg.register(key1, ATT_REF);
        uint256 treasuryBefore = treasury.balance;
        vm.expectEmit(true, false, false, true);
        emit NodeEjected(key1, 0);
        vm.prank(governance);
        reg.eject(key1);
        assertEq(treasury.balance, treasuryBefore);
    }

    // --- stake management ---

    function test_addStake() public {
        _register(key1);
        vm.expectEmit(true, false, false, true);
        emit StakeAdded(key1, 2 ether);
        vm.prank(operator);
        reg.addStake{value: 2 ether}(key1);
        (,,,,, uint256 stake) = reg.nodes(key1);
        assertEq(stake, MIN_STAKE + 2 ether);
    }

    function test_addStake_notOperator_reverts() public {
        _register(key1);
        vm.deal(outsider, 1 ether);
        vm.prank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotOperator.selector);
        reg.addStake{value: 1 ether}(key1);
    }

    function test_addStake_ejected_reverts() public {
        _register(key1);
        vm.prank(governance);
        reg.eject(key1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.addStake{value: 1 ether}(key1);
    }

    function test_addStake_zeroValue_reverts() public {
        _register(key1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.ZeroAmount.selector);
        reg.addStake(key1);
    }

    function test_withdrawStake_afterDelay() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.warp(block.timestamp + UNSTAKE_DELAY);

        uint256 before = operator.balance;
        vm.expectEmit(true, true, false, true);
        emit StakeWithdrawn(key1, operator, MIN_STAKE);
        vm.prank(operator);
        reg.withdrawStake(key1);
        assertEq(operator.balance, before + MIN_STAKE);
        // node record survives with zero stake, still Offline
        assertEq(uint8(_status(key1)), uint8(VerifierNodeRegistry.NodeStatus.Offline));
    }

    function test_withdrawStake_beforeDelay_reverts() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.warp(block.timestamp + UNSTAKE_DELAY - 1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.UnstakeLocked.selector);
        reg.withdrawStake(key1);
    }

    function test_withdrawStake_whileActive_reverts() public {
        _registerActive(key1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.InvalidTransition.selector);
        reg.withdrawStake(key1);
    }

    function test_withdrawStake_notOperator_reverts() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.warp(block.timestamp + UNSTAKE_DELAY);
        vm.prank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotOperator.selector);
        reg.withdrawStake(key1);
    }

    function test_withdrawStake_zeroStake_reverts() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.warp(block.timestamp + UNSTAKE_DELAY);
        vm.prank(operator);
        reg.withdrawStake(key1);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.ZeroAmount.selector);
        reg.withdrawStake(key1);
    }

    function test_withdrawnNode_cannotReactivate_untilRestaked() public {
        _registerActive(key1);
        vm.prank(operator);
        reg.deactivate(key1);
        vm.warp(block.timestamp + UNSTAKE_DELAY);
        vm.prank(operator);
        reg.withdrawStake(key1);

        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.StakeTooLow.selector);
        reg.activate(key1);

        vm.prank(operator);
        reg.addStake{value: MIN_STAKE}(key1);
        vm.prank(governance);
        reg.activate(key1);
        assertTrue(reg.isActive(key1));
    }

    // --- governance config ---

    function test_setMinStake() public {
        vm.expectEmit(false, false, false, true);
        emit MinStakeChanged(5 ether);
        vm.prank(governance);
        reg.setMinStake(5 ether);
        assertEq(reg.minStake(), 5 ether);
    }

    function test_setUnstakeDelay() public {
        vm.expectEmit(false, false, false, true);
        emit UnstakeDelayChanged(1 days);
        vm.prank(governance);
        reg.setUnstakeDelay(1 days);
        assertEq(reg.unstakeDelay(), 1 days);
    }

    function test_setTreasury() public {
        vm.expectEmit(true, false, false, true);
        emit TreasuryChanged(outsider);
        vm.prank(governance);
        reg.setTreasury(outsider);
        assertEq(reg.treasury(), outsider);
    }

    function test_setTreasury_zero_reverts() public {
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.ZeroAddress.selector);
        reg.setTreasury(address(0));
    }

    function test_configSetters_onlyGovernance() public {
        vm.startPrank(outsider);
        vm.expectRevert(VerifierNodeRegistry.NotGovernance.selector);
        reg.setMinStake(0);
        vm.expectRevert(VerifierNodeRegistry.NotGovernance.selector);
        reg.setUnstakeDelay(0);
        vm.expectRevert(VerifierNodeRegistry.NotGovernance.selector);
        reg.setTreasury(outsider);
        vm.stopPrank();
    }

    // --- two-step governance transfer ---

    function test_transferGovernance_twoStep() public {
        vm.expectEmit(true, false, false, true);
        emit GovernanceTransferStarted(outsider);
        vm.prank(governance);
        reg.transferGovernance(outsider);
        assertEq(reg.governance(), governance); // unchanged until accepted
        assertEq(reg.pendingGovernance(), outsider);

        vm.expectEmit(true, false, false, true);
        emit GovernanceTransferred(outsider);
        vm.prank(outsider);
        reg.acceptGovernance();
        assertEq(reg.governance(), outsider);
        assertEq(reg.pendingGovernance(), address(0));
    }

    function test_acceptGovernance_wrongCaller_reverts() public {
        vm.prank(governance);
        reg.transferGovernance(outsider);
        vm.prank(operator);
        vm.expectRevert(VerifierNodeRegistry.NotPendingGovernance.selector);
        reg.acceptGovernance();
    }

    function test_transferGovernance_zero_reverts() public {
        vm.prank(governance);
        vm.expectRevert(VerifierNodeRegistry.ZeroAddress.selector);
        reg.transferGovernance(address(0));
    }

    // --- multi-node accounting ---

    function test_activeNodeCount_tracksAcrossNodes() public {
        _registerActive(key1);
        _registerActive(key2);
        assertEq(reg.activeNodeCount(), 2);
        assertEq(reg.nodeCount(), 2);

        vm.prank(governance);
        reg.eject(key2);
        assertEq(reg.activeNodeCount(), 1);
        assertEq(reg.nodeCount(), 2); // nodeCount is total ever registered
    }
}
