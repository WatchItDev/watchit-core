// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "contracts/syndication/Syndication.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployTreasury is Script {
    function run() external returns (address) {
        // we need to declare the sender's private key here to sign the deploy transaction
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployUUPSProxy(
            "Treasury.sol",
            abi.encodeCall(Syndication.initialize, (msg.sender))
        );

        vm.stopBroadcast();
        return _proxyAddress;
    }
}
