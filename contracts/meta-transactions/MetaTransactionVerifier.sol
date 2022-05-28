// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {EIP712Base} from "./EIP712Base.sol";

contract MetaTransactionVerifier is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(uint256 => bool) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    modifier verifyMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        uint256 nonce,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) {
        require(!nonces[nonce], "Already run");

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonce,
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            _verifyMetaTransaction(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // mark nonce to prevent tx reuse
        nonces[nonce] = true;

        _;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function _verifyMetaTransaction(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}