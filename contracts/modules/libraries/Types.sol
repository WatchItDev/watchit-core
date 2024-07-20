// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @title Types
 * @author Lens Protocol
 *
 * @notice A standard library of data types used throughout the Lens Protocol.
 */
library Types {
    enum ModuleType {
        __, // Just to avoid 0 as valid ModuleType
        PUBLICATION_ACTION_MODULE,
        REFERENCE_MODULE,
        FOLLOW_MODULE
    }

    struct RentPrice {
        address currency; // the currency
        uint256 price; // price per day
    }

    struct RentParams {
        bytes secured; // secured content
        uint256 contentId; // content id 2hash
        address distributor; // initial distributor
        RentPrice[] rentPrices;
    }

    /**
     * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
     *
     * @param Nonexistent An indicator showing the queried publication does not exist.
     * @param Post A standard post, having an URI, action modules and no pointer to another publication.
     * @param Comment A comment, having an URI, action modules and a pointer to another publication.
     * @param Mirror A mirror, having a pointer to another publication, but no URI or action modules.
     * @param Quote A quote, having an URI, action modules, and a pointer to another publication.
     */
    enum PublicationType {
        Nonexistent,
        Post,
        Comment,
        Mirror,
        Quote
    }

    struct ProcessActionParams {
        uint256 publicationActedProfileId;
        uint256 publicationActedId;
        uint256 actorProfileId;
        address actorProfileOwner;
        address transactionExecutor;
        uint256[] referrerProfileIds;
        uint256[] referrerPubIds;
        Types.PublicationType[] referrerPubTypes;
        bytes actionModuleData;
    }
}
