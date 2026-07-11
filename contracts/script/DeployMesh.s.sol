// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {VerifierNodeRegistry} from "../src/verifiers/VerifierNodeRegistry.sol";
import {MeshVerifier} from "../src/verifiers/MeshVerifier.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {IVerifier} from "../src/interfaces/IVerifier.sol";

/// @title DeployMesh — verifier D (Android mesh) add-on for an EXISTING MVP stack.
/// @notice Deliberately a SEPARATE script from DeployMVP (not an extension of it): the mesh is
///         Faza 2 and, per docs/18 ("A2 → D je kontinuum"), it arrives on an already-live
///         registry — so this script takes the deployed IdentityRegistry as INPUT and cannot
///         disturb the default MVP wiring (EIP712Verifier stays the registry's verifier).
///         Swapping the registry to the mesh is a governance act (`setVerifier`), kept behind
///         the explicit SET_VERIFIER env flag and only executed when the broadcaster IS the
///         registry governance; otherwise the exact call for the DAO Safe is printed.
///
/// @dev Env config:
///   PRIVATE_KEY       — deployer key (broadcasts). REQUIRED.
///   IDENTITY_REGISTRY — the live IdentityRegistry from DeployMVP. REQUIRED.
///   MESH_ADMIN        — MeshVerifier admin (sets threshold).            default: deployer
///   NODE_GOVERNANCE   — VerifierNodeRegistry governance (admits/ejects). default: deployer
///   TREASURY          — slash destination.                              default: NODE_GOVERNANCE
///   MIN_STAKE         — node stake in wei (0 = staking off).            default: 0 (otvorena odluka)
///   UNSTAKE_DELAY     — seconds offline before stake withdrawal.        default: 7 days (otvorena odluka)
///   MESH_THRESHOLD    — initial M (docs/18: first ring is 3-of-5).      default: 3
///   SET_VERIFIER      — if true AND broadcaster is registry governance,
///                       calls registry.setVerifier(mesh).               default: false
///
/// Usage (Chiado, after DeployMVP):
///   IDENTITY_REGISTRY=0x... forge script script/DeployMesh.s.sol:DeployMesh \
///     --rpc-url chiado --broadcast
contract DeployMesh is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        IdentityRegistry registry = IdentityRegistry(vm.envAddress("IDENTITY_REGISTRY"));
        address meshAdmin = vm.envOr("MESH_ADMIN", deployer);
        address nodeGovernance = vm.envOr("NODE_GOVERNANCE", deployer);
        address treasury = vm.envOr("TREASURY", nodeGovernance);
        uint256 minStake = vm.envOr("MIN_STAKE", uint256(0));
        uint256 unstakeDelay = vm.envOr("UNSTAKE_DELAY", uint256(7 days));
        uint256 threshold = vm.envOr("MESH_THRESHOLD", uint256(3));
        bool setVerifier = vm.envOr("SET_VERIFIER", false);

        console2.log("Deployer:        ", deployer);
        console2.log("ChainId:         ", block.chainid);
        console2.log("IdentityRegistry:", address(registry));
        console2.log("Mesh admin:      ", meshAdmin);
        console2.log("Node governance: ", nodeGovernance);
        console2.log("Treasury:        ", treasury);
        console2.log("minStake:        ", minStake);
        console2.log("unstakeDelay:    ", unstakeDelay);
        console2.log("threshold (M):   ", threshold);

        vm.startBroadcast(pk);

        // 1. Node registry — DAO admits Android nodes (pending -> active) after off-chain
        //    verification of their Key Attestation evidence (docs/18).
        VerifierNodeRegistry nodeRegistry = new VerifierNodeRegistry(nodeGovernance, treasury, minStake, unstakeDelay);

        // 2. Mesh verifier — M-of-N EIP-712 attestations from ACTIVE nodes, replay-protected.
        MeshVerifier mesh = new MeshVerifier(meshAdmin, nodeRegistry, registry, threshold);

        // 3. (env-gated) wire the registry to the mesh — a governance act; default MVP wiring
        //    (EIP712Verifier) is untouched unless SET_VERIFIER=true and we ARE governance.
        if (setVerifier && registry.governance() == deployer) {
            registry.setVerifier(IVerifier(address(mesh)));
            console2.log("registry.setVerifier(mesh) executed");
        }

        vm.stopBroadcast();

        console2.log("--- deployed ---");
        console2.log("VerifierNodeRegistry:", address(nodeRegistry));
        console2.log("MeshVerifier:        ", address(mesh));
        console2.log("mesh domainSeparator:");
        console2.logBytes32(mesh.domainSeparator());

        if (!setVerifier || registry.governance() != deployer) {
            console2.log("NOTE: registry verifier UNCHANGED. When the DAO is ready, call from governance:");
            console2.log("  IdentityRegistry.setVerifier(", address(mesh), ")");
        }
        console2.log("Next: nodes call nodeRegistry.register{value: minStake}(signingKey, attestationRef),");
        console2.log("governance verifies the HW attestation off-chain, then nodeRegistry.activate(signingKey),");
        console2.log("then mesh.setThreshold(M) once activeNodeCount >= M (docs/18: 3-of-5).");
    }
}
