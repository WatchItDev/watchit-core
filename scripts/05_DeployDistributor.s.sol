// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { DeployBase } from "scripts/00_DeployBase.s.sol";
import { Distributor } from "contracts/syndication/Distributor.sol";
import { DistributorFactory } from "contracts/syndication/DistributorFactory.sol";

contract DeployDistributor is DeployBase {
    string endpoint;

    function setEndpoint(string memory endpoint_) external {
        endpoint = endpoint_;
    }

    function run() external BroadcastedByAdmin returns (address) {
        Distributor imp = new Distributor(); //implementation
        // factory implementing an upgradeable beacon that produces beacon proxies..
        DistributorFactory beacon = new DistributorFactory(address(imp));
        return beacon.create(endpoint);
    }
}
