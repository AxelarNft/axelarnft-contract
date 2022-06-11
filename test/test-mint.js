/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
const {
  constants,
  utils: { parseEther, keccak256, toUtf8Bytes },
  Contract,
} = require("ethers");
const { ethers, network } = require("hardhat");
const { faucet, whileImpersonating } = require("./utils/impersonate");
const { merkleTreeForMint, merkleKeyForMint } = require("./utils/merkle");
const {
  randomHex,
  random128,
  toAddress,
  toKey,
  convertSignatureToEIP2098,
  getBasicOrderParameters,
  getItemETH,
  toBN,
  randomBN,
  toFulfillment,
  toFulfillmentComponents,
  getBasicOrderExecutions,
  buildResolver,
  buildOrderStatus,
  defaultBuyNowMirrorFulfillment,
  defaultAcceptOfferMirrorFulfillment,
} = require("./utils/encoding");
const { randomInt } = require("crypto");
const {
  fixtureERC20,
  fixtureERC721,
  fixtureERC1155,
  seaportFixture,
} = require("./utils/fixtures");
const { deployContract } = require("./utils/contracts");
const { testPermission } = require("./utils/permission");
const { getBlockTimestamp } = require("./utils/blockTimestamp");

const wait = ms => new Promise(resolve => setTimeout(resolve, ms))

const ONLYOWNER_REVERT = "Ownable: caller is not the owner";

describe(`AxelarSea — initial test suite`, function () {
  const provider = ethers.provider;
  let zone;
  let marketplaceContract;
  let testERC20;
  let testERC721;
  let testERC1155;
  let testERC1155Two;
  let owner;
  let withBalanceChecks;
  let EIP1271WalletFactory;
  let reenterer;
  let stubZone;
  let conduitController;
  let conduitImplementation;
  let conduitOne;
  let conduitKeyOne;
  let directMarketplaceContract;
  let mintAndApproveERC20;
  let getTestItem20;
  let set721ApprovalForAll;
  let mint721;
  let mint721s;
  let mintAndApprove721;
  let getTestItem721;
  let getTestItem721WithCriteria;
  let set1155ApprovalForAll;
  let mint1155;
  let mintAndApprove1155;
  let getTestItem1155WithCriteria;
  let getTestItem1155;
  let deployNewConduit;
  let createTransferWithApproval;
  let createOrder;
  let createMirrorBuyNowOrder;
  let createMirrorAcceptOfferOrder;
  let checkExpectedEvents;

  let chainId;
  let someone;

  let projectRegistry;
  let nft721template;

  async function deployNft(
    {
      template,
      minterTemplate,
      owner,
      collectionId,
      projectId,
      exclusiveLevel,
      maxSupply,
      name,
      symbol,
      data,
    }
  ) {
    if (minterTemplate) {
      let nftAddress = await projectRegistry.callStatic.deployNftWithMinter(
        template,
        minterTemplate,
        owner,
        collectionId,
        projectId,
        exclusiveLevel,
        maxSupply,
        name,
        symbol,
        data
      );
      await projectRegistry.deployNftWithMinter(
        template,
        minterTemplate,
        owner,
        collectionId,
        projectId,
        exclusiveLevel,
        maxSupply,
        name,
        symbol,
        data
      ).then(tx => tx.wait());

      const nftFactory = await ethers.getContractFactory("AxelarSeaNft721Enumerable", owner);
      const minterFactory = await ethers.getContractFactory("AxelarSeaNftMerkleMinter", owner);
      return [await nftFactory.attach(nftAddress.nft), await minterFactory.attach(nftAddress.minter)];
    } else {
      let nftAddress = await projectRegistry.callStatic.deployNft(
        template,
        owner,
        collectionId,
        projectId,
        exclusiveLevel,
        maxSupply,
        name,
        symbol
      );
      await projectRegistry.deployNft(
        template,
        owner,
        collectionId,
        projectId,
        exclusiveLevel,
        maxSupply,
        name,
        symbol
      ).then(tx => tx.wait());

      const factory = await ethers.getContractFactory("AxelarSeaNft721Enumerable", owner);
      return await factory.attach(nftAddress);
    }
  }

  async function deployMinter(nft, owner, minterTemplate, data) {
    let minterAddress = await nft.connect(owner).callStatic.deployMinter(
      minterTemplate,
      data
    );
    await nft.connect(owner).deployMinter(
      minterTemplate,
      data
    ).then(tx => tx.wait());

    const minterFactory = await ethers.getContractFactory("AxelarSeaNftMerkleMinter", owner);
    return await minterFactory.attach(minterAddress);
  }

  // Deploy contracts
  before(async () => {
    const network = await provider.getNetwork();

    chainId = network.chainId;

    owner = new ethers.Wallet(randomHex(32), provider);
    someone = new ethers.Wallet(randomHex(32), provider);

    await Promise.all(
      [owner].map((wallet) => faucet(wallet.address, provider))
    );

    projectRegistry = await deployContract("AxelarSeaProjectRegistry", owner);
    nft721template = await deployContract("AxelarSeaNft721Enumerable", owner);
    nftMerkleMinterTemplate = await deployContract("AxelarSeaNftMerkleMinter", owner);

    ({
      EIP1271WalletFactory,
      reenterer,
      conduitController,
      conduitImplementation,
      conduitKeyOne,
      conduitOne,
      deployNewConduit,
      testERC20,
      mintAndApproveERC20,
      getTestItem20,
      testERC721,
      set721ApprovalForAll,
      mint721,
      mint721s,
      mintAndApprove721,
      getTestItem721,
      getTestItem721WithCriteria,
      testERC1155,
      set1155ApprovalForAll,
      mint1155,
      mintAndApprove1155,
      getTestItem1155WithCriteria,
      getTestItem1155,
      testERC1155Two,
      createTransferWithApproval,
      marketplaceContract,
      directMarketplaceContract,
      stubZone,
      createOrder,
      createMirrorBuyNowOrder,
      createMirrorAcceptOfferOrder,
      withBalanceChecks,
      checkExpectedEvents,
    } = await seaportFixture(owner));
  });

  // NFT Drop / Minting test cases
  describe('NFT Drop / Minting', function () {
    let feeAddress;
    let operator;
    let projectOwner;
    let projectNewOwner;
    let projectMember;
    let projectMember2;

    // let collectionOwner;

    let minter;
    let claimable1;
    let claimable2;
    let claimable3;

    before(async () => {
      feeAddress = new ethers.Wallet(randomHex(32), provider);
      operator = new ethers.Wallet(randomHex(32), provider);
      projectOwner = new ethers.Wallet(randomHex(32), provider);
      projectNewOwner = new ethers.Wallet(randomHex(32), provider);
      projectMember = new ethers.Wallet(randomHex(32), provider);
      projectMember2 = new ethers.Wallet(randomHex(32), provider);

      // collectionOwner = new ethers.Wallet(randomHex(32), provider);

      minter = new ethers.Wallet(randomHex(32), provider);
      claimable1 = new ethers.Wallet(randomHex(32), provider);
      claimable2 = new ethers.Wallet(randomHex(32), provider);
      claimable3 = new ethers.Wallet(randomHex(32), provider);

      await Promise.all(
        [
          feeAddress,
          operator,
          projectOwner,
          projectNewOwner,
          projectMember,
          projectMember2,
          // collectionOwner,
          minter,
          claimable1,
          claimable2,
          claimable3,
        ].map((wallet) => faucet(wallet.address, provider))
      );
    })

    it('Should be able to set template', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nft721template.address, true)
    })

    it('Should be able to set minter template', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftMerkleMinterTemplate.address, true)
    })

    // 2% fee
    it('Should be able to set mint fee', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setMintFee',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, feeAddress.address, ethers.utils.parseEther("0.02"))
    })

    it('Should be able to set operator', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setOperator',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, operator.address, true)
    })

    it('Should be able to set axelarSea contract', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setAxelarSeaContract',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nft721template.address, true)
    })

    it('Should be able to create new project', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'newProject',
        authorized: operator,
        unauthorized: owner,
        revertMessage: "Not Operator",
      }, projectOwner.address, ethers.utils.hexZeroPad('0x1234', 32))

      await testPermission({
        contract: projectRegistry,
        fn: 'newProject',
        authorized: operator,
        unauthorized: someone,
        revertMessage: "Not Operator",
      }, projectOwner.address, ethers.utils.hexZeroPad('0x2345', 32))
    })

    it('Should be able to setProjectMember / Owner', async () => {
      // Project not exists
      expect(projectRegistry.connect(projectOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2346', 32), projectMember.address, 1))
        .to.be.revertedWith("Forbidden")

      // Not project admin
      expect(projectRegistry.connect(owner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectMember.address, 1))
        .to.be.revertedWith("Forbidden")

      // Assign member
      await projectRegistry.connect(projectOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectMember.address, 1);

      // Invalid level
      expect(projectRegistry.connect(projectOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectMember.address, 3))
        .to.be.revertedWith("Forbidden")

      // Member cannot add new member
      expect(projectRegistry.connect(projectMember)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectMember.address, 1))
        .to.be.revertedWith("Forbidden")

      // Assign owner
      await projectRegistry.connect(projectOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectNewOwner.address, 2);

      // New owner assign new member
      await projectRegistry.connect(projectNewOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectMember2.address, 1);

      // Cannot remove official owner
      expect(projectRegistry.connect(projectNewOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectOwner.address, 0))
        .to.be.revertedWith("Forbidden")

      // Transfer ownership
      await projectRegistry.connect(projectOwner)
        .setProjectOwner(ethers.utils.hexZeroPad('0x2345', 32), projectNewOwner.address);

      // Remove old owner
      await projectRegistry.connect(projectNewOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), projectOwner.address, 0);

      // Removed owner cannot assign new member anymore
      expect(projectRegistry.connect(projectOwner)
        .setProjectMember(ethers.utils.hexZeroPad('0x2345', 32), someone.address, 1))
        .to.be.revertedWith("Forbidden")
    })

    describe('Basic minting', async () => {
      let nft1, minter1;
      let nft2, minter2;
      let nft3, minter3;
      let merkleTree;
      
      it('Should be able to deploy NFT', async () => {
        let blockTimestamp = await getBlockTimestamp()
        
        merkleTree = merkleTreeForMint([claimable1.address, claimable2.address, claimable3.address], [1, 3, 1])

        console.log('ROOT', merkleTree.getHexRoot())
        console.log(merkleTree.toString())
  
        const packedParameter = ethers.utils.AbiCoder.prototype.encode(
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
            merkleTree.getHexRoot(),
            ethers.utils.parseEther("10"),
            ethers.utils.parseEther("5"),
            ethers.utils.parseEther("0.01"),
            blockTimestamp + 1000,
            blockTimestamp + 2000,
            testERC20.address,
          ]
        );

        const packedParameter2 = ethers.utils.AbiCoder.prototype.encode(
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
            merkleTree.getHexRoot(),
            ethers.utils.parseEther("10"),
            ethers.utils.parseEther("10"),
            ethers.utils.parseEther("0"),
            blockTimestamp + 1000,
            blockTimestamp + 2000,
            testERC20.address,
          ]
        );
  
        const collectionId1 = ethers.utils.hexZeroPad('0x111101', 32);
        // const collectionId2 = ethers.utils.hexZeroPad('0x111102', 32);
        // const collectionId3 = ethers.utils.hexZeroPad('0x111103', 32);
        // const collectionId4 = ethers.utils.hexZeroPad('0x111104', 32);
        const projectId = ethers.utils.hexZeroPad('0x1234', 32);

        // console.log(packedParameter)
  
        let deployment1 = await deployNft({
          template: nft721template.address,
          minterTemplate: nftMerkleMinterTemplate.address,
          owner: projectOwner.address,
          collectionId: collectionId1,
          projectId: projectId,
          exclusiveLevel: 0,
          maxSupply: 100,
          name: "Test 1",
          symbol: "TEST1",
          data: packedParameter,
        });

        nft1 = deployment1[0];
        minter1 = deployment1[1];

        nft2 = await deployNft({
          template: nft721template.address,
          owner: projectOwner.address,
          collectionId: collectionId1,
          projectId: projectId,
          exclusiveLevel: 2,
          maxSupply: 100,
          name: "Test 2",
          symbol: "TEST2",
        });

        minter2 = await deployMinter(
          nft2,
          projectOwner,
          nftMerkleMinterTemplate.address,
          packedParameter2,
        )
  
        console.log(nft1.address, minter1.address)
        console.log(nft2.address, minter2.address)
      })

      it('Should be able to mint', async () => {
        await mintAndApproveERC20(claimable1, minter1.address, ethers.utils.parseEther("10000"));
        await mintAndApproveERC20(claimable2, minter2.address, ethers.utils.parseEther("10000"));
        // await mintAndApproveERC20(claimable3, minter3.address, ethers.utils.parseEther("10000"));

        console.log(merkleKeyForMint(claimable1.address, 1))

        let proof1 = merkleTree.getHexProof(merkleKeyForMint(claimable1.address, 1))
        let proof2 = merkleTree.getHexProof(merkleKeyForMint(claimable2.address, 3))

        // expect(minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1)).to.be.revertedWith("NotMintingTime")

        await network.provider.send("evm_increaseTime", [1010]);
        await network.provider.send("evm_mine");

        console.log(proof1)

        await wait(3000); // Fix unknown bug

        await minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1).then(tx => tx.wait())
      })
    })
  })
});