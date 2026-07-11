// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.24;

import {IIdentityRegistry} from "./interfaces/IIdentityRegistry.sol";
import {IERC677Receiver} from "./interfaces/IERC677Receiver.sol";

/// @title KunaToken — airKUNA e-money token (EMT), "1 KUNA = 1 EUR".
/// @notice MiCA e-money-token model in the Monerium mould: KYC and SEPA rails live OFF-chain at
///         the issuer; on-chain the issuer mints on SEPA deposit and burns on redemption at par.
///         ERC-20 (18 decimals) + EIP-2612 permit (gasless approvals) + ERC-677 transferAndCall
///         (one-tx pay-and-notify — required for PinkaCrowdfund Path A and Monerium-EURe-style
///         integrations).
///
///         Roles (single-address style, consistent with IdentityRegistry — production =
///         Safe multisig + OZ AccessControl):
///         - `governance` — sets issuer / personhood policy / pause. Transfer is TWO-STEP
///           (propose + `acceptGovernance`) so a typo cannot brick the token — the lesson from
///           EIP712Verifier's one-shot `transferAdmin`.
///         - `issuer`     — `mint(to, amount)` on SEPA deposit; `burnFrom(from, amount)` on
///           redemption. Burn is issuer-only (Monerium controller model): redemption starts
///           off-chain as a SEPA payout request, and the issuer executes the burn against the
///           redeemed account — holders never grant allowances to redeem, and the burned amount
///           always equals the fiat actually paid out.
///
///         `pause()` gates transfers and mint but NEVER the redemption burn: under MiCA an EMT
///         holder has a permanent right to redeem at par — freezing circulation must not freeze
///         the exit.
///
///         Personhood policy (optional): when `identityRegistry` is set (zero = off), mint
///         recipients MUST satisfy `isPerson(to)`. KYC lives at the fiat ramp; the on-chain
///         personhood check is an EXTRA issuance policy (one person, one identity). Transfers
///         stay free — only issuance is gated.
/// @dev    Reference only — unaudited. In production use OZ ERC20 + ERC20Permit + Pausable +
///         AccessControl, an audited issuer contract behind the fiat bridge, and timelocks.
contract KunaToken {
    string public constant name = "airKUNA";
    string public constant symbol = "KUNA";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    mapping(address owner => uint256) public balanceOf;
    mapping(address owner => mapping(address spender => uint256)) public allowance;

    // --- EIP-2612 ---

    bytes32 private constant _EIP712_DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /// @dev secp256k1 group order / 2 — EIP-2 low-s bound (same hardening as EIP712Verifier).
    uint256 private constant _SECP256K1N_HALF = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /// @dev Cached at deploy — fine for a single-chain (Gnosis, chainId 100) reference token.
    ///      A production token should rebuild the separator if block.chainid changes (fork replay).
    bytes32 public immutable DOMAIN_SEPARATOR;
    mapping(address owner => uint256) public nonces;

    // --- roles & policy ---

    address public governance; // airKUNA DAO Safe multisig (production)
    address public pendingGovernance; // two-step transfer target (0 = none)
    address public issuer; // fiat bridge: mints on SEPA deposit, burns on redemption
    IIdentityRegistry public identityRegistry; // personhood issuance policy (0 = off)
    bool public paused;

    // --- events ---

    event Transfer(address indexed from, address indexed to, uint256 value);
    /// @dev ERC-677 overload of Transfer, carrying the callback payload (LINK-compatible).
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Minted(address indexed to, uint256 amount);
    event Redeemed(address indexed from, uint256 amount);
    event IssuerChanged(address indexed issuer);
    event IdentityRegistryChanged(address indexed identityRegistry);
    event Paused();
    event Unpaused();
    event GovernanceTransferStarted(address indexed pendingGovernance);
    event GovernanceTransferred(address indexed newGovernance);

    // --- errors ---

    error NotGovernance();
    error NotPendingGovernance();
    error NotIssuer();
    error NotPerson();
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();
    error EnforcedPause();
    error ExpectedPause();
    error PermitExpired();
    error BadSignature();

    modifier onlyGovernance() {
        if (msg.sender != governance) revert NotGovernance();
        _;
    }

    modifier onlyIssuer() {
        if (msg.sender != issuer) revert NotIssuer();
        _;
    }

    constructor(address governance_, address issuer_, address identityRegistry_) {
        if (governance_ == address(0) || issuer_ == address(0)) revert ZeroAddress();
        governance = governance_;
        issuer = issuer_;
        identityRegistry = IIdentityRegistry(identityRegistry_);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), block.chainid, address(this)
            )
        );
        emit IssuerChanged(issuer_);
        emit IdentityRegistryChanged(identityRegistry_);
    }

    // --- ERC-20 ---

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed < amount) revert InsufficientAllowance();
            unchecked { allowance[from][msg.sender] = allowed - amount; }
        }
        _transfer(from, to, amount);
        return true;
    }

    // --- ERC-677 ---

    /// @notice Transfer `amount` to `to` and, if `to` is a contract, notify it via
    ///         `onTokenTransfer(msg.sender, amount, data)` in the same transaction.
    ///         A reverting receiver reverts the whole transfer (no stuck tokens).
    function transferAndCall(address to, uint256 amount, bytes calldata data) external returns (bool) {
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount, data);
        if (to.code.length > 0) {
            IERC677Receiver(to).onTokenTransfer(msg.sender, amount, data);
        }
        return true;
    }

    // --- EIP-2612 ---

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        if (block.timestamp > deadline) revert PermitExpired();
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
        if (uint256(s) > _SECP256K1N_HALF) revert BadSignature(); // EIP-2 low-s only
        address recovered = ecrecover(digest, v, r, s);
        if (recovered == address(0) || recovered != owner) revert BadSignature();
        _approve(owner, spender, value);
    }

    // --- issuer: mint on SEPA deposit / burn on redemption (Monerium controller model) ---

    /// @notice Issue KUNA 1:1 against a received SEPA EUR deposit.
    ///         When the personhood policy is on, the recipient must be a verified person.
    function mint(address to, uint256 amount) external onlyIssuer {
        if (paused) revert EnforcedPause();
        if (to == address(0)) revert ZeroAddress();
        if (address(identityRegistry) != address(0) && !identityRegistry.isPerson(to)) revert NotPerson();
        totalSupply += amount;
        unchecked { balanceOf[to] += amount; }
        emit Transfer(address(0), to, amount);
        emit Minted(to, amount);
    }

    /// @notice Burn KUNA on redemption (SEPA payout at par). Deliberately NOT pausable:
    ///         redemption at par is a MiCA right — pausing circulation must not block the exit.
    function burnFrom(address from, uint256 amount) external onlyIssuer {
        uint256 bal = balanceOf[from];
        if (bal < amount) revert InsufficientBalance();
        unchecked { balanceOf[from] = bal - amount; totalSupply -= amount; }
        emit Transfer(from, address(0), amount);
        emit Redeemed(from, amount);
    }

    // --- governance (airKUNA DAO Safe) ---

    function setIssuer(address issuer_) external onlyGovernance {
        if (issuer_ == address(0)) revert ZeroAddress();
        issuer = issuer_;
        emit IssuerChanged(issuer_);
    }

    /// @notice Set (or clear with zero) the personhood issuance policy.
    function setIdentityRegistry(address identityRegistry_) external onlyGovernance {
        identityRegistry = IIdentityRegistry(identityRegistry_);
        emit IdentityRegistryChanged(identityRegistry_);
    }

    function pause() external onlyGovernance {
        if (paused) revert EnforcedPause();
        paused = true;
        emit Paused();
    }

    function unpause() external onlyGovernance {
        if (!paused) revert ExpectedPause();
        paused = false;
        emit Unpaused();
    }

    /// @notice Two-step governance transfer: propose here, new governance calls acceptGovernance().
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

    function _transfer(address from, address to, uint256 amount) private {
        if (paused) revert EnforcedPause();
        if (to == address(0)) revert ZeroAddress();
        uint256 bal = balanceOf[from];
        if (bal < amount) revert InsufficientBalance();
        unchecked { balanceOf[from] = bal - amount; balanceOf[to] += amount; }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
