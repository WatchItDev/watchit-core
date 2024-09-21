// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";    
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// https://eips.ethereum.org/EIPS/eip-2612 - permit
// https://eips.ethereum.org/EIPS/eip-1363 - payable
contract MMC is ERC20, ERC20Permit, ERC20Burnable, ERC20Votes {
    constructor() ERC20("Watchit", "MMC") ERC20Permit("Watchit") {}

    /**
     * @inheritdoc IERC20Permit
     */
    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /**
     * @inheritdoc ERC20
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        return super._update(from, to, value);
    }
}
