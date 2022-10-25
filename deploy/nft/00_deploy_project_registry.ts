import { ethers } from 'hardhat'
import { DeployFunction } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { deployContract } from '../../utils/deploySimple'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments, network } = hre
  const { deploy, fetchIfDifferent } = deployments
  const { deployer } = await getNamedAccounts()

  const projectRegistry = await deployContract(hre, 'AxelarSeaProjectRegistry')
}

func.id = 'ProjectRegistry'
func.tags = ['ProjectRegistry']
func.dependencies = []

export default func
