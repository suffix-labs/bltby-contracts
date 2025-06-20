// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Custom proxy that accepts admin address directly 
contract CustomTransparentProxy is ERC1967Proxy {
    address private immutable _admin;
    
    constructor(address implementation, address admin, bytes memory data) 
        payable ERC1967Proxy(implementation, data) 
    {
        _admin = admin;
        ERC1967Utils.changeAdmin(admin);
    }
    
    function _fallback() internal virtual override {
        if (msg.sender == _admin) {
            if (msg.sig == ITransparentUpgradeableProxy.upgradeToAndCall.selector) {
                _dispatchUpgradeToAndCall();
            } else {
                revert("Admin cannot fallback");
            }
        } else {
            super._fallback();
        }
    }
    
    function _dispatchUpgradeToAndCall() internal {
        (address newImplementation, bytes memory data) = abi.decode(msg.data[4:], (address, bytes));
        ERC1967Utils.upgradeToAndCall(newImplementation, data);
    }
}

contract MigrationAndUpgradeProxy is Ownable {
    // Proxy contract address storage
    mapping(string => address) public proxies;
    mapping(string => address) public proxyAdmins;

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Deploy a new proxy contract for a given logic contract.
     * @param logicContract The address of the logic contract to point to.
     * @param data Any initialization data.
     */
    function deployProxy(
        address logicContract,
        bytes memory data,
        string memory contractName
    ) external onlyOwner {
        // Create ProxyAdmin first with this contract as owner
        ProxyAdmin proxyAdmin = new ProxyAdmin(address(this));
        
        // Create custom proxy that sets the admin correctly
        CustomTransparentProxy proxy = new CustomTransparentProxy(
            logicContract,
            address(proxyAdmin),
            data
        );
        
        proxies[contractName] = address(proxy);
        proxyAdmins[contractName] = address(proxyAdmin);
    }

    /**
     * @dev Get the proxy contract address for a specific contract.
     * @param contractName The name of the deployed contract.
     * @return Address of the proxy contract.
     */
    function getProxyAddress(
        string memory contractName
    ) external view returns (address) {
        return proxies[contractName];
    }


    /**
     * @dev Get the proxy admin address for a specific contract.
     * @param contractName The name of the deployed contract.
     * @return Address of the proxy admin contract.
     */
    function getProxyAdmin(
        string memory contractName
    ) external view returns (address) {
        return proxyAdmins[contractName];
    }

    /**
     * @dev Upgrade a proxy to a new implementation.
     * @param contractName The name of the contract to upgrade.
     * @param newImplementation The address of the new implementation.
     */
    function upgradeProxy(
        string memory contractName,
        address newImplementation
    ) external onlyOwner {
        address proxyAddress = proxies[contractName];
        address adminAddress = proxyAdmins[contractName];
        
        require(proxyAddress != address(0), "Proxy not found");
        require(adminAddress != address(0), "ProxyAdmin not found");
        
        ProxyAdmin admin = ProxyAdmin(adminAddress);
        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            newImplementation,
            ""
        );
    }

    /**
     * @dev Upgrade a proxy to a new implementation with initialization data.
     * @param contractName The name of the contract to upgrade.
     * @param newImplementation The address of the new implementation.
     * @param data Initialization data for the new implementation.
     */
    function upgradeProxyAndCall(
        string memory contractName,
        address newImplementation,
        bytes memory data
    ) external onlyOwner {
        address proxyAddress = proxies[contractName];
        address adminAddress = proxyAdmins[contractName];
        
        require(proxyAddress != address(0), "Proxy not found");
        require(adminAddress != address(0), "ProxyAdmin not found");
        
        ProxyAdmin admin = ProxyAdmin(adminAddress);
        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            newImplementation,
            data
        );
    }
}
