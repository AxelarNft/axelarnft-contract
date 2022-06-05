/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
const {
  constants,
  utils: { parseEther, keccak256, toUtf8Bytes, recoverAddress },
  Contract,
} = require("ethers");
const { ethers } = require("hardhat");
const { faucet, whileImpersonating } = require("./utils/impersonate");
const { deployContract } = require("./utils/contracts");
const { merkleTree } = require("./utils/criteria");
const deployConstants = require("../constants/constants");
const {
  randomHex,
  random128,
  toAddress,
  toKey,
  convertSignatureToEIP2098,
  getBasicOrderParameters,
  getOfferOrConsiderationItem,
  getItemETH,
  toBN,
  randomBN,
} = require("./utils/encoding");
const { randomInt } = require("crypto");
const { getCreate2Address } = require("ethers/lib/utils");
const { tokensFixture } = require("./utils/fixtures");