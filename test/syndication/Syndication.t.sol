pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/Treasury.sol";
import "contracts/syndication/Syndication.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";

contract SyndicationTest is Test {
    Syndication syndication;

    function setUp() public {
        address treasury = Upgrades.deployUUPSProxy(
            "Treasury.sol",
            abi.encodeCall(Syndication.initialize, ())
        );

        syndication = = Upgrades.deployUUPSProxy(
            "Syndication.sol",
            abi.encodeCall(Syndication.initialize, (treasury))
        );
    }
}
