pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/syndication/Syndication.sol";

contract SyndicationTest is Test {

    Syndication  syndication;

    function setUp() public {
        syndication = new Syndication();
    }
    
}
