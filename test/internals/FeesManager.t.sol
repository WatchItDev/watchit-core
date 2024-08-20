pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/base/upgradeable/FeesManagerUpgradeable.sol";

contract FeesManagerTest is Test, FeesManagerUpgradeable {
    function setFees(uint256 fee) public {}

    function setFees(
        uint256 fee,
        address token
    ) public onlySupportedCurrency(token) {}

    function test_SetFeesERC20() public {
        uint256 expected = 1e18;
        address token = vm.addr(1); // example address

        _setFees(expected, token);
        assertEq(getFees(token), expected);
    }

    function test_SetFeesNative() public {
        uint256 expected = 1e18;
        _setFees(expected, address(0));
        assertEq(getFees(address(0)), expected);
    }

    function test_RevertWhen_NotSupportedCurrency() public {
        vm.expectRevert(
            abi.encodeWithSignature(
                "InvalidUnsupportedCurrency(address)",
                address(0)
            )
        );
        getFees(address(0));
    }
}
