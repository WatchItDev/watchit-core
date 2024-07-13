// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "contracts/base/upgradeable/GovernableUpgradeable.sol";

/// @title Ownership
/// @notice This contract manages ownership of NFTs using ERC721 and AccessControlUpgradeable.
/// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent-vs-uups
/// ERC2981
contract Ownership is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    GovernableUpgradeable,
    UUPSUpgradeable
{

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes the contract on "proxy context" (storage, etc).
    /// @notice This function is called only once during the contract deployment.
    function initialize() public initializer {
        __ERC721_init("Watchit", "WOT");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();
        __Governable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @dev Internal function to update the ownership of a token.
    /// @param to The address to transfer the token to.
    /// @param tokenId The ID of the token to transfer.
    /// @param auth The address authorized to perform the transfer.
    /// @return The address of the new owner of the token.
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

    /// @dev Internal function to increase the balance of an account.
    /// @param account The address of the account whose balance is to be increased.
    /// @param value The amount by which the balance is to be increased.
    function _increaseBalance(
        address account,
        uint128 value
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    /// @dev Authorizes the upgrade of the contract.
    /// @notice Only the owner can authorize the upgrade.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Mints a new NFT to the specified address.
    /// @dev The minting is public. Our naive assumption is that only those who know the CID hash can mint the corresponding token.
    /// @param to The address to mint the NFT to.
    /// @param contentId The CID hash of the NFT. This should be a unique identifier for the NFT.
    function mint(address to, uint256 contentId) external {
        // MAX supply
        _mint(to, contentId);
    }

    /// @notice Burns a token based on the provided token ID.
    /// @dev This burn operation is generally delegated through governance.
    /// @param contentId The CID hash of the NFT to be burned.
    function burn(uint256 contentId) external onlyGov {
        _update(address(0), contentId, address(0));
    }

    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(
            AccessControlUpgradeable,
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
