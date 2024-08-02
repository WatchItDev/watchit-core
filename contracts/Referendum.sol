// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "contracts/base/upgradeable/GovernableUpgradeable.sol";
import "contracts/base/upgradeable/QuorumUpgradeable.sol";
import "contracts/interfaces/IContentReferendum.sol";
import "contracts/libraries/Types.sol";

/// @title Content curation contract.
/// @notice This contract allows for the submission, voting, and approval/rejection of content.
contract Referendum is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    QuorumUpgradeable,
    IContentReferendum
{
    uint256 public count;
    mapping(uint256 => address) public submissions;
    error InvalidSubmissionInitiator();

    /// @dev Event emitted when a content is submitted for referendum.
    /// @param contentId The ID of the content submitted.
    /// @param initiator The address of the initiator who submitted the content.
    event ContentSubmitted(
        address initiator,
        uint256 indexed contentId,
        T.ContentParams conditions
    );

    /// @dev Event emitted when a content is approved.
    /// @param contentId The ID of the content approved.
    event ContentApproved(uint256 indexed contentId);

    /// @dev Event emitted when a content is revoked.
    /// @param contentId The ID of the content revoked.
    event ContentRevoked(uint256 indexed contentId);

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// @notice This constructor prevents the implementation contract from being initialized.
    /// @dev See https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    function initialize() public initializer {
        __Quorum_init();
        __Governable_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyAdmin {}

    /// @notice Returns the address that submitted the content proposition.
    /// @param contentId The ID of the content.
    /// @return The address of the initiator who submitted the content.
    function approvedFor(uint256 contentId) public view returns (address) {
        return submissions[contentId];
    }

    /// @notice Checks if the content is approved.
    /// @param contentId The ID of the content.
    /// @return True if the content is approved, false otherwise.
    function isApproved(uint256 contentId) public view returns (bool) {
        return _status(contentId) == Status.Active;
    }

    /// @notice Submits a content proposition for referendum.
    /// @param contentId The ID of the content to be submitted.
    /// @param initiator The address of the initiator submitting the content.
    /// @dev The content ID is reviewed by a set number of people before voting.
    function submit(
        uint256 contentId,
        address initiator,
        T.ContentParams calldata params
    ) public {
        if (initiator == address(0)) revert InvalidSubmissionInitiator();

        count++;
        submissions[contentId] = initiator;
        _register(contentId);

        emit ContentSubmitted(initiator, contentId, params);
    }

    /// @notice Submits a content proposition for referendum.
    /// @param contentId The ID of the content to be submitted.
    /// @param initiator The address of the initiator submitting the content.
    /// @dev The content ID is reviewed by a set number of people before voting.
    function submitWithSig(
        uint256 contentId,
        address initiator,
        T.ContentParams calldata params,
        T.EIP712Signature calldata signature
    ) public {
        if (initiator == address(0)) revert InvalidSubmissionInitiator();

        // TODO finish this..
        // bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH,
        // owner, spender, value, _useNonce(owner), deadline));

        // bytes32 hash = _hashTypedDataV4(structHash);

        // address signer = ECDSA.recover(hash, v, r, s);
        // if (signer != initiator) {
        //     revert ERC2612InvalidSigner(signer, owner);
        // }

        _register(contentId);
        submissions[contentId] = initiator;
        count++;
        emit ContentSubmitted(initiator, contentId, params);
    }

    /// @notice Reject a content proposition.
    /// @param contentId The ID of the content to be revoked.
    function reject(uint256 contentId) public onlyGov {
        _revoke(contentId);
        emit ContentRevoked(contentId);
    }

    /// @notice Approves a content proposition.
    /// @param contentId The ID of the content to be approved.
    function approve(uint256 contentId) public onlyGov {
        _approve(contentId);
        emit ContentApproved(contentId);
    }

    function submit(uint256 contentId, address initiator) external override {}
}
