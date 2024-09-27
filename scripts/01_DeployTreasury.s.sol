// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployTreasury is Script {
    function run() external returns (address) {
        vm.startBroadcast();

        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployUUPSProxy(
            "Treasury.sol",
            abi.encodeCall(Syndication.initialize, (msg.sender))
        );

        vm.stopBroadcast();
        return _proxyAddress;
    }
}
