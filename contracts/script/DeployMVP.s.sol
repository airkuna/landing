// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {EIP712Verifier} from "../src/verifiers/EIP712Verifier.sol";
import {PersonhoodSBT} from "../src/PersonhoodSBT.sol";
import {IdentityRegistry} from "../src/IdentityRegistry.sol";
import {IVerifier} from "../src/interfaces/IVerifier.sol";
import {IPersonhoodSBT} from "../src/interfaces/IPersonhoodSBT.sol";

/// @title DeployMVP — verifier A2 (thin oracle) MVP stack for Gnosis Chiado.
/// @notice Deploy order resolves the SBT<->Registry constructor cycle (ADR / docs/18):
///   1. EIP712Verifier(admin, threshold = 1)      — the A2 oracle is signer #1 (N=1, M=1)
///   2. PersonhoodSBT()                            — registry wired afterwards
///   3. IdentityRegistry(gov, verifier, sbt, minLoA)
///   4. sbt.setRegistry(registry)                  — one-time wiring
///   5. verifier.addSigner(oracleSigner)           — authorize the A2 verifier's EIP-712 key
///
/// @dev Env config (all optional except PRIVATE_KEY; sensible test defaults derive from the deployer):
///   PRIVATE_KEY    — deployer key (broadcasts). REQUIRED.
///   GOVERNANCE     — IdentityRegistry governance Safe/EOA.   default: deployer
///   ADMIN          — EIP712Verifier admin (manages signers). default: deployer
///   ORACLE_SIGNER  — the A2 verifier's EIP-712 signing address. default: deployer
///   MIN_LOA        — minimum accepted assurance.              default: 2 (substantial)
///
/// Usage (Chiado):
///   forge script script/DeployMVP.s.sol:DeployMVP \
///     --rpc-url chiado --broadcast
contract DeployMVP is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        address governance = vm.envOr("GOVERNANCE", deployer);
        address admin = vm.envOr("ADMIN", deployer);
        address oracleSigner = vm.envOr("ORACLE_SIGNER", deployer);
        uint16 minLoA = uint16(vm.envOr("MIN_LOA", uint256(2)));

        console2.log("Deployer:     ", deployer);
        console2.log("ChainId:      ", block.chainid);
        console2.log("Governance:   ", governance);
        console2.log("Verifier admin:", admin);
        console2.log("Oracle signer:", oracleSigner);
        console2.log("minLoA:       ", minLoA);

        vm.startBroadcast(pk);

        // 1. Verifier (A2 oracle = M-of-N with N=1, M=1)
        EIP712Verifier verifier = new EIP712Verifier(admin, 1);

        // 2. SBT (registry set after)
        PersonhoodSBT sbt = new PersonhoodSBT();

        // 3. Registry
        IdentityRegistry registry =
            new IdentityRegistry(governance, IVerifier(address(verifier)), IPersonhoodSBT(address(sbt)), minLoA);

        // 4. Wire the SBT to the registry (one-time; must be the deployer that created the SBT)
        sbt.setRegistry(address(registry));

        // 5. Authorize the A2 oracle's signing key
        // (only works if the broadcaster is the verifier admin; otherwise do it from `admin` later)
        if (admin == deployer) {
            verifier.addSigner(oracleSigner);
        }

        vm.stopBroadcast();

        console2.log("--- deployed ---");
        console2.log("EIP712Verifier: ", address(verifier));
        console2.log("PersonhoodSBT:  ", address(sbt));
        console2.log("IdentityRegistry:", address(registry));
        console2.log("domainSeparator:");
        console2.logBytes32(verifier.domainSeparator());

        if (admin != deployer) {
            console2.log("NOTE: admin != deployer -> call verifier.addSigner(oracleSigner) from admin.");
        }
    }
}
