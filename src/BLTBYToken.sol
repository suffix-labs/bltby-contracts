// BLTBY Token Contract : Built By DAO V 0.01.0
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC20/ERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/utils/Pausable.sol";
import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/utils/ReentrancyGuard.sol";

contract BLTBYToken is
    ERC20,
    Ownable,
    AccessControl,
    Pausable,
    ReentrancyGuard
{
    uint256 public immutable MAX_SUPPLY = 2_500_000_000 * 10 ** 18; // Total fixed supply of 2.5 billion tokens
    uint256 public constant MINT_CAP_PERCENTAGE = 5; // Up to 5% yearly inflation cap
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18; // Initial circulation supply of 100 million tokens
    uint256 public lastMintTimestamp;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MULTISIG_ROLE = keccak256("MULTISIG_ROLE");

    // Event declarations
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    // Custom errors for gas efficiency
    error UnauthorizedAccess();
    error MintingTooSoon();
    error MintExceedsCap(uint256 requested, uint256 allowed);
    error InsufficientRole(string role);
    error BurnFailed(address from, uint256 amount);

    constructor(
        address initialOwner
    ) ERC20("BLTBY Token Contract", "BLTBY") Ownable(initialOwner) {
        _mint(msg.sender, INITIAL_SUPPLY); // Initial mint to deployer
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(MINTER_ROLE, msg.sender);
        grantRole(MULTISIG_ROLE, msg.sender);
        lastMintTimestamp = block.timestamp;
    }

    /**
     * @dev Mint tokens, restricted to MINTER_ROLE with additional constraints.
     * Requires multi-signature approval via MULTISIG_ROLE.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mint(
        address to,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) nonReentrant whenNotPaused {
        if (block.timestamp < lastMintTimestamp + 365 days) {
            revert MintingTooSoon();
        }
        if (totalSupply() + amount > MAX_SUPPLY) {
            revert MintExceedsCap(amount, MAX_SUPPLY - totalSupply());
        }
        if (amount > (MAX_SUPPLY * MINT_CAP_PERCENTAGE) / 100) {
            revert MintExceedsCap(
                amount,
                (MAX_SUPPLY * MINT_CAP_PERCENTAGE) / 100
            );
        }
        if (!hasRole(MULTISIG_ROLE, msg.sender)) {
            revert InsufficientRole("MULTISIG_ROLE");
        }

        _mint(to, amount);
        lastMintTimestamp = block.timestamp;
        emit Minted(to, amount);
    }

    /**
     * @dev Burn tokens, restricted to admin-controlled operations to stabilize value.
     * @param from The address from which tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burn(
        address from,
        uint256 amount
    ) external onlyOwner nonReentrant whenNotPaused {
        if (balanceOf(from) < amount) {
            revert BurnFailed(from, amount);
        }
        _burn(from, amount);
        emit Burned(from, amount);
    }

    /**
     * @dev Pause all token transfers in case of emergency.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause token transfers.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Transfer function with added checks for internal redemption mechanism.
     * @param recipient Address of the recipient.
     * @param amount Amount to be transferred.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

    /**
     * @dev Override transferFrom to ensure pausable functionality.
     * @param sender The address sending tokens.
     * @param recipient The address receiving tokens.
     * @param amount The amount of tokens to be transferred.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whenNotPaused returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }

    /**
     * @dev Redeem tokens at an internal redemption rate for services in the DAO.
     * This function would interact with other contracts managing the DAO's service provision.
     * @param amount The amount of tokens to redeem.
     */
    function redeem(uint256 amount) external nonReentrant whenNotPaused {
        if (balanceOf(msg.sender) < amount) {
            revert BurnFailed(msg.sender, amount);
        }
        _burn(msg.sender, amount);
        emit Burned(msg.sender, amount);
        // Further actions such as interacting with service contracts could be added here
    }
}
