// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Base} from "./Base.t.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";
import {MeshVerifier} from "../src/verifiers/MeshVerifier.sol";
import {VerifierNodeRegistry} from "../src/verifiers/VerifierNodeRegistry.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {PersonhoodSBT} from "../src/PersonhoodSBT.sol";
import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {IPersonhoodSBT} from "../src/interfaces/IPersonhoodSBT.sol";

/// @dev Shared fixture: full MVP stack (EIP712Verifier default, per DeployMVP) + the Faza 2
///      mesh add-on (VerifierNodeRegistry + MeshVerifier) with three ACTIVE Android nodes.
abstract contract MeshFixture is Base {
    EIP712Verifier internal a2; // the MVP default verifier
    VerifierNodeRegistry internal nodeReg;
    MeshVerifier internal mesh;
    PersonhoodSBT internal sbt;
    IdentityRegistry internal registry;

    address internal governance = address(0xDA0);
    address internal admin = address(0xAD);
    address internal treasury = address(0x7EA);
    address internal operator = address(0x0B1);
    address internal outsider = address(0xBEEF);

    // three admitted mesh nodes + one that never gets past PENDING
    uint256 internal pk1 = 0x1111;
    uint256 internal pk2 = 0x2222;
    uint256 internal pk3 = 0x3333;
    uint256 internal pkPending = 0x4444;
    uint256 internal pkEvil = 0x9999;

    bytes32 internal constant NULL = keccak256("nullifier-1");
    uint16 internal constant LOA = 3;
    address internal constant ANCHOR = address(0xA11CE);

    uint256 internal constant MIN_STAKE = 1 ether;

    function setUp() public virtual {
        vm.warp(1_000_000);
        vm.deal(operator, 100 ether);

        // MVP stack (mirrors DeployMVP order)
        a2 = new EIP712Verifier(admin, 1);
        sbt = new PersonhoodSBT();
        registry = new IdentityRegistry(governance, IVerifier(address(a2)), IPersonhoodSBT(address(sbt)), 2);
        sbt.setRegistry(address(registry));

        // Faza 2 add-on
        nodeReg = new VerifierNodeRegistry(governance, treasury, MIN_STAKE, 7 days);
        mesh = new MeshVerifier(admin, nodeReg, registry, 1);

        _admitNode(pk1);
        _admitNode(pk2);
        _admitNode(pk3);
        vm.prank(operator);
        nodeReg.register{value: MIN_STAKE}(vm.addr(pkPending), keccak256("att-pending"));
    }

    function _admitNode(uint256 pk) internal {
        address key = vm.addr(pk);
        vm.prank(operator);
        nodeReg.register{value: MIN_STAKE}(key, keccak256(abi.encode("att", pk)));
        vm.prank(governance);
        nodeReg.activate(key);
    }

    function _exp() internal view returns (uint64) {
        return uint64(block.timestamp + 600);
    }

    /// @dev nonce the off-chain node would sign: the person's current reverifiedAt.
    function _nonce(bytes32 nullifier) internal view returns (uint64 reverifiedAt) {
        (,,, reverifiedAt) = registry.identities(nullifier);
    }
}

contract MeshVerifierTest is MeshFixture {
    // --- verify happy paths ---

    function test_singleActiveNode_valid() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        (bytes32 n, uint16 loa) = mesh.verify(ANCHOR, att, _singleProof(pk1, digest));
        assertEq(n, NULL);
        assertEq(loa, LOA);
    }

    function test_MofN_valid() public {
        vm.prank(admin);
        mesh.setThreshold(3);
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);

        uint256[] memory pks = new uint256[](3);
        pks[0] = pk1;
        pks[1] = pk2;
        pks[2] = pk3;
        (bytes32 n, uint16 loa) = mesh.verify(ANCHOR, att, _sortedProof(pks, digest));
        assertEq(n, NULL);
        assertEq(loa, LOA);
    }

    // --- signer-set liveness: signers MUST be ACTIVE nodes at verification time ---

    function test_pendingNode_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, _singleProof(pkPending, digest));
    }

    function test_unregisteredSigner_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, _singleProof(pkEvil, digest));
    }

    function test_deactivatedNode_signatureDiesImmediately() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        bytes memory proof = _singleProof(pk1, digest);
        mesh.verify(ANCHOR, att, proof); // valid while active

        vm.prank(governance);
        nodeReg.deactivate(vm.addr(pk1)); // live check — no cached set
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, proof);
    }

    function test_ejectedNode_signatureDiesImmediately() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        bytes memory proof = _singleProof(pk1, digest);

        vm.prank(governance);
        nodeReg.eject(vm.addr(pk1));
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, proof);
    }

    function test_MofN_oneInactiveCoSigner_reverts() public {
        vm.prank(admin);
        mesh.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk2;
        bytes memory proof = _sortedProof(pks, digest);

        vm.prank(governance);
        nodeReg.deactivate(vm.addr(pk2));
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, proof);
    }

    // --- M-of-N mechanics (parity with EIP712Verifier) ---

    function test_belowThreshold_reverts() public {
        vm.prank(admin);
        mesh.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.NotEnoughSigners.selector);
        mesh.verify(ANCHOR, att, _singleProof(pk1, digest));
    }

    function test_duplicateSigner_reverts() public {
        vm.prank(admin);
        mesh.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk1;
        vm.expectRevert(MeshVerifier.SignersNotSorted.selector);
        mesh.verify(ANCHOR, att, _proof(pks, digest));
    }

    function test_unsorted_reverts() public {
        vm.prank(admin);
        mesh.setThreshold(2);
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        // descending order: larger address first
        (uint256 hiPk, uint256 loPk) = vm.addr(pk1) > vm.addr(pk2) ? (pk1, pk2) : (pk2, pk1);
        uint256[] memory pks = new uint256[](2);
        pks[0] = hiPk;
        pks[1] = loPk;
        vm.expectRevert(MeshVerifier.SignersNotSorted.selector);
        mesh.verify(ANCHOR, att, _proof(pks, digest));
    }

    // --- expiry & replay guards ---

    function test_expired_reverts() public {
        uint64 expiry = uint64(block.timestamp - 1);
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.Expired.selector);
        mesh.verify(ANCHOR, att, _singleProof(pk1, digest));
    }

    function test_nonceMismatch_reverts() public {
        // unclaimed person → registry reverifiedAt == 0, but the attestation carries nonce 1
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 1);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 1);
        vm.expectRevert(MeshVerifier.NonceMismatch.selector);
        mesh.verify(ANCHOR, att, _singleProof(pk1, digest));
    }

    function test_wrongAnchor_reverts() public {
        // digest binds the anchor: presenting for another anchor recovers a different (inactive) signer
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(address(0xDEAD), att, _singleProof(pk1, digest));
    }

    // --- signature hardening (parity with EIP712Verifier) ---

    function test_highS_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk1, digest);
        uint256 secp256k1n = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
        bytes32 sHigh = bytes32(secp256k1n - uint256(s));
        uint8 vFlipped = v == 27 ? 28 : 27;
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = abi.encodePacked(r, sHigh, vFlipped);
        vm.expectRevert(MeshVerifier.BadSignature.selector);
        mesh.verify(ANCHOR, att, abi.encode(sigs));
    }

    function test_zeroRecovered_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes32 digest = _meshDigest(mesh, ANCHOR, NULL, LOA, expiry, 0);
        (, bytes32 r, bytes32 s) = vm.sign(pk1, digest);
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = abi.encodePacked(r, s, uint8(2)); // invalid v → ecrecover 0
        vm.expectRevert(MeshVerifier.BadSignature.selector);
        mesh.verify(ANCHOR, att, abi.encode(sigs));
    }

    function test_badSigLength_reverts() public {
        uint64 expiry = _exp();
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        bytes[] memory sigs = new bytes[](1);
        sigs[0] = hex"deadbeef";
        vm.expectRevert(bytes("bad sig len"));
        mesh.verify(ANCHOR, att, abi.encode(sigs));
    }

    // --- constructor & admin surface ---

    function test_constructor_zeroArgs_revert() public {
        vm.expectRevert(MeshVerifier.ZeroAddress.selector);
        new MeshVerifier(address(0), nodeReg, registry, 1);
        vm.expectRevert(MeshVerifier.ZeroAddress.selector);
        new MeshVerifier(admin, VerifierNodeRegistry(address(0)), registry, 1);
        vm.expectRevert(MeshVerifier.ZeroAddress.selector);
        new MeshVerifier(admin, nodeReg, IdentityRegistry(address(0)), 1);
        vm.expectRevert(MeshVerifier.BadThreshold.selector);
        new MeshVerifier(admin, nodeReg, registry, 0);
    }

    function test_setThreshold_zero_reverts() public {
        vm.prank(admin);
        vm.expectRevert(MeshVerifier.BadThreshold.selector);
        mesh.setThreshold(0);
    }

    function test_setThreshold_aboveActiveNodeCount_reverts() public {
        // 3 active nodes; 4 must be unsatisfiable
        vm.prank(admin);
        vm.expectRevert(MeshVerifier.ThresholdUnsatisfiable.selector);
        mesh.setThreshold(4);

        vm.prank(admin);
        mesh.setThreshold(3);
        assertEq(mesh.threshold(), 3);

        // ejection shrinks the ceiling — live count, not a snapshot
        vm.prank(governance);
        nodeReg.eject(vm.addr(pk3));
        vm.prank(admin);
        vm.expectRevert(MeshVerifier.ThresholdUnsatisfiable.selector);
        mesh.setThreshold(3);
    }

    function test_setThreshold_onlyAdmin() public {
        vm.prank(outsider);
        vm.expectRevert(MeshVerifier.NotAdmin.selector);
        mesh.setThreshold(2);
    }

    function test_transferAdmin_twoStep() public {
        vm.prank(admin);
        mesh.transferAdmin(outsider);
        assertEq(mesh.admin(), admin); // unchanged until accepted
        vm.prank(outsider);
        mesh.acceptAdmin();
        assertEq(mesh.admin(), outsider);
        assertEq(mesh.pendingAdmin(), address(0));

        vm.prank(admin);
        vm.expectRevert(MeshVerifier.NotAdmin.selector);
        mesh.setThreshold(1);
    }

    function test_acceptAdmin_wrongCaller_reverts() public {
        vm.prank(admin);
        mesh.transferAdmin(outsider);
        vm.prank(operator);
        vm.expectRevert(MeshVerifier.NotPendingAdmin.selector);
        mesh.acceptAdmin();
    }

    function test_transferAdmin_zero_reverts() public {
        vm.prank(admin);
        vm.expectRevert(MeshVerifier.ZeroAddress.selector);
        mesh.transferAdmin(address(0));
    }

    function test_domainSeparator_bindsChainAndContract() public view {
        bytes32 expected = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("airKUNA PersonhoodVerifier")),
                keccak256(bytes("1")),
                block.chainid,
                address(mesh)
            )
        );
        assertEq(mesh.domainSeparator(), expected);
    }

    function test_a2Signature_notValidOnMesh() public {
        // same-family domain but different typehash + verifyingContract: an A2 signature must not
        // recover to an active node on the mesh (cross-verifier replay ruled out).
        vm.startPrank(admin);
        a2.addSigner(vm.addr(pk1));
        vm.stopPrank();
        uint64 expiry = _exp();
        bytes32 a2Digest = _digest(a2, ANCHOR, NULL, LOA, expiry);
        bytes memory att = _meshAttestation(NULL, LOA, expiry, 0);
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        mesh.verify(ANCHOR, att, _singleProof(pk1, a2Digest));
    }
}

/// @dev End-to-end: governance swaps the registry's verifier to the mesh (ADR 0002 — registry is
///      verifier-agnostic) and a person claims / reverifies / migrates through M-of-N node sigs.
contract MeshE2ETest is MeshFixture {
    address internal constant NEW_ANCHOR = address(0xB0B2);

    function setUp() public override {
        super.setUp();
        vm.prank(admin);
        mesh.setThreshold(2); // 2-of-3 mesh
        vm.prank(governance);
        registry.setVerifier(IVerifier(address(mesh)));
    }

    function _meshProof2(address anchor, bytes32 nullifier, uint64 expiry, uint64 nonce)
        internal
        returns (bytes memory att, bytes memory proof)
    {
        att = _meshAttestation(nullifier, LOA, expiry, nonce);
        bytes32 digest = _meshDigest(mesh, anchor, nullifier, LOA, expiry, nonce);
        uint256[] memory pks = new uint256[](2);
        pks[0] = pk1;
        pks[1] = pk2;
        proof = _sortedProof(pks, digest);
    }

    function test_claim_throughMesh() public {
        (bytes memory att, bytes memory proof) = _meshProof2(ANCHOR, NULL, _exp(), _nonce(NULL));
        registry.claim(ANCHOR, att, proof);

        assertTrue(registry.isPerson(ANCHOR));
        assertEq(sbt.ownerOfNullifier(NULL), ANCHOR);
        assertEq(registry.anchorToNullifier(ANCHOR), NULL);
    }

    function test_claim_throughMesh_inactiveNode_reverts() public {
        (bytes memory att, bytes memory proof) = _meshProof2(ANCHOR, NULL, _exp(), 0);
        vm.prank(governance);
        nodeReg.eject(vm.addr(pk2));
        vm.expectRevert(MeshVerifier.InactiveNode.selector);
        registry.claim(ANCHOR, att, proof);
    }

    function test_reverify_throughMesh_and_replayRejected() public {
        (bytes memory att, bytes memory proof) = _meshProof2(ANCHOR, NULL, _exp(), 0);
        registry.claim(ANCHOR, att, proof);

        // fresh attestation for reverify: nonce = current reverifiedAt (set by claim)
        vm.warp(block.timestamp + 100);
        uint64 nonce = _nonce(NULL);
        (bytes memory att2, bytes memory proof2) = _meshProof2(ANCHOR, NULL, _exp(), nonce);
        vm.prank(ANCHOR);
        registry.reverify(att2, proof2);
        assertEq(_nonce(NULL), uint64(block.timestamp)); // consumed marker advanced

        // REPLAY: the very same attestation again (still unexpired) → nonce no longer matches
        vm.warp(block.timestamp + 1);
        vm.prank(ANCHOR);
        vm.expectRevert(MeshVerifier.NonceMismatch.selector);
        registry.reverify(att2, proof2);
    }

    function test_migrateAnchor_throughMesh_and_replayRejected() public {
        (bytes memory att, bytes memory proof) = _meshProof2(ANCHOR, NULL, _exp(), 0);
        registry.claim(ANCHOR, att, proof);

        vm.warp(block.timestamp + 100);
        (bytes memory att2, bytes memory proof2) = _meshProof2(NEW_ANCHOR, NULL, _exp(), _nonce(NULL));
        registry.migrateAnchor(NEW_ANCHOR, att2, proof2);
        assertEq(sbt.ownerOfNullifier(NULL), NEW_ANCHOR);
        assertEq(registry.anchorToNullifier(ANCHOR), bytes32(0));

        // person moves on to a third anchor, freeing NEW_ANCHOR again...
        vm.warp(block.timestamp + 100);
        (bytes memory att3, bytes memory proof3) = _meshProof2(address(0xC0C3), NULL, _exp(), _nonce(NULL));
        registry.migrateAnchor(address(0xC0C3), att3, proof3);

        // ...so ONLY the nonce stops replaying att2 to yank the SBT back to NEW_ANCHOR
        vm.warp(block.timestamp + 1);
        vm.expectRevert(MeshVerifier.NonceMismatch.selector);
        registry.migrateAnchor(NEW_ANCHOR, att2, proof2);
    }

    function test_claimReplay_afterRevoke_blockedByExpiry() public {
        (bytes memory att, bytes memory proof) = _meshProof2(ANCHOR, NULL, _exp(), 0);
        registry.claim(ANCHOR, att, proof);
        vm.prank(governance);
        registry.revoke(NULL);

        // revoke resets reverifiedAt to 0, so the old claim attestation matches the nonce again —
        // the documented residual (open decision); the short expiry is the current mitigation.
        vm.warp(block.timestamp + 601);
        vm.expectRevert(MeshVerifier.Expired.selector);
        registry.claim(ANCHOR, att, proof);
    }

    function test_mvpDefaultUnchanged_thenUpgrade() public {
        // sanity for the deploy story: a registry born on EIP712Verifier (DeployMVP) keeps working,
        // and setVerifier(mesh) is the only wiring change Faza 2 needs.
        IdentityRegistry fresh =
            new IdentityRegistry(governance, IVerifier(address(a2)), IPersonhoodSBT(address(new PersonhoodSBT())), 2);
        assertEq(address(fresh.verifier()), address(a2));
        vm.prank(governance);
        fresh.setVerifier(IVerifier(address(mesh)));
        assertEq(address(fresh.verifier()), address(mesh));
    }
}
