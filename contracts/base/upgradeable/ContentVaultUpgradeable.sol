// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IContentVault.sol";

/// @title Content Vault Upgradeable
/// @notice This contract manages encrypted content storage in a secure vault.
/// @dev This contract uses an upgradeable pattern and a namespaced storage layout to avoid storage conflicts.
abstract contract ContentVaultUpgradeable is Initializable, IContentVault {
    /// @custom:storage-location erc7201:vaultupgradeable
    struct VaultStorage {
        mapping(uint256 => bytes) _secured; // Mapping to store encrypted content by content ID
    }

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.vault.secured")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant VAULT_SLOT =
        0x9c5345ebbec2d6cecdb38d9956fa842e9d714f43866d36c54fbb441829f0b000;

    /**
     * @notice Internal function to get the vault storage.
     * @return $ The vault storage.
     */
    function _getVaultStorage() private pure returns (VaultStorage storage $) {
        assembly {
            $.slot := VAULT_SLOT
        }
    }

    /**
     * @notice Returns the encrypted content for a given content ID.
     * @param contentId The identifier of the content.
     * @return The encrypted content as bytes.
     */
    function getSecuredContent(
        uint256 contentId
    ) public view returns (bytes memory) {
        VaultStorage storage $ = _getVaultStorage();
        return $._secured[contentId];
    }

    /// @notice Stores encrypted content in the vault.
    /// @param contentId The identifier of the content.
    /// @param encryptedContent The encrypted content to store.
    /// @dev This function allows storing any secured data as bytes, enabling dynamic secure data storage.
    /// For example: LIT chain.ciphertext.dataToEncryptHash combination, public key encrypted data, 
    /// shared key encrypted data, etc.
    function _secureContent(
        uint256 contentId,
        bytes memory encryptedContent
    ) internal {
        VaultStorage storage $ = _getVaultStorage();
        $._secured[contentId] = encryptedContent;
    }
}
