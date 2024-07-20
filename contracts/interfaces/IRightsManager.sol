// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasury.sol";
import "./ITreasurer.sol";
import "./IOwnership.sol";
import "./IRightsCustodial.sol";
import "./IContentVault.sol";

interface IRightsManager is
    IOwnership,
    ITreasury,
    ITreasurer,
    IRightsCustodial,
    IContentVault
{}
