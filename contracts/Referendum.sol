// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.26;

import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { EIP712Upgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import { NoncesUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/NoncesUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { GovernableUpgradeable } from "contracts/base/upgradeable/GovernableUpgradeable.sol";
import { QuorumUpgradeable } from "contracts/base/upgradeable/QuorumUpgradeable.sol";
import { IReferendum } from "contracts/interfaces/IReferendum.sol";
import { IReferendumRoleManager } from "contracts/interfaces/IReferendumRoleManager.sol";
import { IReferendumVerifiable } from "contracts/interfaces/IReferendumVerifiable.sol";

import { C } from "contracts/libraries/Constants.sol";
import { T } from "contracts/libraries/Types.sol";

/// @title Content curation contract.
/// @notice This contract allows for the submission, voting, and approval/rejection of content.
contract Referendum is
    Initializable,
    UUPSUpgradeable,
    GovernableUpgradeable,
    NoncesUpgradeable,
    EIP712Upgradeable,
    QuorumUpgradeable,
    IReferendum,
    IReferendumVerifiable,
    IReferendumRoleManager
{
    using EnumerableSet for EnumerableSet.UintSet;
    mapping(address => EnumerableSet.UintSet) private submissions;
    // This role is granted to any representant trusted account. eg: Verified Accounts, etc.
    bytes32 private constant VERIFIED_ROLE = keccak256("VERIFIED_ROLE");

    // Error to be thrown when the submission initiator is invalid.
    error InvalidSubmissionSignature();
    error InvalidSubmissionInitiator();

    /// @dev Event emitted when a content is submitted for referendum.
    /// @param contentId The ID of the content submitted.
    /// @param initiator The address of the initiator who submitted the content.
    event ContentSubmitted(address initiator, uint256 indexed contentId);

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
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    function initialize() public initializer {
        __Quorum_init();
        __UUPSUpgradeable_init();
        __EIP712_init("Referendum", "1");
        __Governable_init(_msgSender());
    }

    /// @notice Function that should revert when msg.sender is not authorized to upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    /// @dev See https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable-_authorizeUpgrade-address-
    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {}

    /// @notice Checks if the content is active nor blocked.
    /// @param contentId The ID of the content.
    /// @return True if the content is active, false otherwise.
    function isActive(uint256 contentId) public view returns (bool) {
        return _status(contentId) == Status.Active;
    }

    /// @notice Checks if the content is approved.
    /// @param initiator The submission account address .
    /// @param contentId The ID of the content.
    /// @return True if the content is approved, false otherwise.
    function isApproved(address initiator, uint256 contentId) public view returns (bool) {
        bool approved = isActive(contentId);
        bool validAccount = submissions[initiator].contains(contentId);
        bool verifiedRole = hasRole(VERIFIED_ROLE, initiator);
        // is approved with a valid submission account or is verified account..
        return (approved && validAccount) || verifiedRole;
    }

    /// @notice Grants the verified role to a specific account.
    /// @param account The address of the account to verify.
    /// @dev Only governance is allowed to grant the role.
    function grantVerifiedRole(address account) external onlyGov {
        _grantRole(VERIFIED_ROLE, account);
    }

    /// @notice Revoke the verified role to a specific account.
    /// @param account The address of the account to revoke.
    /// @dev Only governance is allowed to revoke the role.
    function revokeVerifiedRole(address account) external onlyGov {
        _revokeRole(VERIFIED_ROLE, account);
    }

    /// @notice Submits a content proposition for referendum.
    /// @param contentId The ID of the content to be submitted.
    /// @param initiator The address of the initiator submitting the content.
    /// @dev The content ID is reviewed by governance.
    function submit(uint256 contentId, address initiator) public {
        if (initiator == address(0)) revert InvalidSubmissionInitiator();

        _register(contentId);
        submissions[initiator].add(contentId);
        emit ContentSubmitted(initiator, contentId);
    }

    /// @notice Submits a content proposition for referendum with a signature.
    /// @param contentId The ID of the content to be submitted.
    /// @param initiator The address of the initiator submitting the content.
    /// @param sig The EIP712 signature for the submission.
    function submitWithSig(uint256 contentId, address initiator, T.EIP712Signature calldata sig) external {
        // https://eips.ethereum.org/EIPS/eip-712
        uint256 nonce = _useNonce(initiator);
        bytes32 structHash = keccak256(abi.encode(C.REFERENDUM_SUBMIT_TYPEHASH, contentId, initiator, nonce));

        // retrieve the signer from digest and signature to check if the signature correspond to expected signer.
        bytes32 digest = _hashTypedDataV4(structHash); // expected keccak256("\x19\x01" ‖ domainSeparator ‖ hashStruct(message))
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);
        if (signer != initiator) revert InvalidSubmissionSignature();
        submit(contentId, initiator);
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
}
