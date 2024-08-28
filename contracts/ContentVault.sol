// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "contracts/base/upgradeable/ContentVaultUpgradeable.sol";

// TODO upgradeable y inicializar con DRM
contract ContentVault is ContentVaultUpgradeable {
    function storeSecureContent(
        uint256 contentId,
        bytes calldata encryptedContent
    ) public {}

    function getSecureContent(
        uint256 contentId
    ) public view returns (bytes memory) {}
}
