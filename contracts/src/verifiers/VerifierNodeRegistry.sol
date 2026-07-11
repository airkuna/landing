// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

/// @title VerifierNodeRegistry — verifier D node registry (Android mesh, Faza 2).
/// @notice Onchain source of truth for the M-of-N Android verifier mesh (docs/18 dio 2,
///         whitepaper §5). Each node is a hardware-attested Android device whose StrongBox/TEE
///         secp256k1 key co-signs EIP-712 personhood attestations. This registry tracks, per
///         signing key, the doc-specified lifecycle
///
///             pending → active → offline → ejected
///
///         where the airKUNA DAO (Safe multisig = `governance`) admits (`activate`) and kicks
///         (`eject`) nodes, exactly as docs/18 prescribes ("DAO onboarding & statusi").
///
///         What is ONCHAIN vs OFF-chain (docs/18):
///         - ONCHAIN: signing-key address, operator address ("poznat ljudski operater po nodeu"),
///           lifecycle status, stake, and an `attestationRef` — a hash/reference of the Android
///           Key Attestation evidence (certificate chain proving the key never left the secure
///           element). The chain does NOT verify Play Integrity / Key Attestation itself; the DAO
///           verifies the evidence off-chain BEFORE voting `activate`. Storing only the hash keeps
///           the admission input auditable without faking X.509 verification onchain.
///         - OFF-chain: Certilia OIDC validation, nullifier computation behind the pepper boundary
///           (ADR 0003), Cloudflare Tunnel transport, geolocation metadata and the map layer.
///
///         Staking (docs/18 "Anti-GPS-spoof: staking + slashing", whitepaper §5): nodes stake
///         native xDAI at registration; `eject` slashes the full stake to a governance-set
///         treasury. The mechanism is deliberately minimal and parameterized because the docs
///         specify only that staking/slashing exists, not its economics.
/// @dev    Reference only — unaudited.
/// @dev    Otvorena odluka: iznos minimalnog stakea (`minStake`) — dokumenti traže staking/slashing
///         ekonomiju za anti-spoof, ali ne specificiraju iznose; default je parametar governancea
///         (0 = staking isključen dok DAO ne odluči).
/// @dev    Otvorena odluka: formula slashinga — ovdje `eject` režе CIJELI stake u treasury;
///         postotni/stupnjeviti slashing (npr. blaži za offline, puni za lažiranje lokacije)
///         ostaje dizajnerska odluka Faze 2.
/// @dev    Otvorena odluka: proof-of-location (GEODNET/XYO stil) i integracija s kartom su
///         off-chain; onchain ne postoji provjera lokacije.
/// @dev    Otvorena odluka: Acurast kao substrat umjesto vlastite mreže (docs/18) — ovaj registar
///         je substrat-agnostičan (Acurast procesori također imaju EVM adresu pa stanu u isti model).
/// @dev    Otvorena odluka: mora li reaktivacija `offline → active` priložiti svježu HW atestaciju
///         (novi `attestationRef`) — dokumenti šute; ovdje je reaktivacija dozvoljena bez nje.
contract VerifierNodeRegistry {
    /// @dev Doc-specified lifecycle (docs/18: `pending → active → offline → ejected`),
    ///      plus `None` for never-registered keys. `Ejected` is terminal: a kicked signing key
    ///      can never re-enter (re-register), so a slashed operator cannot recycle the same key.
    enum NodeStatus {
        None,
        Pending,
        Active,
        Offline,
        Ejected
    }

    struct Node {
        address operator; // known human operator (docs/18: "poznat ljudski operater po nodeu")
        bytes32 attestationRef; // hash of the Android Key Attestation evidence (verified off-chain by the DAO)
        uint64 registeredAt;
        uint64 statusChangedAt; // last lifecycle transition (also anchors the unstake delay)
        NodeStatus status;
        uint256 stake; // native xDAI held by this contract for the node
    }

    /// @notice signing key (StrongBox/TEE secp256k1 address) => node record.
    mapping(address signingKey => Node) public nodes;
    uint256 public nodeCount; // total ever registered
    uint256 public activeNodeCount; // nodes currently ACTIVE (the mesh threshold ceiling)

    // --- governance-controlled config (airKUNA DAO Safe) ---
    address public governance;
    address public pendingGovernance; // two-step transfer target (0 = none)
    address public treasury; // slashed stakes land here
    uint256 public minStake; // required at register/activate; 0 = staking off
    uint256 public unstakeDelay; // seconds a node must stay offline before withdrawing stake

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

    error NotGovernance();
    error NotPendingGovernance();
    error NotOperator();
    error NotAuthorized();
    error ZeroAddress();
    error NoAttestation();
    error AlreadyRegistered();
    error UnknownNode();
    error InvalidTransition();
    error StakeTooLow();
    error UnstakeLocked();
    error ZeroAmount();
    error TransferFailed();

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }

    constructor(address governance_, address treasury_, uint256 minStake_, uint256 unstakeDelay_) {
        if (governance_ == address(0) || treasury_ == address(0)) revert ZeroAddress();
        governance = governance_;
        treasury = treasury_;
        minStake = minStake_;
        unstakeDelay = unstakeDelay_;
    }

    // --- operator actions ---

    /// @notice Apply for mesh membership: register a signing key with its hardware-attestation
    ///         reference and (if `minStake` > 0) the xDAI stake. The node starts PENDING; per
    ///         docs/18 admission goes through a DAO vote → `activate` by governance.
    /// @param signingKey     The node's StrongBox/TEE secp256k1 address (what co-signs attestations).
    /// @param attestationRef Hash/reference of the Android Key Attestation evidence. Verified
    ///                       OFF-chain by the DAO before activation — never onchain.
    function register(address signingKey, bytes32 attestationRef) external payable {
        if (signingKey == address(0)) revert ZeroAddress();
        if (attestationRef == bytes32(0)) revert NoAttestation();
        if (nodes[signingKey].status != NodeStatus.None) revert AlreadyRegistered();
        if (msg.value < minStake) revert StakeTooLow();

        nodes[signingKey] = Node({
            operator: msg.sender,
            attestationRef: attestationRef,
            registeredAt: uint64(block.timestamp),
            statusChangedAt: uint64(block.timestamp),
            status: NodeStatus.Pending,
            stake: msg.value
        });
        unchecked {
            nodeCount++;
        }
        emit NodeRegistered(signingKey, msg.sender, attestationRef, msg.value);
    }

    /// @notice Top up a node's stake (e.g. after governance raised `minStake`, or to re-qualify
    ///         an offline node for reactivation after a withdrawal).
    function addStake(address signingKey) external payable {
        Node storage node = nodes[signingKey];
        if (node.status == NodeStatus.None) revert UnknownNode();
        if (node.status == NodeStatus.Ejected) revert InvalidTransition();
        if (msg.sender != node.operator) revert NotOperator();
        if (msg.value == 0) revert ZeroAmount();
        node.stake += msg.value;
        emit StakeAdded(signingKey, msg.value);
    }

    /// @notice Withdraw the full stake of an OFFLINE node, `unstakeDelay` after it went offline.
    ///         The delay keeps a misbehaving node slashable: it cannot self-deactivate and exit
    ///         faster than the DAO can vote `eject`.
    function withdrawStake(address signingKey) external {
        Node storage node = nodes[signingKey];
        if (node.status == NodeStatus.None) revert UnknownNode();
        if (msg.sender != node.operator) revert NotOperator();
        if (node.status != NodeStatus.Offline) revert InvalidTransition();
        if (block.timestamp < node.statusChangedAt + unstakeDelay) revert UnstakeLocked();
        uint256 amount = node.stake;
        if (amount == 0) revert ZeroAmount();
        node.stake = 0;
        emit StakeWithdrawn(signingKey, node.operator, amount);
        _pay(node.operator, amount);
    }

    // --- lifecycle (docs/18: DAO admits & kicks; operator may take its own node offline) ---

    /// @notice DAO admission (`pending → active`) or reactivation (`offline → active`).
    ///         Requires the node's stake to satisfy the CURRENT `minStake`.
    function activate(address signingKey) external onlyGovernance {
        Node storage node = nodes[signingKey];
        if (node.status == NodeStatus.None) revert UnknownNode();
        if (node.status != NodeStatus.Pending && node.status != NodeStatus.Offline) revert InvalidTransition();
        if (node.stake < minStake) revert StakeTooLow();
        node.status = NodeStatus.Active;
        node.statusChangedAt = uint64(block.timestamp);
        unchecked {
            activeNodeCount++;
        }
        emit NodeActivated(signingKey);
    }

    /// @notice `active → offline`. Callable by governance (DAO deactivation per docs/18) or by
    ///         the node's own operator (voluntary downtime — docs are silent, allowed as the
    ///         benign case; the stake stays locked for `unstakeDelay` either way).
    function deactivate(address signingKey) external {
        Node storage node = nodes[signingKey];
        if (node.status == NodeStatus.None) revert UnknownNode();
        if (msg.sender != governance && msg.sender != node.operator) revert NotAuthorized();
        if (node.status != NodeStatus.Active) revert InvalidTransition();
        node.status = NodeStatus.Offline;
        node.statusChangedAt = uint64(block.timestamp);
        activeNodeCount--;
        emit NodeDeactivated(signingKey);
    }

    /// @notice DAO kick (`pending|active|offline → ejected`): terminal, and slashes the node's
    ///         entire stake to the treasury.
    /// @dev Otvorena odluka: puni slash je najjednostavnija poštena aproksimacija — dokumenti
    ///      kažu samo "node koji laže lokaciju gubi stake".
    function eject(address signingKey) external onlyGovernance {
        Node storage node = nodes[signingKey];
        if (node.status == NodeStatus.None) revert UnknownNode();
        if (node.status == NodeStatus.Ejected) revert InvalidTransition();
        if (node.status == NodeStatus.Active) {
            activeNodeCount--;
        }
        uint256 slashed = node.stake;
        node.stake = 0;
        node.status = NodeStatus.Ejected;
        node.statusChangedAt = uint64(block.timestamp);
        emit NodeEjected(signingKey, slashed);
        if (slashed > 0) {
            _pay(treasury, slashed);
        }
    }

    // --- views ---

    /// @notice Live ACTIVE check — MeshVerifier consults this per signature, so ejecting or
    ///         deactivating a node invalidates its signatures immediately (no cached set).
    function isActive(address signingKey) external view returns (bool) {
        return nodes[signingKey].status == NodeStatus.Active;
    }

    function statusOf(address signingKey) external view returns (NodeStatus) {
        return nodes[signingKey].status;
    }

    // --- governance config ---

    function setMinStake(uint256 minStake_) external onlyGovernance {
        minStake = minStake_;
        emit MinStakeChanged(minStake_);
    }

    function setUnstakeDelay(uint256 unstakeDelay_) external onlyGovernance {
        unstakeDelay = unstakeDelay_;
        emit UnstakeDelayChanged(unstakeDelay_);
    }

    function setTreasury(address treasury_) external onlyGovernance {
        if (treasury_ == address(0)) revert ZeroAddress();
        treasury = treasury_;
        emit TreasuryChanged(treasury_);
    }

    /// @notice Two-step governance transfer (the KunaToken lesson: a typo must not brick the mesh).
    function transferGovernance(address newGovernance) external onlyGovernance {
        if (newGovernance == address(0)) revert ZeroAddress();
        pendingGovernance = newGovernance;
        emit GovernanceTransferStarted(newGovernance);
    }

    function acceptGovernance() external {
        if (msg.sender != pendingGovernance) revert NotPendingGovernance();
        governance = msg.sender;
        delete pendingGovernance;
        emit GovernanceTransferred(msg.sender);
    }

    // --- internals ---

    function _pay(address to, uint256 amount) private {
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed();
    }
}
