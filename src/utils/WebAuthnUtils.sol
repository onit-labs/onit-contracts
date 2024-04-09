// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// fix this import with a better remapping
import {Base64Url} from "../../lib/webauthn-sol/lib/FreshCryptoLib/solidity/src/utils/Base64Url.sol";

struct WebAuthnInfo {
    bytes authenticatorData;
    string clientDataJSON;
    bytes32 messageHash;
}

/// @author modified from Base (https://github.com/base-org/webauthn-sol/test/Utils.sol)
library WebAuthnUtils {
    function getWebAuthnStruct(
        bytes32 challenge,
        bytes memory authenticatorData,
        string memory origin
    ) public pure returns (WebAuthnInfo memory) {
        string memory challengeb64url = Base64Url.encode(abi.encode(challenge));
        string memory clientDataJSON = string(
            abi.encodePacked(
                '{"type":"webauthn.get","challenge":"',
                challengeb64url,
                '","origin":"',
                origin,
                '","crossOrigin":false}'
            )
        );

        bytes32 clientDataJSONHash = sha256(bytes(clientDataJSON));
        bytes32 messageHash = sha256(abi.encodePacked(authenticatorData, clientDataJSONHash));

        return WebAuthnInfo(authenticatorData, clientDataJSON, messageHash);
    }
}
