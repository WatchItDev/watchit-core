// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IDistributor.sol";

abstract contract ContentAccessUpgradeable is Initializable {
    // Mapping to store the access control list for each watcher and content hash
    mapping(address watcher => mapping(uint256 contentId => uint256 timeframe))
        private acl;

    function granContentAccess(
        address watcher,
        uint256 contentId,
        uint256 timeframe
    ) public {
        acl[watcher][contentId] = block.timestamp + timeframe;
    }

    /// @notice Checks if access is allowed for a specific watcher and content.
    /// @param watcher The address of the watcher.
    /// @param contentId The content id to check access.
    /// @return True if access is allowed, false otherwise.
    function hasContentAccess(
        address watcher,
        uint256 contentId
    ) public view returns (bool) {
        return acl[watcher][contentId] <= Time.timestamp();
    }
}
