// SPDX-License-Identifier UNLICENSED
pragma solidity ^0.8.13;

/* solhint-disable no-console */

import {Test} from "../../lib/forge-std/src/Test.sol";
import {Strings} from "../../lib/webauthn-sol/lib/openzeppelin-contracts/contracts/utils/Strings.sol";

/**
 * @notice - This contract runs the signatureHelper.ts script
 * 			 It is used to create and sign messages, similar to how the passkey would, for testing
 */
contract SignatureHelper is Test {
    function createPublicKey(string memory salt) public returns (uint256[2] memory) {
        string[] memory cmd = new string[](6);

        cmd[0] = "yarn";
        cmd[1] = "--silent";
        cmd[2] = "ts-node";
        cmd[3] = "script/signatureHelper.ts";
        cmd[4] = "generate";
        cmd[5] = salt;

        bytes memory res = vm.ffi(cmd);
        uint256[2] memory publicKey = abi.decode(res, (uint256[2]));

        return publicKey;
    }

    function signMessageForPublicKey(string memory salt, string memory message) public returns (uint256[2] memory) {
        string[] memory cmd = new string[](7);

        cmd[0] = "yarn";
        cmd[1] = "--silent";
        cmd[2] = "ts-node";
        cmd[3] = "script/signatureHelper.ts";
        cmd[4] = "sign";
        cmd[5] = salt;
        cmd[6] = message;

        bytes memory res = vm.ffi(cmd);
        uint256[2] memory sig = abi.decode(res, (uint256[2]));

        return sig;
    }
}
