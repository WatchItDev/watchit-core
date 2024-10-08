// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity 0.8.26;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ITreasurer } from "contracts/interfaces/ITreasurer.sol";

/// @title TreasurerUpgradeable Contract
/// @notice This contract is responsible for managing the address of the treasury in an upgradeable manner.
/// @dev This is an abstract contract that implements the ITreasurer interface and supports upgradeable functionality.
abstract contract TreasurerUpgradeable is Initializable, ITreasurer {
    /// @custom:storage-location erc7201:treasurerupgradeable
    struct TreasurerStorage {
        address _treasury;
    }

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.treasurer.trasure"")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant TREASURER_SLOT = 0xad118695963461d59b4e186bb251fe176897e2c57f3362e8dade6f9a4f8e7400;

    error InvalidTreasuryAddress(address);

    /// @inheritdoc ITreasurer
    /// @notice Gets the current address of the treasury.
    /// @return The address of the treasury.
    function getTreasuryAddress() public view returns (address) {
        TreasurerStorage storage $ = _getTreasurerStorage();
        return $._treasury;
    }

    /// @notice Initializes the treasurer with the given address.
    /// @param treasuryAddress The address of the treasury.
    function __Treasurer_init(address treasuryAddress) internal onlyInitializing {
        __Treasurer_init_unchained(treasuryAddress);
    }

    /// @notice Unchained initializer for the treasurer with the given address.
    /// @param treasuryAddress The address of the treasury.
    function __Treasurer_init_unchained(address treasuryAddress) internal onlyInitializing {
        _setTreasuryAddress(treasuryAddress);
    }

    /// @notice Internal function to set the address of the treasury.
    /// @param newTreasuryAddress The new address of the treasury.
    function _setTreasuryAddress(address newTreasuryAddress) internal {
        if (newTreasuryAddress == address(0)) revert InvalidTreasuryAddress(newTreasuryAddress);
        TreasurerStorage storage $ = _getTreasurerStorage();
        $._treasury = newTreasuryAddress;
    }

    /// @notice Internal function to get the treasurer storage.
    /// @return $ The treasurer storage.
    function _getTreasurerStorage() private pure returns (TreasurerStorage storage $) {
        assembly {
            $.slot := TREASURER_SLOT
        }
    }
}
