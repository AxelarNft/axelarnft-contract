import { ethers } from "ethers";

export interface MinterPriceDetail {
  mintPriceStart: number;
  mintPriceEnd: number;
  mintPriceStep: number;
  mintStart: number;
  mintEnd: number;
  mintTokenAddress: string;
}

export interface MerkleMinterData extends MinterPriceDetail {
  merkleRoot: string;
}

export function merkleMinterData(data: MerkleMinterData) {
  return ethers.utils.AbiCoder.prototype.encode(
    [
      "bytes32",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
      "address",
    ],
    [
      data.merkleRoot,
      data.mintPriceStart,
      data.mintPriceEnd,
      data.mintPriceStep,
      data.mintStart,
      data.mintEnd,
      data.mintTokenAddress,
    ]
  );
}