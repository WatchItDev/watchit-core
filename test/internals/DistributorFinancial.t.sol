pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/base/upgradeable/Distributor.sol";


contract DistributorFinancialTest is Test, Disitributor {

    function test_NegotiationPlusConstantFeesIncrementalDemand() {
        uint256 demand = 1000; // under 1000 content custodial..
        console.log(_getAdjustedFloor(1e8, 1000));
    }


    function test_NegotiationPlusVariantFees() {}
    function test_NegotiationPlusVariantPlusFlattentFactorFees() {}
    function test_NegotiationAutoAdjustedFactorFees() {}
}
