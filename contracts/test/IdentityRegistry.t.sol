// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Base} from "./Base.t.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {PersonhoodSBT} from "../src/PersonhoodSBT.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";
import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {IPersonhoodSBT} from "../src/interfaces/IPersonhoodSBT.sol";

contract IdentityRegistryTest is Base {
    IdentityRegistry internal registry;
    PersonhoodSBT internal sbt;
    EIP712Verifier internal verifier;

    address internal gov = address(this); // governance = this test
    uint256 internal oraclePk;
    address internal oracle;

    uint16 internal constant MIN_LOA = 2;

    // people
    bytes32 internal constant NULL_A = keccak256("oib-A");
    bytes32 internal constant NULL_B = keccak256("oib-B");

    // wallets
    address internal wA = address(0xA11CE);
    address internal wB = address(0xB0B);
    address internal wC = address(0xCAFE);

    function setUp() public {
        vm.warp(1_000_000);
        oraclePk = 0xABCDEF;
        oracle = vm.addr(oraclePk);

        verifier = new EIP712Verifier(gov, 1);
        verifier.addSigner(oracle);

        sbt = new PersonhoodSBT();
        registry = new IdentityRegistry(gov, IVerifier(address(verifier)), IPersonhoodSBT(address(sbt)), MIN_LOA);
        sbt.setRegistry(address(registry));
    }

    // --- helpers ---

    function _makeClaim(address anchor, bytes32 nullifier, uint16 loa)
        internal
        returns (bytes memory att, bytes memory proof)
    {
        uint64 expiry = uint64(block.timestamp + 600);
        att = _attestation(nullifier, loa, expiry);
        bytes32 digest = _digest(verifier, anchor, nullifier, loa, expiry);
        proof = _singleProof(oraclePk, digest);
    }

    function _claim(address anchor, bytes32 nullifier, uint16 loa) internal {
        (bytes memory att, bytes memory proof) = _makeClaim(anchor, nullifier, loa);
        registry.claim(anchor, att, proof);
    }

    // --- claim ---

    function test_claim_mintsSBT() public {
        _claim(wA, NULL_A, 3);
        assertTrue(registry.isPerson(wA));
        assertEq(sbt.ownerOfNullifier(NULL_A), wA);
        assertEq(registry.anchorToNullifier(wA), NULL_A);

        IdentityRegistry.Identity memory id = registry.identityOf(wA);
        assertEq(id.anchor, wA);
        assertEq(id.loa, 3);
        assertEq(id.verifiedAt, uint64(block.timestamp));
        assertEq(id.reverifiedAt, uint64(block.timestamp));
    }

    function test_claim_sameNullifier_reverts() public {
        _claim(wA, NULL_A, 3);
        // same person (nullifier), different wallet → AlreadyClaimed
        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 3);
        vm.expectRevert(IdentityRegistry.AlreadyClaimed.selector);
        registry.claim(wB, att, proof);
    }

    function test_claim_anchorInUse_reverts() public {
        _claim(wA, NULL_A, 3);
        // different person, but reusing wA as anchor → AnchorInUse
        (bytes memory att, bytes memory proof) = _makeClaim(wA, NULL_B, 3);
        vm.expectRevert(IdentityRegistry.AnchorInUse.selector);
        registry.claim(wA, att, proof);
    }

    function test_claim_lowLoA_reverts() public {
        (bytes memory att, bytes memory proof) = _makeClaim(wA, NULL_A, 1); // < MIN_LOA (2)
        vm.expectRevert(IdentityRegistry.AssuranceTooLow.selector);
        registry.claim(wA, att, proof);
    }

    function test_claim_zeroAnchor_reverts() public {
        (bytes memory att, bytes memory proof) = _makeClaim(address(0), NULL_A, 3);
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.claim(address(0), att, proof);
    }

    function test_claim_badSignature_reverts() public {
        // sign with a non-oracle key → verifier UnauthorizedSigner bubbles up
        uint64 expiry = uint64(block.timestamp + 600);
        bytes memory att = _attestation(NULL_A, 3, expiry);
        bytes32 digest = _digest(verifier, wA, NULL_A, 3, expiry);
        bytes memory proof = _singleProof(0xBADBAD, digest);
        vm.expectRevert(EIP712Verifier.UnauthorizedSigner.selector);
        registry.claim(wA, att, proof);
    }

    // --- migrateAnchor (recovery) ---

    function test_migrateAnchor_movesSBT() public {
        _claim(wA, NULL_A, 3);

        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 3);
        registry.migrateAnchor(wB, att, proof);

        // SBT moved
        assertEq(sbt.ownerOfNullifier(NULL_A), wB);
        // old anchor freed
        assertFalse(registry.isPerson(wA));
        assertEq(registry.anchorToNullifier(wA), bytes32(0));
        // new anchor bound
        assertTrue(registry.isPerson(wB));
        assertEq(registry.anchorToNullifier(wB), NULL_A);

        IdentityRegistry.Identity memory id = registry.identityOf(wB);
        assertEq(id.anchor, wB);
    }

    function test_migrateAnchor_freesOldAnchorForReuse() public {
        _claim(wA, NULL_A, 3);
        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 3);
        registry.migrateAnchor(wB, att, proof);
        // a different person can now claim the freed wallet wA
        _claim(wA, NULL_B, 3);
        assertEq(sbt.ownerOfNullifier(NULL_B), wA);
    }

    function test_migrateAnchor_notClaimed_reverts() public {
        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 3);
        vm.expectRevert(IdentityRegistry.NotClaimed.selector);
        registry.migrateAnchor(wB, att, proof);
    }

    function test_migrateAnchor_anchorInUse_reverts() public {
        _claim(wA, NULL_A, 3);
        _claim(wB, NULL_B, 3);
        // try to migrate person A onto wB, which is already B's anchor
        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 3);
        vm.expectRevert(IdentityRegistry.AnchorInUse.selector);
        registry.migrateAnchor(wB, att, proof);
    }

    function test_migrateAnchor_zeroAnchor_reverts() public {
        _claim(wA, NULL_A, 3);
        (bytes memory att, bytes memory proof) = _makeClaim(address(0), NULL_A, 3);
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.migrateAnchor(address(0), att, proof);
    }

    function test_migrateAnchor_lowLoA_reverts() public {
        _claim(wA, NULL_A, 3);
        (bytes memory att, bytes memory proof) = _makeClaim(wB, NULL_A, 1);
        vm.expectRevert(IdentityRegistry.AssuranceTooLow.selector);
        registry.migrateAnchor(wB, att, proof);
    }

    // --- reverify ---

    function test_reverify_refreshesTimestamp() public {
        _claim(wA, NULL_A, 3);
        uint64 t0 = uint64(block.timestamp);
        vm.warp(block.timestamp + 5000);

        (bytes memory att, bytes memory proof) = _makeClaim(wA, NULL_A, 3);
        vm.prank(wA);
        registry.reverify(att, proof);

        IdentityRegistry.Identity memory id = registry.identityOf(wA);
        assertEq(id.verifiedAt, t0); // unchanged
        assertEq(id.reverifiedAt, uint64(block.timestamp)); // refreshed
        assertGt(id.reverifiedAt, id.verifiedAt);
    }

    function test_reverify_notClaimed_reverts() public {
        (bytes memory att, bytes memory proof) = _makeClaim(wC, NULL_A, 3);
        vm.prank(wC);
        vm.expectRevert(IdentityRegistry.NotClaimed.selector);
        registry.reverify(att, proof);
    }

    function test_reverify_nullifierMismatch_reverts() public {
        _claim(wA, NULL_A, 3);
        // present a valid attestation but for a DIFFERENT nullifier bound to same anchor
        (bytes memory att, bytes memory proof) = _makeClaim(wA, NULL_B, 3);
        vm.prank(wA);
        vm.expectRevert(IdentityRegistry.NullifierMismatch.selector);
        registry.reverify(att, proof);
    }

    // --- revoke ---

    function test_revoke_clearsIdentityAndBurnsSBT() public {
        _claim(wA, NULL_A, 3);

        vm.expectEmit(true, true, false, true);
        emit IdentityRegistry.Revoked(NULL_A, wA);
        registry.revoke(NULL_A);

        // both mappings cleared
        assertFalse(registry.isPerson(wA));
        assertEq(registry.anchorToNullifier(wA), bytes32(0));
        (address anchor, uint16 loa, uint64 verifiedAt, uint64 reverifiedAt) = registry.identities(NULL_A);
        assertEq(anchor, address(0));
        assertEq(loa, 0);
        assertEq(verifiedAt, 0);
        assertEq(reverifiedAt, 0);
        // SBT burned
        assertEq(sbt.ownerOfNullifier(NULL_A), address(0));
        assertEq(sbt.balanceOf(wA), 0);
    }

    function test_revoke_notClaimed_reverts() public {
        vm.expectRevert(IdentityRegistry.NotClaimed.selector);
        registry.revoke(NULL_A);
    }

    function test_revoke_onlyGovernance() public {
        _claim(wA, NULL_A, 3);
        vm.prank(wA);
        vm.expectRevert(IdentityRegistry.NotGovernance.selector);
        registry.revoke(NULL_A);
    }

    function test_reclaimAfterRevoke() public {
        _claim(wA, NULL_A, 3);
        registry.revoke(NULL_A);
        // same person can re-claim (fresh attestation), even onto a new wallet
        _claim(wB, NULL_A, 3);
        assertTrue(registry.isPerson(wB));
        assertEq(sbt.ownerOfNullifier(NULL_A), wB);
        // and the freed old anchor is reusable by someone else
        _claim(wA, NULL_B, 3);
        assertEq(sbt.ownerOfNullifier(NULL_B), wA);
    }

    // --- governance ---

    function test_setVerifier_onlyGovernance() public {
        vm.prank(wA);
        vm.expectRevert(IdentityRegistry.NotGovernance.selector);
        registry.setVerifier(IVerifier(address(0x1)));

        registry.setVerifier(IVerifier(address(0x1)));
        assertEq(address(registry.verifier()), address(0x1));
    }

    function test_setMinLoA_onlyGovernance() public {
        vm.prank(wA);
        vm.expectRevert(IdentityRegistry.NotGovernance.selector);
        registry.setMinLoA(3);

        registry.setMinLoA(3);
        assertEq(registry.minLoA(), 3);
    }

    function test_transferGovernance() public {
        registry.transferGovernance(wA);
        assertEq(registry.governance(), wA);
        // old gov locked out
        vm.expectRevert(IdentityRegistry.NotGovernance.selector);
        registry.setMinLoA(3);
    }

    function test_transferGovernance_zero_reverts() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        registry.transferGovernance(address(0));
    }

    // --- constructor guards ---

    function test_constructor_zeroGov_reverts() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        new IdentityRegistry(address(0), IVerifier(address(verifier)), IPersonhoodSBT(address(sbt)), MIN_LOA);
    }

    function test_constructor_zeroSbt_reverts() public {
        vm.expectRevert(IdentityRegistry.ZeroAddress.selector);
        new IdentityRegistry(gov, IVerifier(address(verifier)), IPersonhoodSBT(address(0)), MIN_LOA);
    }
}
