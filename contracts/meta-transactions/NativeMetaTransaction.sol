// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {MetaTransactionVerifier} from "./MetaTransactionVerifier.sol";
import "../lib/RevertReason.sol";

contract NativeMetaTransaction is MetaTransactionVerifier {
    function executeMetaTransaction(
        address userAddress,
        uint256 nonce,
        bytes calldata functionSignature,
        bytes calldata signature
    ) public payable returns (bytes memory) {
        verifyMetaTransaction(userAddress, nonce, functionSignature, signature);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        // require(success, "Function call not successful");

        if (!success) {
            RevertReason.revertWithReasonIfOneIsReturned();
            revert("Function call not successful");
        }

        return returnData;
    }
}