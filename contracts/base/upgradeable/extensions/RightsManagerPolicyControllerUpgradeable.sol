// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsPolicyController.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager Policy Controller Upgradeable
/// @notice This abstract contract manages the delegation and revocation of rights from content holders to various policies.
/// @dev The contract is upgradeable and uses namespaced storage to manage the delegation of rights in a way that avoids storage layout collisions.
abstract contract RightsManagerPolicyControllerUpgradeable is
    Initializable,
    IRightsPolicyController
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @custom:storage-location erc7201:rightsmanagerdelegationupgradeable
    /// @dev Storage struct for managing the delegation of rights to policy contracts by content holders.
    struct RightsStorage {
        /// @dev Mapping to store the delegated rights for each policy contract (address) by each content holder (address).
        mapping(address => EnumerableSet.AddressSet) _delegation;
    }

    /// @dev Namespaced storage slot for RightsStorage to avoid storage layout collisions in upgradeable contracts.
    ///      The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
    bytes32 private constant DELEGATION_RIGHTS_SLOT =
        0x8de86c03e9c907c4cfd46ee06d6593a7fc5fdfb6903523c8213ef37d380b3b00;

    /// @notice Internal function to access the rights storage.
    /// @dev Uses inline assembly to assign the correct storage slot to the RightsStorage struct.
    /// @return $ The storage struct containing the rights delegation data.
    function _getRightsStorage()
        private
        pure
        returns (RightsStorage storage $)
    {
        assembly {
            $.slot := DELEGATION_RIGHTS_SLOT
        }
    }

    /// @dev Verify if the specified policy contract has been delegated the rights by the content holder.
    /// @param policy The address of the policy contract to check for delegation.
    /// @param holder The content rights holder to check for delegation.
    /// Reverts if the rights have not been delegated for the specified content ID.
    function isPolicyAuthorized(address policy, address holder) public {
        RightsStorage storage $ = _getRightsStorage();
        return $._delegation[holder].contains(policy);
    }

    /// @notice Retrieves all policies to which rights have been delegated by a specific content holder.
    /// @dev This function returns an array of policy contract addresses that have been delegated rights by the content holder.
    /// @param holder The content rights holder whose delegated policies are being queried.
    /// @return An array of policy contract addresses that have been delegated rights by the specified content holder.
    function getContentPolicies(
        address holder
    ) public view returns (address[] memory) {
        RightsStorage storage $ = _getRightsStorage();
        // https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet-values-struct-EnumerableSet-AddressSet-
        // This operation will copy the entire storage to memory, which can be quite expensive.
        // This function is designed to be used primarily as a view accessor, queried without any gas fees.
        // Developers should note that this function has an unbounded cost, and using it as part of a state-changing
        // function may render the function uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
        return $._delegation[holder].values();
    }

    /// @notice Delegates rights for a specific content ID to a policy contract.
    /// @dev This function stores the delegation details in the RightsStorage struct,
    ///      allowing the specified policy contract to manage rights for the content holder.
    /// @param policy The address of the policy contract to which rights are being delegated.
    /// @param holder The content rights holder delegating the rights.
    function _authorizePolicy(address policy, address holder) internal {
        RightsStorage storage $ = _getRightsStorage();
        $._delegation[holder].add(policy);
    }

    /// @notice Revokes the delegation of rights to a specific policy contract.
    /// @dev This function removes the rights delegation from the RightsStorage struct,
    ///      preventing the specified policy contract from managing rights for the content holder.
    /// @param policy The address of the policy contract whose rights delegation is being revoked.
    /// @param holder The content rights holder revoking the rights delegation.
    function _revokePolicy(address policy, address holder) internal {
        RightsStorage storage $ = _getRightsStorage();
        $._delegation[holder].remove(policy);
    }
}
