// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";

contract DeployBase is Script {
    modifier BroadcastedByAdmin() {
        address admin = vm.envAddress("ADMIN");
        vm.startBroadcast(admin);
        _;
        vm.stopBroadcast();
    }
}
