pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "contracts/base/upgradeable/Distributor.sol";

contract DistributorFinancialTest is Test, Disitributor {

    function test_NegotiationPlusConstantFees() {}
    function test_NegotiationPlusVariantFees() {}
    function test_NegotiationPlusVariantPlusFlattentFactorFees() {}
    function test_NegotiationAutoAdjustedFactorFees() {}
}
