// import { HttpProvider } from "web3/providers";
// import { getMessage } from 'eip-712';
// import { Signature, utils } from 'ethers';
// import ERC20MetaMintable from "./ERC20MetaMintable"
// import ERC721MetaMintable from "./ERC721MetaMintable"
// import ERC1155MetaMintable from "./ERC1155MetaMintable"
// import web3, { privateKey } from "./web3"

// interface SignatureWithFunctionSignature extends Signature {
//   functionSignature: string;
// }

// export async function generateSignature(tokenAddress: string, functionSignature: string, chainId: string, ContractClass): Promise<SignatureWithFunctionSignature> {
//   const provider: HttpProvider = web3.currentProvider as any;
//   const account = web3.eth.defaultAccount;

//   // console.log('Token Address', tokenAddress);
//   // console.log('Account', account);
//   // console.log('Function Signature', functionSignature);

//   // try to gather a signature for permission
//   const token = await new ContractClass(tokenAddress, account);
//   const nonce = await token.getNonce(account);
//   // console.log(nonce)
//   const name = await token.name();
//   // console.log(name)

//   const EIP712Domain = [
//     { name: 'name', type: 'string' },
//     { name: 'version', type: 'string' },
//     { name: 'chainId', type: 'uint256' },
//     { name: 'verifyingContract', type: 'address' },
//   ]

//   const domain = {
//     name: name,
//     version: '1',
//     chainId,
//     verifyingContract: tokenAddress,
//   }

//   const MetaTransaction = [
//     { name: 'nonce', type: 'uint256' },
//     { name: 'from', type: 'address' },
//     { name: 'functionSignature', type: 'bytes' },
//   ]
//   const message = {
//     nonce,
//     from: account,
//     functionSignature
//   }
//   const typedData = {
//     types: {
//       EIP712Domain,
//       MetaTransaction,
//     },
//     domain,
//     primaryType: 'MetaTransaction',
//     message,
//   }

//   // Get a signable message from the typed data
//   const signingKey = new utils.SigningKey(privateKey);
//   const typedMessage = getMessage(typedData, true);
//   let signature = signingKey.signDigest(typedMessage);

//   return {
//     ...signature,
//     functionSignature: functionSignature,
//   }
// }

// export async function generateERC20MintSignature(tokenAddress, orderId, to, amount): Promise<{r: string, s: string, v: number}> {
//   const functionSignature = web3.eth.abi.encodeFunctionCall(
//     {
//       "inputs": [
//         {
//           "internalType": "uint256",
//           "name": "_orderId",
//           "type": "uint256"
//         },
//         {
//           "internalType": "address",
//           "name": "_to",
//           "type": "address"
//         },
//         {
//           "internalType": "uint256",
//           "name": "_amount",
//           "type": "uint256"
//         }
//       ],
//       "name": "metaMint",
//       "outputs": [],
//       "stateMutability": "nonpayable",
//       "type": "function"
//     },
//     [orderId, to, amount],
//   );

//   return await generateSignature(tokenAddress, functionSignature, ERC20MetaMintable);
// }

// export async function generateERC721MintSignature(tokenAddress, orderId, to, tokenId, data = ""): Promise<{r: string, s: string, v: number}> {
//   const functionSignature = web3.eth.abi.encodeFunctionCall(
//     {
//       "inputs": [
//         {
//           "internalType": "uint256",
//           "name": "_orderId",
//           "type": "uint256"
//         },
//         {
//           "internalType": "address",
//           "name": "_to",
//           "type": "address"
//         },
//         {
//           "internalType": "uint256",
//           "name": "_tokenId",
//           "type": "uint256"
//         },
//         {
//           "internalType": "bytes",
//           "name": "_data",
//           "type": "bytes"
//         }
//       ],
//       "name": "metaMint",
//       "outputs": [],
//       "stateMutability": "nonpayable",
//       "type": "function"
//     },
//     [orderId, to, tokenId, data],
//   );

//   return await generateSignature(tokenAddress, functionSignature, ERC721MetaMintable);
// }

// export async function generateERC1155MintSignature(tokenAddress, orderId, to, tokenId, amount, data = ""): Promise<{r: string, s: string, v: number}> {
//   const functionSignature = web3.eth.abi.encodeFunctionCall(
//     {
//       "inputs": [
//         {
//           "internalType": "uint256",
//           "name": "_orderId",
//           "type": "uint256"
//         },
//         {
//           "internalType": "address",
//           "name": "_to",
//           "type": "address"
//         },
//         {
//           "internalType": "uint256",
//           "name": "_tokenId",
//           "type": "uint256"
//         },
//         {
//           "internalType": "uint256",
//           "name": "_amount",
//           "type": "uint256"
//         },
//         {
//           "internalType": "bytes",
//           "name": "_data",
//           "type": "bytes"
//         }
//       ],
//       "name": "metaMint",
//       "outputs": [],
//       "stateMutability": "nonpayable",
//       "type": "function"
//     },
//     [orderId, to, tokenId, amount, data],
//   );

//   return await generateSignature(tokenAddress, functionSignature, ERC1155MetaMintable);
// }

// if (require.main === module) {
//   // Test generate signature
//   const tokenAddress = "0x06535983022EFef4dA4d2118a824D7Be69D4a672";
//   const to = "0x99d599b268066a04433265Eb71B3167bdd5f39A6";
//   generateERC20MintSignature(tokenAddress, to, "1000000000000000000", 3)
//     .then(x => console.log(x))
//     .catch(err => console.error(err));
// }