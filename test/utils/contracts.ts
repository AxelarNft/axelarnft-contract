import { ethers } from "hardhat";
import { Contract } from "ethers";
import { JsonRpcSigner } from "@ethersproject/providers";
import { upgrades } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config();

export async function deployContract<C extends Contract>(
  name: string,
  signer: JsonRpcSigner,
  ...args: any[]
): Promise<C> {
  const references = new Map<string, string>([
    ["Consideration", "ReferenceConsideration"],
    ["Conduit", "ReferenceConduit"],
    ["ConduitController", "ReferenceConduitController"],
  ]);

  const nameWithReference =
    process.env.REFERENCE && references.has(name)
      ? references.get(name) || name
      : name;

  const f = await ethers.getContractFactory(nameWithReference, signer);
  const c = await f.deploy(...args);
  return c as C;
}

export async function deployUpgradeable(contractName: string, ...args: any[]) {
  const Contract = await ethers.getContractFactory(contractName);
  const contract = await upgrades.deployProxy(Contract, args, { initializer: 'initialize' });
  console.log(contractName, " deployed to:", contract.address);
  return contract;
}
