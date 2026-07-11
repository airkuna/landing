// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Base} from "./Base.t.sol";
import {KunaToken} from "../src/KunaToken.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {PersonhoodSBT} from "../src/PersonhoodSBT.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";
import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {IPersonhoodSBT} from "../src/interfaces/IPersonhoodSBT.sol";
import {IERC677Receiver} from "../src/interfaces/IERC677Receiver.sol";

/// @dev Minimal ERC-677 recipient: records the callback and can be armed to revert.
contract ERC677ReceiverMock is IERC677Receiver {
    address public lastFrom;
    uint256 public lastAmount;
    bytes public lastData;
    uint256 public calls;
    bool public shouldRevert;

    error ReceiverRejected();

    function setRevert(bool shouldRevert_) external {
        shouldRevert = shouldRevert_;
    }

    function onTokenTransfer(address from, uint256 amount, bytes calldata data) external {
        if (shouldRevert) revert ReceiverRejected();
        lastFrom = from;
        lastAmount = amount;
        lastData = data;
        calls++;
    }
}

contract KunaTokenTest is Base {
    KunaToken internal kuna;
    IdentityRegistry internal registry;
    PersonhoodSBT internal sbt;
    EIP712Verifier internal verifier;

    address internal gov = address(this); // governance = this test
    address internal issuer = address(0x155EA);
    uint256 internal oraclePk;

    uint16 internal constant MIN_LOA = 2;

    // alice is key-based so she can sign EIP-2612 permits
    uint256 internal alicePk = 0xA11CE;
    address internal alice;
    address internal bob = address(0xB0B); // never a person
    address internal carol = address(0xCA401);

    bytes32 internal constant NULL_ALICE = keccak256("oib-alice");
    bytes32 internal constant NULL_CAROL = keccak256("oib-carol");

    uint256 internal constant ONE = 1e18;

    function setUp() public {
        vm.warp(1_000_000);
        alice = vm.addr(alicePk);
        oraclePk = 0xABCDEF;

        // real identity stack (integration): verifier -> registry -> sbt
        verifier = new EIP712Verifier(gov, 1);
        verifier.addSigner(vm.addr(oraclePk));
        sbt = new PersonhoodSBT();
        registry = new IdentityRegistry(gov, IVerifier(address(verifier)), IPersonhoodSBT(address(sbt)), MIN_LOA);
        sbt.setRegistry(address(registry));

        kuna = new KunaToken(gov, issuer, address(registry));

        // alice claims personhood through the REAL claim flow
        _claim(alice, NULL_ALICE, 3);
    }

    // --- helpers ---

    function _claim(address anchor, bytes32 nullifier, uint16 loa) internal {
        uint64 expiry = uint64(block.timestamp + 600);
        bytes memory att = _attestation(nullifier, loa, expiry);
        bytes32 digest = _digest(verifier, anchor, nullifier, loa, expiry);
        registry.claim(anchor, att, _singleProof(oraclePk, digest));
    }

    function _mint(address to, uint256 amount) internal {
        vm.prank(issuer);
        kuna.mint(to, amount);
    }

    function _permitDigest(address owner, address spender, uint256 value, uint256 nonce, uint256 deadline)
        internal
        view
        returns (bytes32)
    {
        bytes32 structHash = keccak256(abi.encode(kuna.PERMIT_TYPEHASH(), owner, spender, value, nonce, deadline));
        return keccak256(abi.encodePacked("\x19\x01", kuna.DOMAIN_SEPARATOR(), structHash));
    }

    // --- metadata ---

    function test_metadata() public view {
        assertEq(kuna.name(), "airKUNA");
        assertEq(kuna.symbol(), "KUNA");
        assertEq(kuna.decimals(), 18);
        assertEq(kuna.governance(), gov);
        assertEq(kuna.issuer(), issuer);
        assertEq(address(kuna.identityRegistry()), address(registry));
    }

    function test_constructor_zeroArgs_revert() public {
        vm.expectRevert(KunaToken.ZeroAddress.selector);
        new KunaToken(address(0), issuer, address(registry));
        vm.expectRevert(KunaToken.ZeroAddress.selector);
        new KunaToken(gov, address(0), address(registry));
        // registry = 0 is legal (personhood policy off)
        KunaToken free = new KunaToken(gov, issuer, address(0));
        assertEq(address(free.identityRegistry()), address(0));
    }

    // --- mint (SEPA deposit) ---

    function test_mint_onlyIssuer() public {
        // even governance may not mint
        vm.expectRevert(KunaToken.NotIssuer.selector);
        kuna.mint(alice, ONE);
    }

    function test_mint_toPerson_emitsEvents() public {
        vm.expectEmit(true, true, false, true);
        emit KunaToken.Transfer(address(0), alice, 100 * ONE);
        vm.expectEmit(true, false, false, true);
        emit KunaToken.Minted(alice, 100 * ONE);
        _mint(alice, 100 * ONE);

        assertEq(kuna.balanceOf(alice), 100 * ONE);
        assertEq(kuna.totalSupply(), 100 * ONE);
    }

    function test_mint_toNonPerson_reverts() public {
        vm.prank(issuer);
        vm.expectRevert(KunaToken.NotPerson.selector);
        kuna.mint(bob, ONE);
    }

    function test_mint_zeroAddress_reverts() public {
        vm.prank(issuer);
        vm.expectRevert(KunaToken.ZeroAddress.selector);
        kuna.mint(address(0), ONE);
    }

    function test_mint_policyOff_allowsAnyRecipient() public {
        kuna.setIdentityRegistry(address(0)); // governance turns the policy off
        _mint(bob, ONE);
        assertEq(kuna.balanceOf(bob), ONE);
    }

    function test_mint_afterRevoke_reverts() public {
        // personhood revoked in the registry -> issuance to that wallet stops (integration)
        registry.revoke(NULL_ALICE);
        vm.prank(issuer);
        vm.expectRevert(KunaToken.NotPerson.selector);
        kuna.mint(alice, ONE);
    }

    function test_mint_whenPaused_reverts() public {
        kuna.pause();
        vm.prank(issuer);
        vm.expectRevert(KunaToken.EnforcedPause.selector);
        kuna.mint(alice, ONE);
    }

    // --- burnFrom (redemption) ---

    function test_burnFrom_onlyIssuer() public {
        _mint(alice, ONE);
        vm.prank(alice); // not even the holder may burn directly
        vm.expectRevert(KunaToken.NotIssuer.selector);
        kuna.burnFrom(alice, ONE);
    }

    function test_burnFrom_redeems_emitsEvents() public {
        _mint(alice, 100 * ONE);

        vm.expectEmit(true, true, false, true);
        emit KunaToken.Transfer(alice, address(0), 40 * ONE);
        vm.expectEmit(true, false, false, true);
        emit KunaToken.Redeemed(alice, 40 * ONE);
        vm.prank(issuer);
        kuna.burnFrom(alice, 40 * ONE);

        assertEq(kuna.balanceOf(alice), 60 * ONE);
        assertEq(kuna.totalSupply(), 60 * ONE);
    }

    function test_burnFrom_insufficientBalance_reverts() public {
        _mint(alice, ONE);
        vm.prank(issuer);
        vm.expectRevert(KunaToken.InsufficientBalance.selector);
        kuna.burnFrom(alice, 2 * ONE);
    }

    /// @dev MiCA: redemption at par is a right — the burn must work even while paused.
    function test_burnFrom_worksWhilePaused() public {
        _mint(alice, 100 * ONE);
        kuna.pause();

        vm.prank(alice);
        vm.expectRevert(KunaToken.EnforcedPause.selector);
        kuna.transfer(bob, ONE); // circulation frozen...

        vm.prank(issuer);
        kuna.burnFrom(alice, 100 * ONE); // ...but the exit is not
        assertEq(kuna.balanceOf(alice), 0);
        assertEq(kuna.totalSupply(), 0);
    }

    // --- ERC-20 transfer / approve / transferFrom ---

    function test_transfer_freeOfPersonhood() public {
        _mint(alice, 10 * ONE);
        // bob is NOT a person — transfers are not gated, only issuance is
        vm.expectEmit(true, true, false, true);
        emit KunaToken.Transfer(alice, bob, 3 * ONE);
        vm.prank(alice);
        assertTrue(kuna.transfer(bob, 3 * ONE));
        assertEq(kuna.balanceOf(alice), 7 * ONE);
        assertEq(kuna.balanceOf(bob), 3 * ONE);
    }

    function test_transfer_insufficientBalance_reverts() public {
        vm.prank(alice);
        vm.expectRevert(KunaToken.InsufficientBalance.selector);
        kuna.transfer(bob, ONE);
    }

    function test_transfer_zeroAddress_reverts() public {
        _mint(alice, ONE);
        vm.prank(alice);
        vm.expectRevert(KunaToken.ZeroAddress.selector);
        kuna.transfer(address(0), ONE);
    }

    function test_transfer_whenPaused_reverts() public {
        _mint(alice, ONE);
        kuna.pause();
        vm.prank(alice);
        vm.expectRevert(KunaToken.EnforcedPause.selector);
        kuna.transfer(bob, ONE);
        // and unpause restores
        kuna.unpause();
        vm.prank(alice);
        kuna.transfer(bob, ONE);
        assertEq(kuna.balanceOf(bob), ONE);
    }

    function test_approve_transferFrom() public {
        _mint(alice, 10 * ONE);

        vm.expectEmit(true, true, false, true);
        emit KunaToken.Approval(alice, bob, 4 * ONE);
        vm.prank(alice);
        assertTrue(kuna.approve(bob, 4 * ONE));
        assertEq(kuna.allowance(alice, bob), 4 * ONE);

        vm.prank(bob);
        assertTrue(kuna.transferFrom(alice, carol, 3 * ONE));
        assertEq(kuna.balanceOf(carol), 3 * ONE);
        assertEq(kuna.allowance(alice, bob), ONE); // decremented
    }

    function test_transferFrom_infiniteAllowance_notDecremented() public {
        _mint(alice, 10 * ONE);
        vm.prank(alice);
        kuna.approve(bob, type(uint256).max);
        vm.prank(bob);
        kuna.transferFrom(alice, carol, 3 * ONE);
        assertEq(kuna.allowance(alice, bob), type(uint256).max);
    }

    function test_transferFrom_insufficientAllowance_reverts() public {
        _mint(alice, 10 * ONE);
        vm.prank(alice);
        kuna.approve(bob, ONE);
        vm.prank(bob);
        vm.expectRevert(KunaToken.InsufficientAllowance.selector);
        kuna.transferFrom(alice, carol, 2 * ONE);
    }

    // --- ERC-677 transferAndCall ---

    function test_transferAndCall_toEOA() public {
        _mint(alice, 10 * ONE);
        vm.expectEmit(true, true, false, true);
        emit KunaToken.Transfer(alice, bob, ONE, hex"1234");
        vm.prank(alice);
        assertTrue(kuna.transferAndCall(bob, ONE, hex"1234"));
        assertEq(kuna.balanceOf(bob), ONE); // no callback on EOAs
    }

    function test_transferAndCall_notifiesContract() public {
        ERC677ReceiverMock receiver = new ERC677ReceiverMock();
        _mint(alice, 10 * ONE);

        vm.prank(alice);
        kuna.transferAndCall(address(receiver), 2 * ONE, abi.encode("pinka", uint256(42)));

        assertEq(kuna.balanceOf(address(receiver)), 2 * ONE);
        assertEq(receiver.calls(), 1);
        assertEq(receiver.lastFrom(), alice);
        assertEq(receiver.lastAmount(), 2 * ONE);
        assertEq(receiver.lastData(), abi.encode("pinka", uint256(42)));
    }

    function test_transferAndCall_receiverReverts_bubbles() public {
        ERC677ReceiverMock receiver = new ERC677ReceiverMock();
        receiver.setRevert(true);
        _mint(alice, ONE);
        vm.prank(alice);
        vm.expectRevert(ERC677ReceiverMock.ReceiverRejected.selector);
        kuna.transferAndCall(address(receiver), ONE, "");
        assertEq(kuna.balanceOf(alice), ONE); // nothing moved
    }

    function test_transferAndCall_whenPaused_reverts() public {
        _mint(alice, ONE);
        kuna.pause();
        vm.prank(alice);
        vm.expectRevert(KunaToken.EnforcedPause.selector);
        kuna.transferAndCall(bob, ONE, "");
    }

    // --- EIP-2612 permit ---

    function test_permit_setsAllowance() public {
        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, _permitDigest(alice, bob, 5 * ONE, 0, deadline));

        vm.expectEmit(true, true, false, true);
        emit KunaToken.Approval(alice, bob, 5 * ONE);
        kuna.permit(alice, bob, 5 * ONE, deadline, v, r, s); // anyone may submit

        assertEq(kuna.allowance(alice, bob), 5 * ONE);
        assertEq(kuna.nonces(alice), 1);
    }

    function test_permit_expired_reverts() public {
        uint256 deadline = block.timestamp - 1;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, _permitDigest(alice, bob, ONE, 0, deadline));
        vm.expectRevert(KunaToken.PermitExpired.selector);
        kuna.permit(alice, bob, ONE, deadline, v, r, s);
    }

    function test_permit_wrongSigner_reverts() public {
        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(0xBADBAD, _permitDigest(alice, bob, ONE, 0, deadline));
        vm.expectRevert(KunaToken.BadSignature.selector);
        kuna.permit(alice, bob, ONE, deadline, v, r, s);
    }

    function test_permit_replay_reverts() public {
        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, _permitDigest(alice, bob, ONE, 0, deadline));
        kuna.permit(alice, bob, ONE, deadline, v, r, s);
        // nonce consumed -> replay recovers a different address
        vm.expectRevert(KunaToken.BadSignature.selector);
        kuna.permit(alice, bob, ONE, deadline, v, r, s);
    }

    function test_permit_highS_reverts() public {
        uint256 deadline = block.timestamp + 3600;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, _permitDigest(alice, bob, ONE, 0, deadline));
        // malleate into the high-s form — must be rejected (EIP-2)
        uint256 secp256k1n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 sHigh = bytes32(secp256k1n - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;
        vm.expectRevert(KunaToken.BadSignature.selector);
        kuna.permit(alice, bob, ONE, deadline, vFlipped, r, sHigh);
    }

    // --- pause ---

    function test_pause_onlyGovernance() public {
        vm.prank(bob);
        vm.expectRevert(KunaToken.NotGovernance.selector);
        kuna.pause();
        vm.prank(bob);
        vm.expectRevert(KunaToken.NotGovernance.selector);
        kuna.unpause();
    }

    function test_pause_unpause_stateAndEvents() public {
        vm.expectEmit(false, false, false, true);
        emit KunaToken.Paused();
        kuna.pause();
        assertTrue(kuna.paused());

        vm.expectRevert(KunaToken.EnforcedPause.selector);
        kuna.pause(); // double pause

        vm.expectEmit(false, false, false, true);
        emit KunaToken.Unpaused();
        kuna.unpause();
        assertFalse(kuna.paused());

        vm.expectRevert(KunaToken.ExpectedPause.selector);
        kuna.unpause(); // double unpause
    }

    // --- governance (two-step) & config ---

    function test_transferGovernance_twoStep() public {
        vm.expectEmit(true, false, false, true);
        emit KunaToken.GovernanceTransferStarted(carol);
        kuna.transferGovernance(carol);
        assertEq(kuna.pendingGovernance(), carol);
        assertEq(kuna.governance(), gov); // still in charge until accepted
        kuna.setIssuer(address(0xFEED)); // old governance still works

        vm.expectEmit(true, false, false, true);
        emit KunaToken.GovernanceTransferred(carol);
        vm.prank(carol);
        kuna.acceptGovernance();
        assertEq(kuna.governance(), carol);
        assertEq(kuna.pendingGovernance(), address(0));

        // old governance locked out
        vm.expectRevert(KunaToken.NotGovernance.selector);
        kuna.pause();
    }

    function test_acceptGovernance_notPending_reverts() public {
        kuna.transferGovernance(carol);
        vm.prank(bob);
        vm.expectRevert(KunaToken.NotPendingGovernance.selector);
        kuna.acceptGovernance();
    }

    function test_transferGovernance_zero_reverts() public {
        vm.expectRevert(KunaToken.ZeroAddress.selector);
        kuna.transferGovernance(address(0));
    }

    function test_setIssuer() public {
        vm.prank(bob);
        vm.expectRevert(KunaToken.NotGovernance.selector);
        kuna.setIssuer(bob);

        vm.expectRevert(KunaToken.ZeroAddress.selector);
        kuna.setIssuer(address(0));

        vm.expectEmit(true, false, false, true);
        emit KunaToken.IssuerChanged(carol);
        kuna.setIssuer(carol);
        assertEq(kuna.issuer(), carol);
        // old issuer locked out
        vm.prank(issuer);
        vm.expectRevert(KunaToken.NotIssuer.selector);
        kuna.mint(alice, ONE);
    }

    function test_setIdentityRegistry() public {
        vm.prank(bob);
        vm.expectRevert(KunaToken.NotGovernance.selector);
        kuna.setIdentityRegistry(address(0));

        vm.expectEmit(true, false, false, true);
        emit KunaToken.IdentityRegistryChanged(address(0));
        kuna.setIdentityRegistry(address(0));
        assertEq(address(kuna.identityRegistry()), address(0));
    }

    // --- integration: full claim -> mint round-trip for a second person ---

    function test_claimThenMint_integration() public {
        vm.prank(issuer);
        vm.expectRevert(KunaToken.NotPerson.selector);
        kuna.mint(carol, ONE); // not yet a person

        _claim(carol, NULL_CAROL, 3); // real EIP-712 attestation + claim
        _mint(carol, ONE);
        assertEq(kuna.balanceOf(carol), ONE);
    }
}
