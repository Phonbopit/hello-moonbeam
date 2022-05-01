import { ethers } from 'hardhat';

// import ABI from '../artifacts/contracts/AggregatorV3Interface.sol/AggregatorV3Interface.json';

// data feed contracts (Moonbase Alpha)
// Link : https://docs.moonbeam.network/builders/integrations/oracles/chainlink/
const contracts = {
  'AAVE/USD': '0x64B22D2B8c3CA311a0C2de34bf799f8101c89362',
  'BTC/USD': '0xCf88A8d7fc1A687895fC8ffAad567f303926B094',
  'DOT/USD': '0xA873F6b30aD79fCAF9b03A0A883d6D1f18D661d7',
  'ETH/USD': '0x3669da30c33D27A6A579548fCfc345fE5dEdda6e'
};

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

const main = async () => {
  // with hre, we can use getContractAt
  const priceFeed = await ethers.getContractAt(
    'AggregatorV3Interface',
    contracts['BTC/USD']
  );

  // If not running with npx hardhat use this.
  // const priceFeed = new ethers.Contract(
  //   contracts['BTC/USD'],
  //   ABI.abi,
  //   provider
  // );

  const prices = await priceFeed.latestRoundData();
  const decimals = await priceFeed.decimals();

  const price = prices[1];
  console.log(`Price : ${ethers.utils.formatUnits(price, decimals)}`);
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
