// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsDelegable.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager Delegation Upgradeable
/// @notice This abstract contract manages the delegation of rights
/// for specific content IDs to various strategy policy.
abstract contract RightsManagerDelegationUpgradeable is
    Initializable,
    IRightsDelegable
{
    using EnumerableSet for EnumerableSet.UintSet;
    /// @custom:storage-location erc7201:rightsmanagerdelegationupgradeable
    /// @dev Storage struct for managing rights delegation to policies.
    struct RightsStorage {
        /// @dev Mapping to store the delegated rights for each policy (address) and content ID.
        mapping(address => EnumerableSet.UintSet) _delegation;
    }

    /// @dev Error thrown when rights have not been delegated to the specified grantee for the given content ID.
    /// @param grantee The address of the account or contract attempting to access rights.
    /// @param contentId The ID of the content for which access is attempted.
    error InvalidNotRightsDelegated(address grantee, uint256 contentId);

    /// @dev Namespaced storage slot for RightsStorage to avoid storage layout collisions in upgradeable contracts.
    /// @dev The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
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

    /// @dev Modifier to ensure that the given policy contract has been delegated
    /// the rights for the specific content ID.
    /// @param grantee The address of the account or contract to delegate rights to.
    /// @param contentId The content ID to check for delegation.
    /// Reverts if the rights have not been delegated for the content ID.
    modifier onlyWhenRightsDelegated(address grantee, uint256 contentId) {
        RightsStorage storage $ = _getRightsStorage();
        if (!$._delegation[grantee].contains(contentId))
            revert InvalidNotRightsDelegated(grantee, contentId);
        _;
    }


    // TODO aca deberia ser "obtener los policies de un contenido?

    /// @notice Retrieves all content IDs for which rights have been delegated to a grantee.
    /// @dev This function returns an array of content IDs that the specified grantee
    /// has been delegated rights for. It fetches the data from the RightsStorage struct.
    /// @param grantee The address of the account or contract whose delegated rights are being queried.
    /// @return An array of content IDs that have been delegated to the specified grantee.
    function getDelegatedRights(
        address grantee
    ) public view returns (uint256[] memory) {
        RightsStorage storage $ = _getRightsStorage();
        // https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet-values-struct-EnumerableSet-AddressSet-
        // This operation will copy the entire storage to memory, which can be quite expensive. 
        // This is designed to mostly be used by view accessors that are queried without any gas fees. 
        // Developers should keep in mind that this function has an unbounded cost, and using it as part of a state-changing 
        // function may render the function uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
        return $._delegation[grantee].values();
    }

    /// @notice Delegates rights for a specific content ID to a grantee.
    /// @dev This function stores the delegation details in the RightsStorage struct.
    /// @param grantee The address of the account or contract to delegate rights to.
    /// @param contentId The content ID for which rights are being delegated.
    function _delegateRights(address grantee, uint256 contentId) internal {
        RightsStorage storage $ = _getRightsStorage();
        $._delegation[grantee].add(contentId);
    }

    /// @notice Revokes the delegation of rights for a grantee.
    /// @dev This function removes the rights delegation from the RightsStorage struct.
    /// @param grantee The address of the account or contract whose delegation is being revoked.
    /// @param contentId The content ID for which rights are being delegated.
    function _revokeRights(address grantee, uint256 contentId) internal {
        RightsStorage storage $ = _getRightsStorage();
        $._delegation[grantee].remove(contentId);
    }
}
