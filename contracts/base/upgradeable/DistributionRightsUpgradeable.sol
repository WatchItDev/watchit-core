// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "contracts/interfaces/IDistributor.sol";

abstract contract DistributionRightsUpgradeable is Initializable {
    // @notice Emitted when distribution rights are granted to a distributor.
    /// @param contentId The content  identifier.
    /// @param distributor The distributor contract address.
    event RightsGranted(uint256 contentId, IDistributor indexed distributor);
    /// mapping to record the current content custody contract.
    mapping(uint256 => IDistributor) private custodying;

    // this is where the fees are routed
    function getCustodial(uint256 contentId) public view returns (IDistributor) {
        return custodying[contentId];
    }

    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param distributor The distributor address to assign the content to.
    function _grantDistributionRights(
        IDistributor distributor,
        uint256 contentId
    ) internal {
        custodying[contentId] = distributor;
        emit RightsGranted(contentId, distributor);
    }
}
