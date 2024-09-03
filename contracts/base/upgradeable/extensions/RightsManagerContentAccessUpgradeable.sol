// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "contracts/interfaces/IRightsAccessController.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";

/// @title Rights Manager Content Access Upgradeable
/// @notice This abstract contract manages content access control using a license
/// policy contract that must implement the IPolicy interface.
abstract contract RightsManagerContentAccessUpgradeable is
    Initializable,
    IRightsAccessController
{
    using ERC165Checker for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    // uint256 private constant MAX_POLICIES = 3; // Max limit of policies for account.
    /// @dev The interface ID for IPolicy, used to verify that a policy contract implements the correct interface.
    bytes4 private constant INTERFACE_POLICY = type(IPolicy).interfaceId;
    /// @custom:storage-location erc7201:rightscontentaccess.upgradeable
    /// @dev Storage struct for the access control list (ACL) that maps content IDs and accounts to policy contracts.
    struct ACLStorage {
        /// @dev Mapping to store the access control list for each content ID and account.
        mapping(address => EnumerableSet.AddressSet) _acl;
    }

    /// @dev Namespaced storage slot for ACLStorage to avoid storage layout collisions in upgradeable contracts.
    /// @dev The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
    bytes32 private constant ACCESS_CONTROL_SLOT =
        0xcd95b85482a9213e30949ccc9c44037e29b901ca879098f5c64dd501b45d9200;

    /**
     * @notice Internal function to access the ACL storage.
     * @dev Uses inline assembly to assign the correct storage slot to the ACLStorage struct.
     * @return $ The storage struct containing the access control list.
     */
    function _getACLStorage() private pure returns (ACLStorage storage $) {
        assembly {
            $.slot := ACCESS_CONTROL_SLOT
        }
    }

    /// @dev Error thrown when the policy contract does not implement the IPolicy interface.
    error InvalidPolicyContract(address);
    error MaxPoliciesReached();

    /// @dev Modifier to check that a policy contract implements the IPolicy interface.
    /// @param policy The address of the license policy contract.
    /// Reverts if the policy does not implement the required interface.
    modifier onlyPolicyContract(address policy) {
        if (!policy.supportsInterface(INTERFACE_POLICY)) {
            revert InvalidPolicyContract(policy);
        }
        _;
    }

    /// @notice Registers a new policy for a specific account and policy, maintaining a chain of precedence.
    /// @param account The address of the account to be granted access through the policy.
    /// @param policy The address of the policy contract responsible for validating the conditions of the license.
    function _registerPolicy(address account, address policy) internal {
        ACLStorage storage $ = _getACLStorage();
        // Add the new policy as the most recent, following LIFO precedence
        // an account could be bounded to different policies to access contents
        $._acl[account].add(policy);
    }

    /// @notice Verifies whether access is allowed for a specific account and content based on a given license.
    /// @param account The address of the account to verify access for.
    /// @param contentId The ID of the content for which access is being checked.
    /// @param policy The address of the license policy contract used to verify access.
    /// @return Returns true if the account is granted access to the content based on the license, false otherwise.
    function _verify(
        address account,
        uint256 contentId,
        address policy
    ) private view returns (bool) {
        // if not registered license policy..
        if (policy == address(0)) return false;
        IPolicy policy_ = IPolicy(policy);
        return policy_.comply(account, contentId);
    }

    /// @inheritdoc IRightsAccessController
    /// @notice Retrieves the list of policys associated with a specific account and content ID.
    /// @param account The address of the account for which policies are being retrieved.
    /// @return An array of addresses representing the policies associated with the account and content ID.
    function getPolicies(
        address account
    ) public view returns (address[] memory) {
        ACLStorage storage $ = _getACLStorage();
        // https://docs.openzeppelin.com/contracts/5.x/api/utils#EnumerableSet-values-struct-EnumerableSet-AddressSet-
        // This operation will copy the entire storage to memory, which can be quite expensive.
        // This is designed to mostly be used by view accessors that are queried without any gas fees.
        // Developers should keep in mind that this function has an unbounded cost, 
        /// and using it as part of a state-changing function may render the function uncallable 
        /// if the set grows to a point where copying to memory consumes too much gas to fit in a block.
        return $._acl[account].values();
    }

    // TODO potential improvement getChainedPolicies
    // allowing concatenate policies to evaluate compliance...
    // This approach supports complex access control scenarios where multiple factors need to be considered.

    /// @notice Retrieves the first active policy for a specific account and content in LIFO order.
    /// @param account The address of the account to evaluate.
    /// @param contentId The ID of the content to evaluate policies for.
    /// @return A tuple containing:
    /// - A boolean indicating whether an active policy was found (`true`) or not (`false`).
    /// - The address of the active policy if found, or `address(0)` if no active policy is found.
    function getActivePolicy(
        address account,
        uint256 contentId
    ) public view returns (bool, address) {
        address[] memory policies = getPolicies(account);
        uint256 i = policies.length - 1;

        while (true) {
            // LIFO precedence order: last registered policy is evaluated first.
            // The first complying policy is returned.
            bool comply = _verify(account, contentId, policies[i]);
            if (comply) return (true, policies[i]);
            if (i == 0) break; // the first happening..
            unchecked {
                --i;
            }
        }
        // No active policy found
        return (false, address(0));
    }
}
