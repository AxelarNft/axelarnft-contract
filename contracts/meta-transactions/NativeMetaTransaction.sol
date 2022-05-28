// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {MetaTransactionVerifier} from "./MetaTransactionVerifier.sol";

contract NativeMetaTransaction is MetaTransactionVerifier {
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        uint256 nonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable verifyMetaTransaction(
        userAddress,
        functionSignature,
        nonce,
        sigR,
        sigS,
        sigV
    ) returns (bytes memory) {
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }
}