pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import { DeployToken } from "scripts/02_DeployToken.s.sol";
import { DeployTreasury } from "scripts/01_DeployTreasury.s.sol";
import { DeploySyndication } from "scripts/04_DeploySyndication.s.sol";

contract BaseTest is Test {
    address admin = vm.envAddress("ADMIN");

    function deploySyndication(address treasury) public returns (address) {
        // set default admin as deployer..
        DeploySyndication synDeployer = new DeploySyndication();
        synDeployer.setTreasuryAddress(treasury);
        return synDeployer.run();
    }

    function deployToken() public returns (address) {
        // set default admin as deployer..
        DeployToken mmcDeployer = new DeployToken();
        return mmcDeployer.run();
    }

    function deployTreasury() public returns (address) {
        // set default admin as deployer..
        DeployTreasury treasuryDeployer = new DeployTreasury();
        return treasuryDeployer.run();
    }
}
