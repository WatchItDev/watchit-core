// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsCustodial.sol";

/// @title Rights Manager Distribution Upgradeable
/// @notice This abstract contract manages the assignment and retrieval of distribution rights for content,
/// ensuring that custodial rights are properly managed.
abstract contract RightsManagerCustodialUpgradeable is
    Initializable,
    IRightsCustodial
{
    using EnumerableSet for EnumerableSet.UintSet;

    /// @custom:storage-location erc7201:rightsmanagercustodialupgradeable
    /// @dev Storage struct for managing custodial rights for content distribution.
    struct CustodyStorage {
        /// @dev Mapping to store the custodial address for each content ID.
        mapping(uint256 => address) _custodying;
        mapping(address => EnumerableSet.UintSet) _registry;
    }

    /// @dev Namespaced storage slot for CustodyStorage to avoid storage layout collisions in upgradeable contracts.
    /// @dev The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
    bytes32 private constant DISTRIBUTION_CUSTODY_SLOT =
        0x19de352aacf5eb23e556c4ae8a1f47118f3051b029159b7e1b8f4f1672aaf600;

    /**
     * @notice Internal function to access the custodial storage.
     * @dev Uses inline assembly to assign the correct storage slot to the CustodyStorage struct.
     * @return $ The storage struct containing the custodial information for distribution rights.
     */
    function _getCustodyStorage()
        private
        pure
        returns (CustodyStorage storage $)
    {
        assembly {
            $.slot := DISTRIBUTION_CUSTODY_SLOT
        }
    }

    /// @notice Assigns distribution rights over the content to a specified distributor.
    /// @dev The distributor must be active and properly authorized to handle the content.
    /// @param distributor The address of the distributor to assign the content to.
    /// @param contentId The ID of the content for which distribution rights are being granted.
    function _grantCustody(address distributor, uint256 contentId) internal {
        CustodyStorage storage $ = _getCustodyStorage();
        address prevCustodial = getCustody(contentId);
        if (prevCustodial != address(0))
            $._registry[prevCustodial].remove(contentId);

        $._custodying[contentId] = distributor;
        $._registry[distributor].add(contentId);
    }

    /// @notice Retrieves the total number of content items in custody for a given distributor.
    /// @dev This function accesses the CustodyStorage to fetch the count of content associated with the specified distributor.
    /// @param distributor The address of the distributor whose custodial content count is being requested.
    /// @return The total number of content items that the specified distributor currently has in custody.
    function getCustodyCount(
        address distributor
    ) public view returns (uint256) {
        CustodyStorage storage $ = _getCustodyStorage();
        return $._registry[distributor].length();
    }

    /// @notice Retrieves the custody records associated with a specific distributor.
    /// @param distributor The address of the distributor whose custody records are to be retrieved.
    /// @return An array of unsigned integers representing the custody records associated with the given distributor.
    function getCustodyRegistry(
        address distributor
    ) public view returns (uint256[] memory) {
        CustodyStorage storage $ = _getCustodyStorage();
        // https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet-values-struct-EnumerableSet-AddressSet-
        // This operation will copy the entire storage to memory, which can be quite expensive. 
        // This is designed to mostly be used by view accessors that are queried without any gas fees. 
        // Developers should keep in mind that this function has an unbounded cost, and using it as part of a state-changing 
        // function may render the function uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
        return $._registry[distributor].values();
    }

    /// @notice Retrieves the custodial address for a given content ID.
    /// @dev This function ensures that the retrieved custodial address is active and authorized.
    /// @param contentId The ID of the content for which the custodial address is being requested.
    /// @return The address of the active custodial responsible for the specified content ID.
    function getCustody(uint256 contentId) public view returns (address) {
        CustodyStorage storage $ = _getCustodyStorage();
        return $._custodying[contentId];
    }
}
