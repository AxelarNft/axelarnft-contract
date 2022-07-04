/* eslint-disable no-unused-expressions */
const { expect } = require("chai");
const {
  constants,
  utils: { parseEther, keccak256, toUtf8Bytes },
  Contract,
} = require("ethers");
const { ethers, network, getChainId } = require("hardhat");
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
const {
  generateNewProjectSignature,
  generateDeployNftSignature,
  generateDeployNftWithMinterSignature,
} = require("./utils/signature");
const {
  merkleMinterData,
} = require("./utils/minterPayload");

const wait = ms => new Promise(resolve => setTimeout(resolve, ms))

const CHAIN_ID = 31337;
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
  let operator;

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
      let signature = await generateDeployNftWithMinterSignature(
        operator.privateKey, 
        projectRegistry.address, 
        CHAIN_ID, 
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
      )

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
        data,
      );

      await projectRegistry.connect(someone).executeMetaTransaction(
        operator.address,
        signature.functionSignature,
        signature.nonce,
        signature.r,
        signature.s,
        signature.v
      ).then(tx => tx.wait());

      const nftFactory = await ethers.getContractFactory("AxelarSeaNft721A", owner);
      const minterFactory = await ethers.getContractFactory("AxelarSeaNftMerkleMinter", owner);

      return [await nftFactory.attach(nftAddress.nft), await minterFactory.attach(nftAddress.minter)];
    } else {
      let signature = await generateDeployNftSignature(
        operator.privateKey, 
        projectRegistry.address, 
        CHAIN_ID, 
        {
          template,
          owner,
          collectionId,
          projectId,
          exclusiveLevel,
          maxSupply,
          name,
          symbol,
        }
      )

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
      await projectRegistry.connect(someone).executeMetaTransaction(
        operator.address,
        signature.functionSignature,
        signature.nonce,
        signature.r,
        signature.s,
        signature.v
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
    operator = new ethers.Wallet(randomHex(32), provider);

    await Promise.all(
      [owner, someone, operator].map((wallet) => faucet(wallet.address, provider))
    );

    projectRegistry = await deployContract("AxelarSeaProjectRegistry", owner);
    nft721template = await deployContract("AxelarSeaNft721A", owner);
    nftMerkleMinterTemplate = await deployContract("AxelarSeaNftMerkleMinter", owner);
    nftMerkleMinterNativeTemplate = await deployContract("AxelarSeaNftMerkleMinterNative", owner);
    nftPublicMinterTemplate = await deployContract("AxelarSeaNftPublicMinter", owner);
    nftPublicMinterNativeTemplate = await deployContract("AxelarSeaNftPublicMinterNative", owner);
    nftSignatureMinterTemplate = await deployContract("AxelarSeaNftSignatureMinter", owner);
    nftSignatureMinterNativeTemplate = await deployContract("AxelarSeaNftSignatureMinterNative", owner);

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
      // operator = new ethers.Wallet(randomHex(32), provider);
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
          // operator,
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

      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftMerkleMinterNativeTemplate.address, true)

      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftSignatureMinterTemplate.address, true)

      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftSignatureMinterNativeTemplate.address, true)

      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftPublicMinterTemplate.address, true)

      await testPermission({
        contract: projectRegistry,
        fn: 'setMinterTemplate',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, nftPublicMinterNativeTemplate.address, true)
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
      }, someone.address, true)
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

    it('Should be able to add owner as operator', async () => {
      await testPermission({
        contract: projectRegistry,
        fn: 'setOperator',
        authorized: owner,
        unauthorized: someone,
        revertMessage: ONLYOWNER_REVERT,
      }, owner.address, true)
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

    it('Should use meta transaction to add new project', async () => {
      const signature = await generateNewProjectSignature(operator.privateKey, projectRegistry.address, CHAIN_ID, projectOwner.address, ethers.utils.hexZeroPad('0x4444', 32))
      
      await projectRegistry.executeMetaTransaction(
        operator.address,
        signature.functionSignature,
        signature.nonce,
        signature.r,
        signature.s,
        signature.v
      );
    })

    describe('NFT minting with token', async () => {
      let nft1, minter1;
      let nft2, minter2;
      let nft3, minter3;
      let merkleTree;
      
      it('Should be able to deploy NFT', async () => {
        let blockTimestamp = await getBlockTimestamp()
        
        merkleTree = merkleTreeForMint([claimable1.address, claimable2.address, claimable3.address], [1, 3, 1])

        console.log('ROOT', merkleTree.getHexRoot())
        console.log(merkleTree.toString())

        const packedParameter = merkleMinterData({
          merkleRoot: merkleTree.getHexRoot(),
          mintPriceStart: ethers.utils.parseEther("10"),
          mintPriceEnd: ethers.utils.parseEther("4"),
          mintPriceStep: ethers.utils.parseEther("0.01"),
          mintStart: blockTimestamp + 1000,
          mintEnd: blockTimestamp + 2000,
          mintTokenAddress: testERC20.address,
        });

        const packedParameter2 = merkleMinterData({
          merkleRoot: merkleTree.getHexRoot(),
          mintPriceStart: ethers.utils.parseEther("11"),
          mintPriceEnd: ethers.utils.parseEther("11"),
          mintPriceStep: ethers.utils.parseEther("0"),
          mintStart: blockTimestamp + 1000,
          mintEnd: blockTimestamp + 2000,
          mintTokenAddress: testERC20.address,
        });
  
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
        await mintAndApproveERC20(claimable1, minter2.address, ethers.utils.parseEther("10000"));
        await mintAndApproveERC20(claimable2, minter1.address, ethers.utils.parseEther("10000"));
        await mintAndApproveERC20(claimable2, minter2.address, ethers.utils.parseEther("10000"));
        await mintAndApproveERC20(claimable3, minter1.address, ethers.utils.parseEther("10000"));
        await mintAndApproveERC20(claimable3, minter2.address, ethers.utils.parseEther("10000"));

        // console.log(merkleKeyForMint(claimable1.address, 1))

        let proof1 = merkleTree.getHexProof(merkleKeyForMint(claimable1.address, 1))
        let proof2 = merkleTree.getHexProof(merkleKeyForMint(claimable2.address, 3))
        let proof3 = merkleTree.getHexProof(merkleKeyForMint(claimable3.address, 1))

        await expect(minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1)).to.be.reverted;

        await network.provider.send("evm_increaseTime", [1000]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1).then(tx => tx.wait())
        await minter2.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1).then(tx => tx.wait())

        await network.provider.send("evm_increaseTime", [200]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2).then(tx => tx.wait())
        await minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2).then(tx => tx.wait())

        await network.provider.send("evm_increaseTime", [600]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 2, proof2).then(tx => tx.wait())
        await minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 2, proof2).then(tx => tx.wait())

        await expect(minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2)).to.be.reverted
        await expect(minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2)).to.be.reverted

        await network.provider.send("evm_increaseTime", [410]);
        await network.provider.send("evm_mine");

        await expect(minter1.connect(claimable3).mintMerkle(claimable3.address, 1, 1, proof3)).to.be.reverted
        await expect(minter2.connect(claimable3).mintMerkle(claimable3.address, 1, 1, proof3)).to.be.reverted
      })

      it("Shouldn't be transferable for Soulbound", async () => {
        await nft1.connect(claimable2).transferFrom(claimable2.address, claimable1.address, 1).then(tx => tx.wait());
        expect(nft2.connect(claimable2).transferFrom(claimable2.address, claimable1.address, 1)).to.be.reverted;
      })
    })

    describe('NFT minting with ETH', async () => {
      let nft1, minter1;
      let nft2, minter2;
      let nft3, minter3;
      let merkleTree;
      
      it('Should be able to deploy NFT', async () => {
        let blockTimestamp = await getBlockTimestamp()
        
        merkleTree = merkleTreeForMint([claimable1.address, claimable2.address, claimable3.address], [1, 3, 1])

        console.log('ROOT', merkleTree.getHexRoot())
        console.log(merkleTree.toString())

        const packedParameter = merkleMinterData({
          merkleRoot: merkleTree.getHexRoot(),
          mintPriceStart: ethers.utils.parseEther("10"),
          mintPriceEnd: ethers.utils.parseEther("4"),
          mintPriceStep: ethers.utils.parseEther("0.01"),
          mintStart: blockTimestamp + 1000,
          mintEnd: blockTimestamp + 2000,
          mintTokenAddress: testERC20.address, // Ignored
        });

        const packedParameter2 = merkleMinterData({
          merkleRoot: merkleTree.getHexRoot(),
          mintPriceStart: ethers.utils.parseEther("11"),
          mintPriceEnd: ethers.utils.parseEther("11"),
          mintPriceStep: ethers.utils.parseEther("0"),
          mintStart: blockTimestamp + 1000,
          mintEnd: blockTimestamp + 2000,
          mintTokenAddress: testERC20.address, // Ignored
        });
  
        const collectionId1 = ethers.utils.hexZeroPad('0x211101', 32);
        // const collectionId2 = ethers.utils.hexZeroPad('0x111102', 32);
        // const collectionId3 = ethers.utils.hexZeroPad('0x111103', 32);
        // const collectionId4 = ethers.utils.hexZeroPad('0x111104', 32);
        const projectId = ethers.utils.hexZeroPad('0x1234', 32);

        // console.log(packedParameter)
  
        let deployment1 = await deployNft({
          template: nft721template.address,
          minterTemplate: nftMerkleMinterNativeTemplate.address,
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
          exclusiveLevel: 1,
          maxSupply: 100,
          name: "Test 2",
          symbol: "TEST2",
        });

        minter2 = await deployMinter(
          nft2,
          projectOwner,
          nftMerkleMinterNativeTemplate.address,
          packedParameter2,
        )
  
        console.log(nft1.address, minter1.address)
        console.log(nft2.address, minter2.address)
      })

      it('Should be able to mint', async () => {
        // console.log(merkleKeyForMint(claimable1.address, 1))

        let proof1 = merkleTree.getHexProof(merkleKeyForMint(claimable1.address, 1))
        let proof2 = merkleTree.getHexProof(merkleKeyForMint(claimable2.address, 3))
        let proof3 = merkleTree.getHexProof(merkleKeyForMint(claimable3.address, 1))

        await expect(minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1, { value: ethers.utils.parseEther("10") })).to.be.reverted;

        await network.provider.send("evm_increaseTime", [1000]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1, { value: ethers.utils.parseEther("10") }).then(tx => tx.wait())
        await minter2.connect(claimable1).mintMerkle(claimable1.address, 1, 1, proof1, { value: ethers.utils.parseEther("11") }).then(tx => tx.wait())

        await network.provider.send("evm_increaseTime", [200]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2, { value: ethers.utils.parseEther("8") }).then(tx => tx.wait())
        await minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2, { value: ethers.utils.parseEther("11") }).then(tx => tx.wait())

        await network.provider.send("evm_increaseTime", [600]);
        await network.provider.send("evm_mine");

        await minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 2, proof2, { value: ethers.utils.parseEther("8") }).then(tx => tx.wait())
        await minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 2, proof2, { value: ethers.utils.parseEther("22") }).then(tx => tx.wait())

        await expect(minter1.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2, { value: ethers.utils.parseEther("4") })).to.be.reverted
        await expect(minter2.connect(claimable2).mintMerkle(claimable2.address, 3, 1, proof2, { value: ethers.utils.parseEther("11") })).to.be.reverted

        await network.provider.send("evm_increaseTime", [410]);
        await network.provider.send("evm_mine");

        await expect(minter1.connect(claimable3).mintMerkle(claimable3.address, 1, 1, proof3, { value: ethers.utils.parseEther("4") })).to.be.reverted
        await expect(minter2.connect(claimable3).mintMerkle(claimable3.address, 1, 1, proof3, { value: ethers.utils.parseEther("11") })).to.be.reverted
      })

      it("Shouldn't be transfer only to whitelisted address for Exclusive", async () => {
        await nft1.connect(claimable2).transferFrom(claimable2.address, claimable1.address, 1).then(tx => tx.wait());
        
        expect(nft2.connect(claimable2).transferFrom(claimable2.address, claimable1.address, 1)).to.be.reverted;

        await nft2.connect(claimable2).setApprovalForAll(someone.address, true);

        await nft2.connect(someone).transferFrom(claimable2.address, someone.address, 1).then(tx => tx.wait());

        await nft2.connect(projectOwner).setExclusiveContract(claimable1.address, true).then(tx => tx.wait());

        await nft2.connect(someone).transferFrom(someone.address, claimable1.address, 1).then(tx => tx.wait());
        await nft2.connect(claimable1).transferFrom(claimable1.address, someone.address, 1).then(tx => tx.wait());

        await nft2.connect(projectOwner).setExclusiveContract(claimable1.address, false).then(tx => tx.wait());
        await nft2.connect(projectOwner).setExclusiveContract(someone.address, false).then(tx => tx.wait());

        await nft2.connect(someone).transferFrom(someone.address, claimable1.address, 1).then(tx => tx.wait());

        expect(nft2.connect(claimable1).transferFrom(claimable1.address, someone.address, 1)).to.be.reverted;
      })
    })  
  })
});