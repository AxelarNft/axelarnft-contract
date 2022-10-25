import { DeployFunction, DeployResult } from 'hardhat-deploy/types'
import { HardhatRuntimeEnvironment } from 'hardhat/types'

export async function deployContract(hre: HardhatRuntimeEnvironment, name: string, ...args: any[]): Promise<DeployResult> {
  const { getNamedAccounts, deployments } = hre
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()

  const deployArgs = {
    from: deployer,
    args,
    log: true,
  };

  return await deploy(name, deployArgs)
}