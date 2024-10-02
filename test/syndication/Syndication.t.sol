pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import { ITreasurer } from "contracts/interfaces/ITreasurer.sol";
import { IGovernable } from "contracts/interfaces/IGovernable.sol";
import { IFeesManager } from "contracts/interfaces/IFeesManager.sol";
import { ISyndicatablePenalizer } from "contracts/interfaces/ISyndicatablePenalizer.sol";

import { BaseTest } from "test/BaseTest.t.sol";

contract SyndicationTest is BaseTest {
    address syndication;
    address treasury;
    address token;

    function setUp() public {
        token = deployToken();
        treasury = deployTreasury();
        syndication = deploySyndication(treasury);
    }

    function _setGovernor(address account) internal {
        vm.prank(admin);
        IGovernable(syndication).setGovernance(account);
        vm.prank(account);
    }

    function test_Init_TreasuryAddress() public {
        // test initialized treasury address
        address treasuryAddress = ITreasurer(syndication).getTreasuryAddress();
        assertNotEq(treasuryAddress, address(0));
    }

    function test_Set_PenaltyRate() public {
        // admins sets governor address
        _setGovernor(vm.addr(1));

        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(1500, token); // MMC 15% nominal = 1500 bps
        assertEq(pen.getPenaltyRate(token), 1500);
    }

    function test_RevertWhen_UnauthorizedSetPenaltyRate() public {
        vm.expectRevert();
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(1500, token); // MMC 15% nominal = 1500 bps
    }

    function test_RevertIf_InvalidBPSPenaltyRate() public {
        uint256 invalidFee = 10_001; // MMC 101% nominal = 10001 bps;
        // admins sets governor address
        _setGovernor(vm.addr(1));

        vm.expectRevert(abi.encodeWithSignature("InvalidBasisPointRange(uint256)", invalidFee));
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(invalidFee, token);
    }

    function test_SetTreasuryFees() public {
        uint256 expectedFees = 100 * 1e18;
        // only governor can set fees
        _setGovernor(vm.addr(1));

        IFeesManager(syndication).setFees(expectedFees, token);
        assertEq(IFeesManager(syndication).getFees(token), expectedFees);
    }

    function test_RevertWhen_UnauthorizedSetTreasuryFees() public {
        vm.expectRevert();
        uint256 expectedFees = 100 * 1e18;
        IFeesManager(syndication).setFees(expectedFees, token);
    }

    function test_RevertIf_UnsupportedCurrencyFees() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidUnsupportedCurrency(address)", token));
        // if fees for token are not set, must fail..
        IFeesManager(syndication).getFees(token);
    }

    function test_SetTreasuryAddress() public {
        // only governor can set treasury address
        _setGovernor(vm.addr(1));
        // test initialized treasury address
        address expectedTreasury = vm.addr(2);
        ITreasurer(syndication).setTreasuryAddress(expectedTreasury);
        assertEq(ITreasurer(syndication).getTreasuryAddress(), expectedTreasury);
    }

    function test_RevertWhen_UnauthorizedSetTreasuryAddress() public {
        vm.expectRevert();
        // if fees for token are not set, must fail..
        address expectedTreasury = vm.addr(2);
        ITreasurer(syndication).setTreasuryAddress(expectedTreasury);
    }
}
