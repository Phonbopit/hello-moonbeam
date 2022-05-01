import Web3 from 'web3';
import { AbiItem } from 'web3-utils';

// 1. Setup RPC
const RPC_URL = 'https://rpc.api.moonbase.moonbeam.network';
const web3 = new Web3(RPC_URL);

// 2. Create address variables
const addressFrom = '<ADDRESS>';
const addressTo = '<ADDRESS>';

// 3. Create balances function
const balances = async () => {
  // 4. Fetch balance info
  const balanceFrom = web3.utils.fromWei(
    await web3.eth.getBalance(addressFrom),
    'ether'
  );
  const balanceTo = web3.utils.fromWei(
    await web3.eth.getBalance(addressTo),
    'ether'
  );

  console.log(`The balance of ${addressFrom} is: ${balanceFrom} ETH`);
  console.log(`The balance of ${addressTo} is: ${balanceTo} ETH`);
};

// 5. Call balances function
// balances();

const sendTransaction = async () => {
  // 1. Create signed account.
  const accountFrom = {
    privateKey: 'YOUR-PRIVATE-KEY-HERE',
    address: 'PUBLIC-ADDRESS-OF-PK-HERE'
  };
  const addressTo = 'ADDRESS-TO-HERE'; // Change addressTo

  // 2. Create send function
  const send = async () => {
    console.log(
      `Attempting to send transaction from ${accountFrom.address} to ${addressTo}`
    );

    // 3. Sign tx with PK
    const createTransaction = await web3.eth.accounts.signTransaction(
      {
        gas: 21000,
        to: addressTo,
        value: web3.utils.toWei('0.05', 'ether')
      },
      accountFrom.privateKey
    );

    // 4. Send tx and wait for receipt
    const createReceipt = await web3.eth.sendSignedTransaction(
      createTransaction.rawTransaction || ''
    );
    console.log(
      `Transaction successful with hash: ${createReceipt.transactionHash}`
    );
  };

  // 5. Call send function
  send();
};

const getContractData = async () => {
  // 1.struct an ABI (currently, only totalSupply)
  const abi: AbiItem[] = [
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

  // 2. Contract address AToken on moonbase alpha
  const contractAddress = '<CONTRACT_ADDRESS>';

  // 3. Create contract instance
  const token = new web3.eth.Contract(abi, contractAddress);

  // 4. Call total Supply
  const totalSupply = await token.methods.totalSupply().call();

  console.log('totalSupply : ', web3.utils.fromWei(totalSupply));
};

// uncomment to send a transaction.
// sendTransaction();
getContractData();
