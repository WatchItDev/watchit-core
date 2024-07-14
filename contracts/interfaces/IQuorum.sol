// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;


import "./IRegistrable.sol";
import "./IRegistrableRevokable.sol";
import "./IRegistrableVerifiable.sol";


interface IQuorum is
    IRegistrable,
    IRegistrableRevokable,
    IRegistrableVerifiable
{

}
