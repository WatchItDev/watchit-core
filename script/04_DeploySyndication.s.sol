// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { Syndication } from "contracts/syndication/Syndication.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { DeployTreasury } from "script/01_DeployTreasury.s.sol";
import { DeployBase } from "script/00_DeployBase.s.sol";

contract DeploySyndication is DeployBase {
    address treasury;

    function setTreasuryAddress(address treasury_) external {
        treasury = treasury_;
    }

    function run() external BroadcastedByAdmin returns (address) {
        // Deploy the upgradeable contract
        address _proxyAddress = Upgrades.deployUUPSProxy(
            "Syndication.sol",
            abi.encodeCall(Syndication.initialize, (treasury))
        );

        return _proxyAddress;
    }
}
