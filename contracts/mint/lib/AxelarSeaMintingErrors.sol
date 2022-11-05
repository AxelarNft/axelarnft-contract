//SPDX-License-Identifier: None
pragma solidity >=0.8.7;

error InvalidTemplate(address template);
error Forbidden();
error NotMintingTime();
error MintPerWalletLimited(uint256 maxAmount);
error SupplyLimited();
error NotWhitelisted();
error TransferFailed();
error DuplicatedCollection(bytes32 collectionId);