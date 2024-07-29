// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IRightsCustodial.sol";

abstract contract RightsManagerDistributionUpgradeable is
    Initializable,
    IRightsCustodial
{
    /// @custom:storage-location erc7201:rightsmanagerdistributionupgradeable
    struct DistributionRightsStorage {
        mapping(uint256 => address) _custodying;
    }

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.distributionrights.custodying")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant DISTRIBUTION_RIGHTS_SLOT =
        0x19de352aacf5eb23e556c4ae8a1f47118f3051b029159b7e1b8f4f1672aaf600;

    // @notice Emitted when distribution rights are granted to a distributor.
    /// @param contentId The content  identifier.
    /// @param distributor The distributor contract address.
    event RightsGranted(uint256 contentId, address indexed distributor);

    /**
     * @notice Internal function to get the governor storage.
     * @return $ The distribution rights storage.
     */
    function _getRightsStorage()
        private
        pure
        returns (DistributionRightsStorage storage $)
    {
        assembly {
            $.slot := DISTRIBUTION_RIGHTS_SLOT
        }
    }

    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param distributor The distributor address to assign the content to.
    function _grantCustodial(address distributor, uint256 contentId) internal {
        DistributionRightsStorage storage $ = _getRightsStorage();
        $._custodying[contentId] = distributor;
        emit RightsGranted(contentId, distributor);
    }

    // this is where the fees are routed
    function getCustodial(uint256 contentId) public view returns (address) {
        DistributionRightsStorage storage $ = _getRightsStorage();
        return $._custodying[contentId];
    }

    function hasCustodial(
        address distributor,
        uint256 contentId
    ) public view returns (bool) {
        DistributionRightsStorage storage $ = _getRightsStorage();
        return $._custodying[contentId] == distributor;
    }
}
