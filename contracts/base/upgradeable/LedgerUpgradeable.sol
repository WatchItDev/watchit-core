// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.8.24/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "contracts/interfaces/IDistributor.sol";
import "contracts/interfaces/ILedger.sol";

abstract contract LedgerUpgradeable is Initializable, ILedger {
    /// @custom:storage-location erc7201:ledgerupgradeable
    struct LedgerStorage {
        mapping(address => mapping(address => uint256)) _ledger;
    }

    // ERC-7201: Namespaced Storage Layout is another convention that can be used to avoid storage layout errors
    // keccak256(abi.encode(uint256(keccak256("watchit.ledger.trasure")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant LEDGER_SLOT =
        0xcb711bda070b7bbcc2b711ef3993cc17677144f4419b29e303bef375c5f40f00;

    /**
     * @notice Internal function to get the ledger storage.
     * @return $ The ledger storage.
     */
    function _getLedgerStorage()
        private
        pure
        returns (LedgerStorage storage $)
    {
        assembly {
            $.slot := LEDGER_SLOT
        }
    }

    function __Ledger_init() internal onlyInitializing {}

    function __Ledger_init_unchained() internal onlyInitializing {}

    /// @notice Internal function to store the token fees for account.
    /// @param account The address of the account.
    /// @param amount The amount to register to account.
    /// @param token The token to register to account.
    /// @dev This function is used to store the fees for acount.
    function _setLedgerEntry(
        address account,
        uint256 amount,
        address token
    ) internal {
        LedgerStorage storage $ = _getLedgerStorage();
        $._ledger[account][token] = amount;
    }

    /// @notice Internal function to accumulate token fees for account.
    /// @param account The address of the account.
    /// @param amount The amount to register to account.
    /// @param token The token to register to account.
    /// @dev This function is used to store the fees for acount.
    function _sumLedgerEntry(
        address account,
        uint256 amount,
        address token
    ) internal {
        LedgerStorage storage $ = _getLedgerStorage();
        $._ledger[account][token] += amount;
    }

    /// @notice Internal function to subtract token fees for account.
    /// @param account The address of the account.
    /// @param amount The amount to register to account.
    /// @param token The token to register to account.
    /// @dev This function is used to store the fees for acount.
    function _subLedgerEntry(
        address account,
        uint256 amount,
        address token
    ) internal {
        LedgerStorage storage $ = _getLedgerStorage();
        $._ledger[account][token] -= amount;
    }

    /// @inheritdoc ILedger
    /// @notice Retrieves the registered coins amoint for the specified account.
    /// @param account The address of the account.
    function getLedgerEntry(address account) public view returns (uint256) {
        LedgerStorage storage $ = _getLedgerStorage();
        return $._ledger[account][address(0)];
    }

    /// @inheritdoc ILedger
    /// @notice Retrieves the registered token amount for the specified account.
    /// @param account The address of the account.
    /// @param token The token to retrieve ledger amount.
    function getLedgerEntry(
        address account,
        address token
    ) public view returns (uint256) {
        LedgerStorage storage $ = _getLedgerStorage();
        return $._ledger[account][token];
    }
}
