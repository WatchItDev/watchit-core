// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "../interfaces/IModuleRegistrant.sol";
import "../interfaces/IModuleRegistry.sol";
import "../libraries/Types.sol";

/**
 * @title LensModuleRegistrant
 * @dev Abstract contract for registering a module with a module registry.
 */
abstract contract LensModuleRegistrant is ILensModuleRegistrant {
    /// @notice Emitted when the module is successfully registered.
    event ModuleRegistered();

    /// @notice The module registry instance.
    IModuleRegistry public immutable MODULE_REGISTRY;

    /**
     * @dev Initializes the contract by setting the module registry address.
     * @param moduleRegistry The address of the module registry.
     */
    constructor(address moduleRegistry) {
        MODULE_REGISTRY = IModuleRegistry(moduleRegistry);
    }

    /**
     * @inheritdoc ILensModuleRegistrant
     * @dev Checks if the module is already registered in the module registry.
     * @return True if the module is already registered, false otherwise.
     */
    function isRegistered() public view override returns (bool) {
        return MODULE_REGISTRY.isModuleRegistered(address(this));
    }

    function isRegisteredErc20(address currencyAddress) public view override returns (bool){
        return MODULE_REGISTRY.isErc20CurrencyRegistered(currencyAddress);
    }

    function _registerErc20Currency(
        address currencyAddress
    ) internal returns (bool) {
        if (isRegisteredErc20(currencyAddress)) {
            return true;
        }

        bool registered = MODULE_REGISTRY.registerErc20Currency(
            currencyAddress
        );
        return registered;
    }

    /**
     * @notice Registers the module in the module registry.
     * @dev Internal function to register the module with the given type.
     * @param type_ The type of the module.
     * @return Returns true if the module was successfully registered, false otherwise.
     */
    function _registerModule(Types.ModuleType type_) internal returns (bool) {
        if (isRegistered()) {
            return true;
        }

        bool registered = MODULE_REGISTRY.registerModule(
            address(this),
            uint256(type_)
        );

        if (registered) {
            emit ModuleRegistered();
        }

        return registered;
    }
}
