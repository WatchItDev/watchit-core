// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/interfaces/IRightsOwnership.sol";

/// @title Rights Manager ERC721 Upgradeable
/// @notice This abstract contract manages the ownership and royalty rights for ERC721 tokens, 
// integrating with various ERC721 extensions such as Enumerable and Royalty.
abstract contract RightsManagerERC721Upgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    IRightsOwnership
{
    /**
     * @dev Internal function to update the ownership of a token.
     * @param to The address to transfer the token to.
     * @param tokenId The ID of the token to transfer.
     * @param auth The address authorized to perform the transfer.
     * @return The address of the new owner of the token.
     *
     * This function overrides the `_update` function from both ERC721Upgradeable and ERC721EnumerableUpgradeable.
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Internal function to increase the balance of an account.
     * @param account The address of the account whose balance is to be increased.
     * @param value The amount by which the balance is to be increased.
     *
     * This function overrides the `_increaseBalance` function from both ERC721Upgradeable and ERC721EnumerableUpgradeable.
     */
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }
    
    /**
     * @notice Checks if the contract supports a specific interface.
     * @param interfaceId The interface ID to check.
     * @return True if the contract supports the interface, false otherwise.
     *
     * This function overrides the `supportsInterface` function from multiple interfaces and extensions, including ERC165, ERC721Upgradeable, ERC721RoyaltyUpgradeable, and ERC721EnumerableUpgradeable.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            IERC165,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
