// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/token/ERC20/IERC20.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/extensions/ERC20Burnable.sol";

contract TreasuryAndReserve is Ownable {
    // Token contracts for minting and burning
    IERC20 public BLTBYToken;
    IERC20 public USDC;
    IERC20 public USDT;
    IERC20 public PYUSD;

    // Events for minting, burning, and buybacks
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event BuybackExecuted(address indexed from, uint256 amount);

    constructor(
        address initialOwner,
        address _BLTBYToken,
        address _USDC,
        address _USDT,
        address _PYUSD
    ) Ownable(initialOwner) {
        BLTBYToken = IERC20(_BLTBYToken);
        USDC = IERC20(_USDC);
        USDT = IERC20(_USDT);
        PYUSD = IERC20(_PYUSD);
    }

    /**
     * @dev Mint BLTBY tokens to a specific address.
     * Can be called by other contracts with mint permissions.
     * @param to The address that will receive the minted tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintBLTBY(address to, uint256 amount) external onlyOwner {
        IERC20(address(BLTBYToken)).transfer(to, amount);
        emit Minted(to, amount);
    }

    /**
     * @dev Burn BLTBY tokens from a specific address.
     * Can be executed by administrators to control supply.
     * @param from The address whose tokens will be burned.
     * @param amount The amount of tokens to burn.
     */
    function burnBLTBY(address from, uint256 amount) external onlyOwner {
        ERC20Burnable(address(BLTBYToken)).burnFrom(from, amount);
        emit Burned(from, amount);
    }

    /**
     * @dev Perform a manual buyback of BLTBY tokens using USDC, USDT, or PYUSD.
     * @param token The address of the stablecoin being used for buyback (USDC, USDT, PYUSD).
     * @param amount The amount of stablecoin to use for the buyback.
     */
    function executeBuyback(address token, uint256 amount) external onlyOwner {
        require(
            token == address(USDC) ||
                token == address(USDT) ||
                token == address(PYUSD),
            "Invalid stablecoin address"
        );
        require(
            IERC20(token).balanceOf(msg.sender) >= amount,
            "Insufficient stablecoin balance"
        );
        require(
            IERC20(token).transferFrom(msg.sender, address(this), amount),
            "Buyback transfer failed"
        );
        emit BuybackExecuted(msg.sender, amount);
    }

    /**
     * @dev Allows DAO governance to eventually take over admin roles.
     * Transfers ownership to the DAO's governance address.
     * @param newAdmin The address of the new DAO governance admin.
     */
    function transferToDAO(address newAdmin) external onlyOwner {
        transferOwnership(newAdmin);
    }

    /**
     * @dev Fallback function to receive stablecoins.
     */
    receive() external payable {}
}

/*
 Key Features:
 - Manual minting and burning of BLTBY tokens, with no cap on minting.
 - Integration with stablecoins (USDC, USDT, PYUSD) for buybacks, managed manually by administrators.
 - Initially admin-controlled, with a mechanism to transition to DAO governance in the future.
 - Other contracts can call minting functions, subject to permissions.
*/
