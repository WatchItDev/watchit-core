// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { DeployBase } from "scripts/00_DeployBase.s.sol";
import { Treasury } from "contracts/economics/Treasury.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

contract DeployTreasury is DeployBase {
    function run() external BroadcastedByAdmin returns (address) {
        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployUUPSProxy("Treasury.sol", abi.encodeCall(Treasury.initialize, ()));
        return _proxyAddress;
    }
}
