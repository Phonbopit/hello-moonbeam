import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('AhoyMoonNFT', () => {
  it('Should able to mint a NFT', async () => {
    const Contract = await ethers.getContractFactory('AhoyMoon');
    const contract = await Contract.deploy();
    await contract.deployed();

    const [_, wallet1] = await ethers.getSigners();

    await contract.safeMint(wallet1.address);

    const ownerAddress = await contract.ownerOf(0); // tokenId = 0 is the first mint.

    expect(ownerAddress).to.equal(wallet1.address);
  });
});
