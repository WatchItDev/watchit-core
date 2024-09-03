// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "contracts/interfaces/IRightsDealBroker.sol";
import "contracts/interfaces/IPolicy.sol";
import "contracts/libraries/Types.sol";

/// @title RightsManagerBrokerUpgradeable
/// @notice This abstract contract handles the deal-proofs logic to interact with policies.
/// @dev This contract manages the lifecycle of deals between content holders and policy contracts,
/// including the creation, validation, and retrieval of deal proofs. The design ensures that the logic is modular,
/// facilitating secure and flexible interactions between different components of the system.
abstract contract RightsManagerBrokerUpgradeable is
    Initializable,
    IRightsDealBroker
{
    using ERC165Checker for address;

    /// @custom:storage-location erc7201:rightsbroker.upgradeable
    /// @dev Storage struct for the access control list (ACL) that maps content IDs and accounts to policy contracts.
    struct BrokerStorage {
        // @dev Holds a bounded key expressing the deal between the parts.
        // The key is derived using keccak256 hashing of the account and the rights holder.
        // This mapping stores active deals, indexed by their unique proof.
        mapping(bytes32 => T.Deal) _deals;
    }

    // @notice Thrown when the provided proof is invalid.
    error InvalidDealProof();

    /// @dev Namespaced storage slot for BrokerStorage to avoid storage layout collisions in upgradeable contracts.
    /// @dev The storage slot is calculated using a combination of keccak256 hashes and bitwise operations.
    bytes32 private constant BROKER_SLOT =
        0x643a77ccd706c45494ec65fcdc4967bac329558cb2707590bde0365eb9b56400;

    /**
     * @notice Internal function to access the Broker storage.
     * @dev Uses inline assembly to assign the correct storage slot to the BrokerStorage struct.
     * @return $ The storage struct containing the brokered deals.
     */
    function _getBrokerStorage()
        private
        pure
        returns (BrokerStorage storage $)
    {
        assembly {
            $.slot := BROKER_SLOT
        }
    }

    /// @notice Modifier to ensure the validity of a deal proof.
    /// @dev Validates that the given proof corresponds to an active deal in the storage.
    /// @param proof The unique identifier of the deal being validated.
    modifier onlyValidProof(bytes32 proof) {
        BrokerStorage storage $ = _getBrokerStorage();
        if (!_validProof(proof)) revert InvalidDealProof();
        _;
    }

    /// @notice Creates and stores a new deal proof.
    /// @dev The proof is generated using keccak256 hashing of the deal data.
    ///      This proof is then used as a unique identifier for the deal in the storage.
    /// @param deal The deal object containing the terms and parties involved.
    /// @return proof The unique identifier for the newly created deal.
    function _createProof(T.Deal memory deal) internal returns (bytes32) {
        BrokerStorage storage $ = _getBrokerStorage();
        // yes, we can encode full struct as abi.encode with extra overhead..
        bytes32 proof = keccak256(
            abi.encodePacked(
                deal.time,
                deal.total,
                deal.holder,
                deal.account,
                deal.custodial
            )
        );

        // activate deal before
        $._deals[proof] = deal;
        return proof;
    }

    /// @notice Retrieves a deal associated with the given proof.
    /// @dev Fetches the deal from storage using the proof as the key.
    /// @param proof The unique identifier of the deal to retrieve.
    /// @return deal The deal object associated with the provided proof.
    function getDeal(bytes32 proof) public view returns (T.Deal memory) {
        BrokerStorage storage $ = _getBrokerStorage();
        return $._deals[proof];
    }

    /// @notice Checks if a given proof corresponds to an active deal.
    /// @dev Verifies the existence and active status of the deal in storage.
    /// @param proof The unique identifier of the deal to validate.
    /// @return isValid True if the deal is active, false otherwise.
    function _validProof(bytes32 proof) internal view returns (bool) {
        BrokerStorage storage $ = _getBrokerStorage();
        return $._deals[proof].active;
    }

    /// @notice Close a deal for a given proof corresponds to an active deal.
    /// @dev Set the status as inactive of the deal in storage.
    /// @param proof The unique identifier of the deal to validate.
    function _closeDeal(bytes32 proof) internal {
        BrokerStorage storage $ = _getBrokerStorage();
        $._deals[proof].active = false;
    }
}
