import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { deployContract, deployUpgradable } from '../../utils/deploySimple'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, fetchIfDifferent } = deployments
  const { deployer } = await getNamedAccounts()
  const deployerSigner = await ethers.getSigner(deployer);

  const projectRegistry = await deployUpgradable(hre, 'AxelarSeaProjectRegistry')

  await projectRegistry.contract.connect(deployerSigner).setOperator(deployer, true).then(tx => tx.wait());

  // DEV: whitelist dev operator
  await projectRegistry.contract.connect(deployerSigner).setOperator('0xd2794Af5e78B42e74252FBc68De3CfAc644629AC', true).then(tx => tx.wait());
}

func.id = 'ProjectRegistry'
func.tags = ['ProjectRegistry']
func.dependencies = []

export default func
