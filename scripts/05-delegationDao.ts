import { ethers } from 'hardhat';

const main = async () => {
  const Factory = await ethers.getContractFactory('DelegationDAO');

  const [deployer] = await ethers.getSigners();

  // FRANK -> https://apps.moonbeam.network/moonbase-alpha/staking
  const target = '0x4209CA6C63c1624Ec86A1A6221618f8FCD1FCA84';
  const contract = await Factory.deploy(target, deployer.address);

  await contract.deployed();

  console.log('Contract deployed to:', contract.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
