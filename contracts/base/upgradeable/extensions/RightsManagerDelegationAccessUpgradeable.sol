// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "contracts/interfaces/IRightsAccessController.sol";
import "contracts/interfaces/IAccessWitness.sol";
import "contracts/libraries/Types.sol";

// TODO crear un contrato para delegacion de derechos
// grantDelegation
// revokeDelegation
// isDelegated


abstract contract RightsManagerDelegationUpgradeable is
    Initializable,
    IRightsAccessController
{
    
}
