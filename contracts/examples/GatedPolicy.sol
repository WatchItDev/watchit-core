// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "./IPolicy.sol";
import "./Types.sol";
import "./RightsManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; // Para manejar tokens ERC20
import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Para manejar NFTs (ERC721)

contract GatedContentPolicy is IPolicy {
    struct Content {
        address gateToken; // Dirección del token requerido para acceder al contenido
        uint256 tokenIdOrAmount; // Para ERC721 sería el tokenId, para ERC20 sería la cantidad mínima requerida
        bool isERC721; // Indica si es un ERC721 (true) o ERC20 (false)
        uint256 feeAmount; // Cantidad de fees que se deben pagar
        address feeCurrency; // Moneda en la que se paga la fee (puede ser address(0) para ETH)
    }

    mapping(uint256 => Content) public contents; // Contenidos identificados por contentId
    RightsManager public rightsManager;

    constructor(address _rightsManager) {
        rightsManager = RightsManager(_rightsManager);
    }

    // Función que retorna el nombre de la política
    function name() external pure override returns (string memory) {
        return "GatedContentPolicy";
    }

    // Registrar un nuevo contenido con restricción de acceso y fees
    function registerContent(
        uint256 contentId,
        address gateToken,
        uint256 tokenIdOrAmount,
        bool isERC721,
        uint256 feeAmount,
        address feeCurrency,
        address account
    ) external {
        contents[contentId] = Content(gateToken, tokenIdOrAmount, isERC721, feeAmount, feeCurrency);
        // Manejar las fees si se requiere (solo si el feeCurrency no es ETH)
        if (feeCurrency != address(0)) {
            IERC20(feeCurrency).transferFrom(account, address(this), feeAmount);
            IERC20(feeCurrency).approve(address(rightsManager), feeAmount);
        }

        // Registrar la política en el RightsManager
        rightsManager.registerPolicy{value: feeCurrency == address(0) ? feeAmount : 0}(contentId, account);

    }

    // Retorna los términos de acceso para un usuario y un contenido
    function terms(address account, uint256 contentId) external view override returns (bytes memory) {
        return abi.encode(contents[contentId]);
    }

    // Verifica si el usuario cumple con las condiciones de acceso (ya registrado)
    function comply(address account, uint256 contentId) external view override returns (bool) {
        // Verificar si el usuario cumple con las condiciones de acceso
        bool hasAccess;
        if (isERC721) {
            hasAccess = IERC721(gateToken).ownerOf(tokenIdOrAmount) == account;
        } else {
            hasAccess = IERC20(gateToken).balanceOf(account) >= tokenIdOrAmount;
        }

        return hasAccess;
    }

    // Define cómo se manejarán los pagos de fees y cómo se distribuyen
    function payouts(address account, uint256 contentId) external view override returns (T.Payouts memory) {
        T.Payouts memory payout;
        payout.t9n.amount = contents[contentId].feeAmount; // Fee del contenido
        payout.t9n.currency = contents[contentId].feeCurrency; // Moneda en la que se maneja el fee
        payout.s4s = new T.Share ;
        payout.s4s[0] = T.Share({account: 0xCreatorAddress, value: 70}); // 70% al creador
        payout.s4s[1] = T.Share({account: 0xPlatformAddress, value: 30}); // 30% a la plataforma
        return payout;
    }
}
