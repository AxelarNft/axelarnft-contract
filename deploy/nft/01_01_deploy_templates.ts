import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { deployContract } from '../../utils/deploySimple'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, fetchIfDifferent } = deployments
  const { deployer } = await getNamedAccounts()
  const deployerSigner = await ethers.getSigner(deployer);

  const projectRegistry = await ethers.getContract('AxelarSeaProjectRegistry')

  const ERC721EnumerableTemplate = await deployContract(hre, 'AxelarSeaNft721Enumerable')
  const ERC721ATemplate = await deployContract(hre, 'AxelarSeaNft721A')

  const AxelarSeaNftMerkleMinter = await deployContract(hre, 'AxelarSeaNftMerkleMinter')
  const AxelarSeaNftMerkleMinterNative = await deployContract(hre, 'AxelarSeaNftMerkleMinterNative')
  const AxelarSeaNftSignatureMinter = await deployContract(hre, 'AxelarSeaNftSignatureMinter')
  const AxelarSeaNftSignatureMinterNative = await deployContract(hre, 'AxelarSeaNftSignatureMinterNative')
  const AxelarSeaNftPublicMinter = await deployContract(hre, 'AxelarSeaNftPublicMinter')
  const AxelarSeaNftPublicMinterNative = await deployContract(hre, 'AxelarSeaNftPublicMinterNative')

  await projectRegistry.connect(deployerSigner).setTemplate(ERC721EnumerableTemplate.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setTemplate(ERC721ATemplate.address, true).then(tx => tx.wait());

  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftMerkleMinter.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftMerkleMinterNative.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftSignatureMinter.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftSignatureMinterNative.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftPublicMinter.address, true).then(tx => tx.wait());
  await projectRegistry.connect(deployerSigner).setMinterTemplate(AxelarSeaNftPublicMinterNative.address, true).then(tx => tx.wait());
}

func.id = 'nft-template-01'
func.tags = ['nft-template-01']
func.dependencies = ['ProjectRegistry']

export default func
