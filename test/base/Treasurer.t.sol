pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {TreasurerUpgradeable} from "contracts/base/upgradeable/TreasurerUpgradeable.sol";

contract TreasurerTest is Test, TreasurerUpgradeable {
    function setTreasuryAddress(address newTreasuryAddress) public {
        _setTreasuryAddress(newTreasuryAddress);
    }

    function test_SetTreasuryAddress() public {
        address treasuryAddress = vm.addr(1); // example address
        setTreasuryAddress(treasuryAddress);
        assertEq(getTreasuryAddress(), treasuryAddress);
    }
}
