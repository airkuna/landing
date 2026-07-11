// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Base} from "./Base.t.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";

contract EIP712VerifierTest is Base {
    EIP712Verifier internal verifier;

    address internal admin = address(0xA);
    address internal outsider = address(0xBEEF);

    // three authorized signers + one unauthorized
    uint256 internal pk1 = 0x1111;
    uint256 internal pk2 = 0x2222;
    uint256 internal pk3 = 0x3333;
    uint256 internal pkEvil = 0x9999;

    bytes32 internal constant NULL = keccak256("nullifier-1");
    uint16 internal constant LOA = 3;
    address internal constant ANCHOR = address(0xA11CE);

    function setUp() public {
        // start at a non-zero time so we can set expiries in the past
        vm.warp(1_000_000);
        vm.prank(admin);
        verifier = new EIP712Verifier(admin, 1);
        vm.startPrank(admin);
        verifier.addSigner(vm.addr(pk1));
        verifier.addSigner(vm.addr(pk2));
        verifier.addSigner(vm.addr(pk3));
        vm.stopPrank();
    }

    function _exp() internal view returns (uint64) {
        return uint64(block.timestamp + 600);
    }

    // --- happy paths ---

    function test_singleSigner_valid() public {
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        bytes memory proof = _singleProof(pk1, digest);
        (bytes32 n, uint16 loa) = verifier.verify(ANCHOR, att, proof);
        assertEq(n, NULL);
        assertEq(loa, LOA);
    }

    function test_MofN_valid() public {
        vm.prank(admin);
        verifier.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);

        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk2;
        bytes memory proof = _sortedProof(pks, digest);
        (bytes32 n, uint16 loa) = verifier.verify(ANCHOR, att, proof);
        assertEq(n, NULL);
        assertEq(loa, LOA);
    }

    // --- revert branches ---

    function test_belowThreshold_reverts() public {
        vm.prank(admin);
        verifier.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        bytes memory proof = _singleProof(pk1, digest); // only 1 sig, need 2
        vm.expectRevert(EIP712Verifier.NotEnoughSigners.selector);
        verifier.verify(ANCHOR, att, proof);
    }

    function test_unsorted_reverts() public {
        vm.prank(admin);
        verifier.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);

        // build sorted, then reverse to force descending order
        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk2;
        // sort ascending first
        if (vm.addr(pk1) > vm.addr(pk2)) {
            pks[0] = pk1;
            pks[1] = pk2;
        }
        // deliberately reversed relative to ascending
        uint256[] memory rev = new uint256[](2);
        // ensure descending: put the larger address first
        (address lo, address hi) = vm.addr(pk1) < vm.addr(pk2) ? (vm.addr(pk1), vm.addr(pk2)) : (vm.addr(pk2), vm.addr(pk1));
        rev[0] = (vm.addr(pk1) == hi) ? pk1 : pk2; // hi first
        rev[1] = (vm.addr(pk1) == lo) ? pk1 : pk2; // lo second
        bytes memory proof = _proof(rev, digest);
        vm.expectRevert(EIP712Verifier.SignersNotSorted.selector);
        verifier.verify(ANCHOR, att, proof);
    }

    function test_duplicateSigner_reverts() public {
        vm.prank(admin);
        verifier.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk1; // same signer twice → signer <= last
        bytes memory proof = _proof(pks, digest);
        vm.expectRevert(EIP712Verifier.SignersNotSorted.selector);
        verifier.verify(ANCHOR, att, proof);
    }

    function test_unauthorizedSigner_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        bytes memory proof = _singleProof(pkEvil, digest); // not a signer
        vm.expectRevert(EIP712Verifier.UnauthorizedSigner.selector);
        verifier.verify(ANCHOR, att, proof);
    }

    function test_expired_reverts() public {
        uint64 expiry = uint64(block.timestamp - 1);
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        bytes memory proof = _singleProof(pk1, digest);
        vm.expectRevert(EIP712Verifier.Expired.selector);
        verifier.verify(ANCHOR, att, proof);
    }

    function test_wrongAnchor_reverts() public {
        // attestation signed for ANCHOR but presented for another anchor → recovered signer
        // won't be authorized (digest differs) → UnauthorizedSigner.
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        bytes memory proof = _singleProof(pk1, digest);
        vm.expectRevert(EIP712Verifier.UnauthorizedSigner.selector);
        verifier.verify(address(0xDEAD), att, proof);
    }

    // --- signature hardening (EIP-2 low-s, ecrecover zero) ---

    function test_highS_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk1, digest);
        // malleate: s' = n - s, v' flipped — same signer without EIP-2, rejected with it
        uint256 secp256k1n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 sHigh = bytes32(secp256k1n - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = abi.encodePacked(r, sHigh, vFlipped);
        vm.expectRevert(EIP712Verifier.BadSignature.selector);
        verifier.verify(ANCHOR, att, abi.encode(sigs));
    }

    function test_zeroRecovered_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes32 digest = _digest(verifier, ANCHOR, NULL, LOA, expiry);
        (, bytes32 r, bytes32 s) = vm.sign(pk1, digest);
        // invalid v (not 27/28) makes ecrecover return address(0)
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = abi.encodePacked(r, s, uint8(2));
        vm.expectRevert(EIP712Verifier.BadSignature.selector);
        verifier.verify(ANCHOR, att, abi.encode(sigs));
    }

    // --- admin surface ---

    function test_badSigLength_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _attestation(NULL, LOA, expiry);
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = hex"deadbeef"; // not 65 bytes
        bytes memory proof = abi.encode(sigs);
        vm.expectRevert(bytes("bad sig len"));
        verifier.verify(ANCHOR, att, proof);
    }

    function test_addSigner_idempotent() public {
        vm.prank(admin);
        verifier.addSigner(vm.addr(pk1)); // already a signer → no-op
        assertEq(verifier.signerCount(), 3);
    }

    function test_addRemoveSigner_onlyAdmin() public {
        vm.prank(outsider);
        vm.expectRevert(EIP712Verifier.NotAdmin.selector);
        verifier.addSigner(outsider);

        vm.prank(outsider);
        vm.expectRevert(EIP712Verifier.NotAdmin.selector);
        verifier.removeSigner(vm.addr(pk1));
    }

    function test_signerCount_tracks() public {
        assertEq(verifier.signerCount(), 3);
        vm.prank(admin);
        verifier.removeSigner(vm.addr(pk3));
        assertEq(verifier.signerCount(), 2);
        assertFalse(verifier.isSigner(vm.addr(pk3)));
        // idempotent add/remove
        vm.prank(admin);
        verifier.removeSigner(vm.addr(pk3)); // no-op
        assertEq(verifier.signerCount(), 2);
    }

    function test_removeSigner_thresholdGuard() public {
        vm.prank(admin);
        verifier.setThreshold(3); // M = N = 3
        vm.prank(admin);
        vm.expectRevert(EIP712Verifier.ThresholdUnsatisfiable.selector);
        verifier.removeSigner(vm.addr(pk3)); // would leave N = 2 < M = 3

        vm.prank(admin);
        verifier.setThreshold(2);
        vm.prank(admin);
        verifier.removeSigner(vm.addr(pk3)); // now N = 2 >= M = 2
        assertEq(verifier.signerCount(), 2);
    }

    function test_transferAdmin_zero_reverts() public {
        vm.prank(admin);
        vm.expectRevert(EIP712Verifier.ZeroAddress.selector);
        verifier.transferAdmin(address(0));
    }

    function test_setThreshold_bounds() public {
        vm.prank(admin);
        vm.expectRevert(EIP712Verifier.BadThreshold.selector);
        verifier.setThreshold(0);

        vm.prank(admin);
        vm.expectRevert(EIP712Verifier.BadThreshold.selector);
        verifier.setThreshold(4); // > signerCount (3)

        vm.prank(admin);
        verifier.setThreshold(3);
        assertEq(verifier.threshold(), 3);
    }

    function test_setThreshold_onlyAdmin() public {
        vm.prank(outsider);
        vm.expectRevert(EIP712Verifier.NotAdmin.selector);
        verifier.setThreshold(2);
    }

    function test_transferAdmin() public {
        vm.prank(admin);
        verifier.transferAdmin(outsider);
        assertEq(verifier.admin(), outsider);
        // old admin locked out
        vm.prank(admin);
        vm.expectRevert(EIP712Verifier.NotAdmin.selector);
        verifier.addSigner(admin);
    }

    function test_domainSeparator_bindsChainAndContract() public view {
        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("airKUNA PersonhoodVerifier")),
                keccak256(bytes("1")),
                block.chainid,
                address(verifier)
            )
        );
        assertEq(verifier.domainSeparator(), expected);
    }
}
