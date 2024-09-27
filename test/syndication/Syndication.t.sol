pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {Syndication} from "contracts/syndication/Syndication.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {DeploySyndication} from "scripts/03_DeploySyndication.s.sol";

contract SyndicationTest is Test {
    Syndication syndication;

    function setUp() public {
        DeploySyndication synDeployer = new DeploySyndication();
        syndication =  synDeployer.run();
    }

    function test_init_ValidInitialTreasuryAddress() public {
        address treasury = syndication.getTreasuryAddress();
        assertNotEq(treasury, address(0));
    }
}
