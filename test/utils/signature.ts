import { getMessage } from 'eip-712';
import { Signature, Wallet, Signer, utils } from 'ethers';

import { abi as AxelarSeaProjectRegistryABI } from '../../artifacts/contracts/mint/AxelarSeaProjectRegistry.sol/AxelarSeaProjectRegistry.json';

export interface SignatureWithFunctionSignature {
  operatorAddress: string;
  signature: string;
  functionSignature: string;
  nonce: string;
}

export interface DeployNftParameters {
  template: string;
  owner: string;
  collectionId: string;
  projectId: string;
  exclusiveLevel: number;
  maxSupply: number;
  name: string;
  symbol: string;
}

export interface DeployNftWithMinterParameters extends DeployNftParameters {
  minterTemplate: string;
  data: string;
}

export async function generateSignature(privateKey: string, contractAddress: string, name: string, functionSignature: string, chainId: string | number): Promise<SignatureWithFunctionSignature> {
  const wallet = new Wallet(privateKey);
  const account = await wallet.getAddress();

  // console.log('Contract Address', contractAddress);
  // console.log('Account', account);
  // console.log('Function Signature', functionSignature);

  // try to gather a signature for permission
  const nonce = Date.now().toString() + Math.floor(Math.random() * 1000).toString();

  const EIP712Domain = [
    { name: 'name', type: 'string' },
    { name: 'version', type: 'string' },
    { name: 'chainId', type: 'uint256' },
    { name: 'verifyingContract', type: 'address' },
  ]

  const domain = {
    name: name,
    version: '1',
    chainId,
    verifyingContract: contractAddress,
  }

  const MetaTransaction = [
    { name: 'nonce', type: 'uint256' },
    { name: 'from', type: 'address' },
    { name: 'functionSignature', type: 'bytes' },
  ]
  const message = {
    nonce,
    from: account,
    functionSignature
  }
  const typedData = {
    types: {
      EIP712Domain,
      MetaTransaction,
    },
    domain,
    primaryType: 'MetaTransaction',
    message,
  }

  // Get a signable message from the typed data
  const signingKey = new utils.SigningKey(privateKey);
  const typedMessage = getMessage(typedData, true);
  let signature = signingKey.signDigest(typedMessage);

  return {
    operatorAddress: account,
    signature: signature.compact,
    functionSignature: functionSignature,
    nonce: nonce,
  }
}

export async function generateNewProjectSignature(privateKey: string, contractAddress: string, chainId: string | number, owner: string, projectId: string): Promise<SignatureWithFunctionSignature> {
  let iface = new utils.Interface(AxelarSeaProjectRegistryABI);
  const functionSignature = iface.encodeFunctionData("newProject", [ owner, projectId ])
  return await generateSignature(privateKey, contractAddress, "AxelarSeaProjectRegistry", functionSignature, chainId);
}

export async function generateDeployNftSignature(privateKey: string, contractAddress: string, chainId: string | number, params: DeployNftParameters): Promise<SignatureWithFunctionSignature> {
  let iface = new utils.Interface(AxelarSeaProjectRegistryABI);
  const functionSignature = iface.encodeFunctionData("deployNft", [
    params.template,
    params.owner,
    params.collectionId,
    params.projectId,
    params.exclusiveLevel,
    params.maxSupply,
    params.name,
    params.symbol,
  ])
  return await generateSignature(privateKey, contractAddress, "AxelarSeaProjectRegistry", functionSignature, chainId);
}

export async function generateDeployNftWithMinterSignature(privateKey: string, contractAddress: string, chainId: string | number, params: DeployNftWithMinterParameters): Promise<SignatureWithFunctionSignature> {
  let iface = new utils.Interface(AxelarSeaProjectRegistryABI);
  const functionSignature = iface.encodeFunctionData("deployNftWithMinter", [
    params.template,
    params.minterTemplate,
    params.owner,
    params.collectionId,
    params.projectId,
    params.exclusiveLevel,
    params.maxSupply,
    params.name,
    params.symbol,
    params.data,
  ])
  return await generateSignature(privateKey, contractAddress, "AxelarSeaProjectRegistry", functionSignature, chainId);
}
