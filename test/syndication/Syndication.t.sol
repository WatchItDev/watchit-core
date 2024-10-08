pragma solidity 0.8.26;

import "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { ILedger } from "contracts/interfaces/ILedger.sol";
import { IDisburser } from "contracts/interfaces/IDisburser.sol";
import { ITreasurer } from "contracts/interfaces/ITreasurer.sol";
import { IGovernable } from "contracts/interfaces/IGovernable.sol";
import { IFeesManager } from "contracts/interfaces/IFeesManager.sol";
import { ISyndicatableEnroller } from "contracts/interfaces/ISyndicatableEnroller.sol";
import { ISyndicatableExpirable } from "contracts/interfaces/ISyndicatableExpirable.sol";
import { ISyndicatablePenalizer } from "contracts/interfaces/ISyndicatablePenalizer.sol";
import { ISyndicatableVerifiable } from "contracts/interfaces/ISyndicatableVerifiable.sol";
import { ISyndicatableRegistrable } from "contracts/interfaces/ISyndicatableRegistrable.sol";
import { ISyndicatableRevokable } from "contracts/interfaces/ISyndicatableRevokable.sol";

import { BaseTest } from "test/BaseTest.t.sol";
import { Syndication } from "contracts/syndication/Syndication.sol";
import { FeesHelper } from "contracts/libraries/FeesHelper.sol";

contract SyndicationTest is BaseTest {
    using FeesHelper for uint256;

    address distributor;
    address syndication;
    address treasury;
    address token;
    address governor;

    function setUp() public {
        token = deployToken();
        treasury = deployTreasury();
        syndication = deploySyndication(treasury);
        distributor = deployDistributor("contentrider.com");
        governor = vm.addr(1);
    }

    function _setGovernor(address account) internal {
        vm.prank(admin);
        IGovernable(syndication).setGovernance(account);
        vm.prank(account);
    }

    function _setFeesAsGovernor(uint256 fees) internal {
        _setGovernor(governor);
        IFeesManager(syndication).setFees(fees, token);
    }

    function _registerDistributorWithApproval(uint256 approval) internal {
        // manager = contract deployer
        // only manager can pay enrollment..
        vm.prank(admin);
        IERC20(token).approve(syndication, approval);
        ISyndicatableRegistrable enroller = ISyndicatableRegistrable(syndication);
        enroller.register(distributor, token);
    }

    function _registerDistributorWithGovernorAndApproval() internal {
        uint256 expectedFees = 100 * 1e18; 
        _setFeesAsGovernor(expectedFees);
        _registerDistributorWithApproval(expectedFees);
    }

    function _registerAndApproveDistributor() internal {
        // intially the balance = 0
        _setFeesAsGovernor(0);
        // register the distributor with fees = 100 MMC
        _registerDistributorWithApproval(0);
        vm.prank(governor); // as governor.
        // distribuitor approved only by governor..
        ISyndicatableRegistrable(syndication).approve(distributor);
    }

    /// ----------------------------------------------------------------

    function test_Init_TreasuryAddress() public view {
        // test initialized treasury address
        address treasuryAddress = ITreasurer(syndication).getTreasuryAddress();
        assertNotEq(treasuryAddress, address(0));
    }

    function test_SetPenaltyRate_ValidPenaltyRate() public {
        // admins sets governor address
        _setGovernor(governor);
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(1500, token); // MMC 15% nominal = 1500 bps
        assertEq(pen.getPenaltyRate(token), 1500);
    }

    function test_SetPenaltyRate_RevertWhen_Unauthorized() public {
        vm.expectRevert();
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(1500, token); // MMC 15% nominal = 1500 bps
    }

    function test_SetPenaltyRate_RevertIf_InvalidBPS() public {
        uint256 invalidFee = 10_001; // MMC 101% nominal = 10001 bps;
        // admins sets governor address
        _setGovernor(vm.addr(1));

        vm.expectRevert(abi.encodeWithSignature("InvalidBasisPointRange(uint256)", invalidFee));
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(invalidFee, token);
    }

    function test_SetFees_ValidFees() public {
        uint256 expectedFees = 100 * 1e18;
        // only governor can set fees
        _setFeesAsGovernor(expectedFees);
        uint256 gotFees = IFeesManager(syndication).getFees(token);
        assertEq(gotFees, expectedFees);
    }

    function test_SetFees_RevertWhen_Unauthorized() public {
        vm.expectRevert();
        uint256 expectedFees = 100 * 1e18;
        IFeesManager(syndication).setFees(expectedFees, token);
    }

    function test_GetFees_RevertIf_UnsupportedCurrency() public {
        vm.expectRevert(abi.encodeWithSignature("InvalidUnsupportedCurrency(address)", token));
        // if fees for token are not set, must fail..
        IFeesManager(syndication).getFees(token);
    }

    function test_SetTreasuryAddress_ValidAddress() public {
        // only governor can set treasury address
        _setGovernor(governor);
        // test initialized treasury address
        address expectedTreasury = vm.addr(2);
        ITreasurer(syndication).setTreasuryAddress(expectedTreasury);
        assertEq(ITreasurer(syndication).getTreasuryAddress(), expectedTreasury);
    }

    function test_SetTreasuryAddress_RevertWhen_Unauthorized() public {
        vm.expectRevert();
        // if fees for token are not set, must fail..
        ITreasurer(syndication).setTreasuryAddress(vm.addr(2));
    }

    function test_SetExpirationPeriod_ValidExpiration() public {
        uint256 expireIn = 3600; // seconds
        _setGovernor(governor); // only gov can update expiration period..
        ISyndicatableExpirable(syndication).setExpirationPeriod(expireIn);
        assertEq(ISyndicatableExpirable(syndication).getExpirationPeriod(), expireIn);
    }

    function test_SetExpirationPeriod_RevertWhen_Unauthorized() public {
        vm.expectRevert();
        ISyndicatableExpirable(syndication).setExpirationPeriod(10);
    }

    function test_Disburse_ValidDisbursement() public {
        uint256 expectedFees = 100 * 1e18; // 100 MMC
        // 1-set enrollment fees.
        _setFeesAsGovernor(expectedFees);
        // 2-deploy and register contract
        _registerDistributorWithApproval(expectedFees);

        // 3-after disburse funds to treasury a valid event should be emitted
        vm.prank(governor);
        vm.expectEmit(true, true, false, true, address(syndication));
        emit Syndication.FeesDisbursed(treasury, expectedFees, token);

        IDisburser disburser = IDisburser(syndication);
        disburser.disburse(expectedFees, token);
        // zero after disburse all the balance
        assertEq(IERC20(token).balanceOf(syndication), 0);
    }

    function test_Register_RegisteredEventEmitted() public {
        _setFeesAsGovernor(0); // free enrollment: test purpose
        // after register a distributor a Registered event is expected
        vm.expectEmit(true, true, false, false, address(syndication));
        emit Syndication.Registered(distributor);
        // register the distributor...
        ISyndicatableRegistrable enroller = ISyndicatableRegistrable(syndication);
        enroller.register(distributor, token);
    }

    function test_Register_RevertIf_InvalidAllowance() public {
        uint256 expectedFees = 100 * 1e18; // 100 MMC
        _setFeesAsGovernor(expectedFees);
        // expected revert if not valid allowance
        vm.expectRevert(abi.encodeWithSignature("FailDuringTransfer(string)", "Invalid allowance."));
        ISyndicatableRegistrable enroller = ISyndicatableRegistrable(syndication);
        enroller.register(distributor, token);
    }

    function test_Register_SetValidEnrollmentTime() public {
        uint256 expectedFees = 100 * 1e18; // 100 MMC
        _setFeesAsGovernor(expectedFees);
        _registerDistributorWithApproval(expectedFees);
        // in the next step the distributor is registered and the
        // manager paid for enrollment. Lets ensure that fees are registered in ledger..
        // admin plays as manager here..
        assertEq(ILedger(syndication).getLedgerBalance(admin, token), expectedFees);
    }

    function test_Register_RegisterValidEnrollmentFees() public {
        _setFeesAsGovernor(0);

        ISyndicatableExpirable expirable = ISyndicatableExpirable(syndication);
        uint256 expectedExpiration = expirable.getExpirationPeriod();
        uint256 currentTime = 1727976358;
        vm.warp(currentTime); // set block.time to current time

        // now syndications takes the role of enroller
        ISyndicatableEnroller enroller = ISyndicatableEnroller(syndication);
        // register the distributor expecting the right enrollment time..
        _registerDistributorWithApproval(0);
        assertEq(enroller.getEnrollmentTime(distributor), currentTime + expectedExpiration);
    }

    function test_Register_SetWaitingState() public {
        _setFeesAsGovernor(0);
        // now syndications takes the role of enroller
        ISyndicatableVerifiable verifier = ISyndicatableVerifiable(syndication);
        // register the distributor expecting the right status.
        _registerDistributorWithApproval(0);
        assertEq(verifier.isWaiting(distributor), true);
    }

    function test_Register_RevertIf_InvalidDistributor() public {
        // register the distributor expecting the right status.
        vm.expectRevert(abi.encodeWithSignature("InvalidDistributorContract(address)", address(0)));
        ISyndicatableRegistrable enroller = ISyndicatableRegistrable(syndication);
        enroller.register(address(0), token);
    }

    function test_Quit_ResignedEventEmitted() public {
        // 1- register the distributor is needed before quit..
        _registerDistributorWithGovernorAndApproval();

        // after register a distributor a Registered event is expected
        vm.expectEmit(true, true, false, false, address(syndication));
        emit Syndication.Resigned(distributor);

        // distribuitor quits..
        ISyndicatableRevokable revoker = ISyndicatableRevokable(syndication);
        revoker.quit(distributor, token);
    }

    function test_Quit_RetainValidPenaltyAmount() public {
        // intially the balance = 0
        uint256 expectedFees = 100 * 1e18; // 100 MMC
        uint256 managerPrevBalance = IERC20(token).balanceOf(admin);
        _setFeesAsGovernor(expectedFees);
        // register the distributor with fees = 100 MMC
        _registerDistributorWithApproval(expectedFees);

        // set expected penalization rate..
        vm.prank(governor);
        ISyndicatablePenalizer pen = ISyndicatablePenalizer(syndication);
        pen.setPenaltyRate(1500, token); // MMC 15% nominal = 1500 bps

        uint256 currentPenalization = pen.getPenaltyRate(token);
        uint256 penal = expectedFees.perOf(currentPenalization);

        // admin = manager..
        vm.prank(admin); // registrator should be the same quitting..
        ISyndicatableRevokable revoker = ISyndicatableRevokable(syndication);
        revoker.quit(distributor, token);

        // quit must retain penal after return fees - penal rate;
        assertEq(IERC20(token).balanceOf(syndication), penal);
        assertEq(IERC20(token).balanceOf(admin), managerPrevBalance - penal);
    }

    function test_Quit_RevertWhen_InvalidEnrollment() public {
        // the currency support is checked..
        _setFeesAsGovernor(0);
        // expected revert if not enrollment or waiting approval..
        vm.expectRevert(abi.encodeWithSignature("NotWaitingApproval()"));
        ISyndicatableRevokable revoker = ISyndicatableRevokable(syndication);
        revoker.quit(distributor, token);
    }

    function test_Quit_RevertIf_InvalidDistributor() public {
        _setFeesAsGovernor(0);
        // register the distributor with fees = 100 MMC
        _registerDistributorWithApproval(0);

        // try to quit with invalid distributor..
        vm.expectRevert(abi.encodeWithSignature("InvalidDistributorContract(address)", address(0)));
        ISyndicatableRevokable revoker = ISyndicatableRevokable(syndication);
        revoker.quit(address(0), token);
    }

    function test_Approve_ApprovedEventEmitted() public {
        // intially the balance = 0
        _setFeesAsGovernor(0);
        // register the distributor with fees = 100 MMC
        _registerDistributorWithApproval(0);

        vm.prank(governor); // as governor.
        // after register a distributor a Registered event is expected
        vm.expectEmit(true, true, false, false, address(syndication));
        emit Syndication.Approved(distributor);
        // distribuitor approved only by governor..
        ISyndicatableRegistrable(syndication).approve(distributor);
    }

    function test_Approve_SetZeroEnrollmentFees() public {
        // intially the balance = 0
        _registerAndApproveDistributor();
        assertEq(ILedger(syndication).getLedgerBalance(admin, token), 0);
    }

    function test_Approve_SetActiveState() public {
        _registerAndApproveDistributor();
        assertEq(ISyndicatableVerifiable(syndication).isActive(distributor), true);
    }

    function test_Approve_IncrementEnrollmentCount() public {
        _registerAndApproveDistributor();
        // valid approvals, increments the total of enrollments
        assertEq(ISyndicatableEnroller(syndication).getEnrollmentCount(), 1);
    }

    function test_Revoke_RevokedEventEmitted() public {
        // intially the balance = 0
        _registerAndApproveDistributor(); // still governor prank
        vm.prank(governor);
        // after register a distributor a Registered event is expected
        vm.expectEmit(true, true, false, false, address(syndication));
        emit Syndication.Revoked(distributor);
        // distribuitor get revoked by governance..
        ISyndicatableRevokable(syndication).revoke(distributor);
    }

    function test_Revoke_DecrementEnrollmentCount() public {
        _registerAndApproveDistributor(); // still governor prank
        // valid approvals, increments the total of enrollments
        vm.prank(governor);
        ISyndicatableRevokable(syndication).revoke(distributor);
        assertEq(ISyndicatableEnroller(syndication).getEnrollmentCount(), 0);
    }

    function test_Revoke_SetBlockedState() public {
        // intially the balance = 0
        _registerAndApproveDistributor(); // still governor prank
        // distribuitor get revoked by governance..
        vm.prank(governor);
        ISyndicatableRevokable(syndication).revoke(distributor);
        assertEq(ISyndicatableVerifiable(syndication).isBlocked(distributor), true);
    }
}
