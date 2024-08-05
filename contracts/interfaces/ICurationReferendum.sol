// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./IReferendum.sol";
import "./IReferendumVerifiable.sol";
import "./IReferendumRoleManager.sol";

interface ICurationReferendum is
    IReferendum,
    IReferendumVerifiable,
    IReferendumRoleManager
{}
