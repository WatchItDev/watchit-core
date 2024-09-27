// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {Syndication} from "contracts/syndication/Syndication.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DeployTreasury} from "scripts/01_DeployTreasury.sol";

contract DeploySyndication is Script {
    function run() external returns (address, address) {
        vm.startBroadcast();
        DeployTreasury treasuryDeployer = new DeployTreasury();
        address treasury = treasury.run()

        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployUUPSProxy(
            "Syndication.sol",
            abi.encodeCall(Syndication.initialize, (treasury))
        );

        vm.stopBroadcast();
        return _proxyAddress;
    }
}
