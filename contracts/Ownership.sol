// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/interfaces/IReferendumVerifiable.sol";
import "contracts/interfaces/IOwnership.sol";

// TODO imp ERC404

/// @title Ownership ERC721 Upgradeable
/// @notice This abstract contract manages the ownership.
abstract contract Ownership is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    IOwnership
{
    address private referendum;
    event RegisteredContent(uint256 contentId);
    error InvalidNotApprovedContent();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    /// @param repository The contract registry to retrieve needed contracts instance.
    /// @dev This function is called only once during the contract deployment.
    function initialize(address repository) public initializer {
        __ERC721_init("Ownership", "WOT");
        __ERC721Enumerable_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

        IRepository repo = IRepository(repository);
        referendum = repo.getContract(T.ContractTypes.REFERENDUM);
    }

    /// @notice Modifier to ensure content is approved before distribution.
    /// @param to The address attempting to distribute the content.
    /// @param contentId The ID of the content to be distributed.
    /// @dev The content must be approved by referendum or the recipient must have a verified role.
    /// This modifier checks if the content is approved by referendum or if the recipient has a verified role.
    /// It also ensures that the recipient is the one who initially submitted the content for approval.
    modifier onlyApprovedContent(address to, uint256 contentId) {
        // Revert if the content is not approved or if the recipient is not the original submitter
        if (!IReferendumVerifiable(referendum).isApproved(to, contentId))
            revert InvalidNotApprovedContent();
        _;
    }

    /// @inheritdoc IRightsOwnership
    /// @notice Mints a new NFT to the specified address.
    /// @dev Our naive assumption is that only those who know the content id can mint the corresponding token.
    /// @param to The address to mint the NFT to.
    /// @param contentId The content id of the NFT. This should be a unique identifier for the NFT.
    function registerContent(
        address to,
        uint256 contentId
    ) external onlyApprovedContent(to, contentId) {
        _mint(to, contentId);
        emit RegisteredContent(contentId);
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

    /// @notice Checks if the contract supports a specific interface.
    /// @param interfaceId The interface ID to check.
    /// @return True if the contract supports the interface, false otherwise.
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(
            IERC165,
            ERC721Upgradeable,
            ERC2981Upgradeable,
            ERC721EnumerableUpgradeable
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
