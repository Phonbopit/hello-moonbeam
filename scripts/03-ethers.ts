import { ethers, Wallet, utils } from 'ethers';
import dotenv from 'dotenv';

dotenv.config();

const providerRPC = {
  moonbase: {
    name: 'moonbase-alpha',
    rpc: 'https://rpc.api.moonbase.moonbeam.network',
    chainId: 1287 // 0x507 in hex,
  }
};

const provider = new ethers.providers.StaticJsonRpcProvider(
  providerRPC.moonbase.rpc,
  {
    chainId: providerRPC.moonbase.chainId,
    name: providerRPC.moonbase.name
  }
);

const getBalances = async () => {
  const address = 'YOUR_ADDRESS';
  const balance = await provider.getBalance(address);
  console.log(`Balance = ${ethers.utils.formatEther(balance)}`);
};

const sendTransaction = async () => {
  console.log('Start sendTransaction...');
  const accountFrom = {
    privateKey: process.env.PRIVATE_KEY || '<YOUR_PRIVATE_KEY>'
  };

  const addressTo = 'YOUR_ADDRESS';

  // Create a wallet.
  const wallet = new Wallet(accountFrom.privateKey, provider);

  console.log(`Send tx from ${wallet.address} to ${addressTo}`);

  const tx = {
    to: addressTo,
    value: utils.parseEther('0.05')
  };

  const receipt = await wallet.sendTransaction(tx);
  await receipt.wait(1); // 1 confirmation
  console.log(`Transaction successful with : ${receipt.hash}`);
};

const connectContract = async () => {
  const contractAddress = 'CONTRACT_ADDRESS';
  const abi = [
    {
      constant: true,
      inputs: [],
      name: 'totalSupply',
      outputs: [
        {
          name: '',
          type: 'uint256'
        }
      ],
      payable: false,
      stateMutability: 'view',
      type: 'function'
    }
  ];

  const token = new ethers.Contract(contractAddress, abi, provider);

  const totalSupply = await token.totalSupply();
  console.log(`Total supply ${utils.formatEther(totalSupply)} TOKEN`);
};

const run = () => {
  try {
    // getBalances();
    // sendTransaction();
    connectContract();
  } catch (error) {
    console.error(error);
    process.exit(1);
  }
};

run();
