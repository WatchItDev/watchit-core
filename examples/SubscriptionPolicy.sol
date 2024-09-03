// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IPolicy.sol";
import "./Types.sol";
import "./RightsManager.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SubscriptionPolicy is IPolicy {
    struct Package {
        bytes32 merkleRoot; // Raíz de Merkle que representa los contentIds
        uint256 subscriptionDuration; // Duración de la suscripción en segundos
        uint256 price; // Precio de la suscripción
    }

    mapping(uint256 => Package) public packages; // Paquetes identificados por packageId
    mapping(address => mapping(uint256 => uint256)) private subscriptions; // Subscripciones de los usuarios
    RightsManager public rightsManager;

    constructor(address _rightsManager) {
        rightsManager = RightsManager(_rightsManager);
    }

    // Función que retorna el nombre de la política
    function name() external pure override returns (string memory) {
        return "SubscriptionPolicy";
    }

    // Registrar un nuevo paquete de suscripción
    function registerPackage(
        uint256 packageId,
        bytes32 merkleRoot,
        uint256 subscriptionDuration,
        uint256 price
    ) external {
        packages[packageId] = Package(merkleRoot, subscriptionDuration, price);
    }

    // Función para que un usuario se suscriba a un paquete
    function subscribe(uint256 packageId) external payable {
        Package memory pkg = packages[packageId];
        require(pkg.subscriptionDuration > 0, "Package does not exist");
        require(msg.value >= pkg.price, "Insufficient funds for subscription");

        // Establece la suscripción del usuario
        subscriptions[msg.sender][packageId] = block.timestamp + pkg.subscriptionDuration;
        // Registra la política en el RightsManager para el paquete completo
        rightsManager.registerPolicy{value: msg.value}(packageId, msg.sender);
    }

    // Retorna los términos de acceso para un usuario y un contenido
    function terms(address account, uint256 contentId) external view override returns (bytes memory) {
        uint256 packageId = _findPackageForContent(account, contentId);
        uint256 expiration = subscriptions[account][packageId];
        bytes32 merkleRoot = packages[packageId].merkleRoot;
        return abi.encode(expiration, merkleRoot);
    }

    // Verifica si el usuario tiene una suscripción activa y si el contenido está en el paquete usando Merkle Proof
    function comply(bytes calldata terms) external view override returns (bool) {
        // uint256 packageId = _findPackageForContent(account, contentId);
        // uint256 expiration = subscriptions[account][packageId];
        // if (block.timestamp > expiration) {
        //     return false; // La suscripción ha expirado
        // }

        // // Verifica que el contentId esté en el Merkle Tree del paquete correspondiente usando Merkle Proof almacenado
        // bytes32 leaf = keccak256(abi.encodePacked(contentId));
        // return MerkleProof.verify(merckleProof, packages[packageId].merkleRoot, leaf);
    }

    // Encuentra el packageId para un contentId dado asociado a un usuario
    function _findPackageForContent(address account, uint256 contentId) internal view returns (uint256) {
        for (uint256 packageId = 0; packageId < packages.length; packageId++) {
            if (subscriptions[account][packageId] > 0) { // Verifica si el usuario está suscrito al paquete
                bytes32 leaf = keccak256(abi.encodePacked(contentId));
                if (MerkleProof.verify(userProofs[account][packageId], packages[packageId].merkleRoot, leaf)) {
                    return packageId;
                }
            }
        }
        revert("Content not found in any subscribed package");
    }

    // Define cómo se manejarán los pagos de suscripción
    function shares(address account, uint256 contentId) external view override returns (T.Shares[] memory) {

    }
}
