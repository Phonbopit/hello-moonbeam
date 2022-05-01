import { ethers } from 'hardhat';

const main = async () => {
  const Factory = await ethers.getContractFactory('DelegationDAO');
  const contract = await Factory.deploy();

  await contract.deployed();

  console.log('Contract deployed to:', contract.address);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
