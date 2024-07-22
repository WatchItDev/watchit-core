// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ITreasury.sol";
import "./ITreasurer.sol";
import "./IRightsOwnership.sol";
import "./IRightsCustodial.sol";
import "./IRightsAccessController.sol";
import "./IContentVault.sol";

interface IRightsManager is
    ITreasury,
    ITreasurer,
    IContentVault,
    IRightsOwnership,
    IRightsCustodial,
    IRightsAccessController
{}
