// pragma solidity 0.8.26;

// import "forge-std/Test.sol";
// import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import { ILedger } from "contracts/interfaces/ILedger.sol";
// import { IDisburser } from "contracts/interfaces/IDisburser.sol";
// import { ITreasurer } from "contracts/interfaces/ITreasurer.sol";
// import { IGovernable } from "contracts/interfaces/IGovernable.sol";
// import { IFeesManager } from "contracts/interfaces/IFeesManager.sol";
// import { ISyndicatableEnroller } from "contracts/interfaces/ISyndicatableEnroller.sol";
// import { ISyndicatableExpirable } from "contracts/interfaces/ISyndicatableExpirable.sol";
// import { ISyndicatablePenalizer } from "contracts/interfaces/ISyndicatablePenalizer.sol";
// import { ISyndicatableVerifiable } from "contracts/interfaces/ISyndicatableVerifiable.sol";
// import { ISyndicatableRegistrable } from "contracts/interfaces/ISyndicatableRegistrable.sol";
// import { ISyndicatableRevokable } from "contracts/interfaces/ISyndicatableRevokable.sol";

// import { BaseTest } from "test/BaseTest.t.sol";
// import { Syndication } from "contracts/syndication/Syndication.sol";
// import { FeesHelper } from "contracts/libraries/FeesHelper.sol";

// contract DistributorTest is BaseTest {
//     using FeesHelper for uint256;

//     address distributor;
//     address syndication;
//     address treasury;
//     address token;
//     address governor;

//     function setUp() public {
//         token = deployToken();
//         treasury = deployTreasury();
//         syndication = deploySyndication(treasury);
//         distributor = deployDistributor("contentrider.com");
//         governor = vm.addr(1);
//     }

 
// }
