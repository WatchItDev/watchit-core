// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsAccessController.sol";

/// @title Rights Manager Content Access Upgradeable
/// @notice This contract manages access control for content based on timeframes.
abstract contract RightsManagerContentAccessUpgradeable is Initializable, IRightsAccessController {
    /// @dev Mapping to store the access control list for each watcher and content hash.
    mapping(uint256 => mapping(address => uint256)) private acl;

    /// @notice Grants access to a specific watcher for a certain content ID for a given timeframe.
    /// @param account The address of the watcher.
    /// @param contentId The content ID to grant access to.
    /// @param timeframe The timeframe in seconds for which access is granted.
    function _grantAccess(
        address account,
        uint256 contentId,
        uint256 timeframe
    ) internal {
        acl[contentId][account] = Time.timestamp() + timeframe;
    }

    /// @notice Checks if access is allowed for a specific watcher and content.
    /// @param account The address of the watcher.
    /// @param contentId The content ID to check access.
    /// @return True if access is allowed, false otherwise.
    function hasAccess(
        address account,
        uint256 contentId
    ) public view returns (bool) {
        return acl[contentId][account] > Time.timestamp();
    }
}
