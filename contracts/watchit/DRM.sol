// SPDX-License-Identifier: MIT
// NatSpec format convention - https://docs.soliditylang.org/en/v0.5.10/natspec-format.html
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/types/Time.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IDistributor.sol";
import "./Syndication.sol";

/// @title Digital Rights Manager
/// @notice This contract manages digital rights, allowing content holders to set prices, rent content, and manage access.
/// @dev This contract uses the UUPS upgradeable pattern and is initialized using the `initialize` function.
contract DigitalRightsManager is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    // @notice Emitted when distribution rights are granted to a distributor.
    /// @param hashCid The content hash identifier.
    /// @param distributor The distributor contract address.
    event RightsGranted(uint256 hashCid, IDistributor indexed distributor);

    // Mapping to store the private content ID for each registered content hash
    mapping(uint256 cidHash => uint256 privateCid) private vault;
    /// mapping to record the current content custody contract.
    mapping(uint256 => IDistributor) private custodying;
    // Mapping to store the access control list for each watcher and content hash
    mapping(address watcher => mapping(uint256 cidHash => uint256 timeframe))
        private acl;

    // Private instance of the Ownership contract
    IERC721 private ownership;
    // Private instance of the Syndication contract
    Syndication private syndication;

    /// @dev Error that is thrown when a restricted access to the holder is attempted.
    error ResitrictedAccessToHolder();
    /// @dev Error that is thrown when a content hash is already registered.
    error AlreadyRegisteredHash();
    error MissingOrNotRegisteredHash();
    error InvalidInactiveDistributor();

    /// @dev Constructor that disables initializers to prevent the implementation contract from being initialized.
    /// https://forum.openzeppelin.com/t/uupsupgradeable-vulnerability-post-mortem/15680
    /// https://forum.openzeppelin.com/t/what-does-disableinitializers-function-mean/28730/5
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract with the given dependencies.
    /// @param _ownership The Ownership contract instance.
    /// @param _syndication The Syndication contract instance.
    function initialize(
        IERC721 _ownership,
        Syndication _syndication
    ) public initializer {
        __Ownable_init(_msgSender());
        __UUPSUpgradeable_init();

        // TODO este contrato puede ser un registry contract para obtener el ERC721 con el que se quiere verificar la propiedad
        // eg: lens: contract address, x: contract address
        ownership = _ownership;
        syndication = _syndication;
    }

    /// @dev Upgrades the contract version.
    /// @notice Only the admin can upgrade the contract.
    /// @param newImplementation The address of the new implementation contract.
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    /// @notice Modifier to restrict access to the holder only.
    /// @param cidHash The content hash to give distribution rights.
    modifier holderOnly(uint256 cidHash) {
        if (ownership.ownerOf(cidHash) != _msgSender())
            revert ResitrictedAccessToHolder();
        _;
    }

    /// @notice Modifier to check if the distributor is active and not blocked.
    /// @param distributor The distributor address to check.
    modifier activeOnly(IDistributor distributor) {
        // TODO En el registro de película en drm el creador debe pasar los token con los desea pagar Y validar si el distribuidor los acepta
        if (!syndication.isActive(distributor))
            revert InvalidInactiveDistributor();

        _;
    }

    /// @notice Modifier to restrict access to unregistered content only.
    /// @param cidHash The content hash to check registration.
    modifier notRegisteredOnly(uint256 cidHash) {
        if (vault[cidHash] > 0) revert AlreadyRegisteredHash();
        _;
    }

    /// @notice Modifier to restrict access to registered content only.
    /// @param cidHash The content hash to check registration.
    modifier registeredOnly(uint256 cidHash) {
        if (vault[cidHash] != 0) revert MissingOrNotRegisteredHash();
        _;
    }

    // /// @notice Registers a new content with a private content id and hash.
    // /// @param cidHash The content hash to register.
    // /// @param privateCid The private content ID to register.
    // function registerContent(
    //     uint256 cidHash,
    //     uint256 privateCid
    // ) public notRegisteredOnly(cidHash) {
    //     vault[cidHash] = privateCid;
    // }

    // // TODO
    // function granContentAccess(
    //     address watcher,
    //     uint256 cidHash,
    //     uint256 timeframe
    // ) public registeredOnly(cidHash) {
    //     acl[watcher][cidHash] = block.timestamp + timeframe;
    // }

    /// @notice Checks if access is allowed for a specific watcher and content.
    /// @param watcher The address of the watcher.
    /// @param cidHash The content hash to check access for.
    /// @return True if access is allowed, false otherwise.
    function hasContentAccess(
        address watcher,
        uint256 cidHash
    ) public view returns (bool) {
        return acl[watcher][cidHash] <= Time.timestamp();
    }

    // this is where the fees are routed
    function getCustodial(
        uint256 cidHash
    ) public view registeredOnly(cidHash) returns (IDistributor) {
        return custodying[cidHash];
    }

    /// @notice Assigns distribution rights over the content.
    /// @dev The distributor must be active.
    /// @param distributor The distributor address to assign the content to.
    /// @param cidHash The content hash to give distribution rights.
    function grantDistributionRights(
        IDistributor distributor,
        uint256 cidHash
    )
        public
        holderOnly(cidHash)
        registeredOnly(cidHash)
        activeOnly(distributor)
    {
        // replace or create a new custodian
        // TODO un pure function que retorne el decripted text basado en el shared key y texto
        // TODO una pure function que calcule un shared key basado en los parametros
        custodying[cidHash] = distributor;
        emit RightsGranted(cidHash, distributor);
    }
}
