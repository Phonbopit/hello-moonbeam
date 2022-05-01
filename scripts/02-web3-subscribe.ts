const Web3 = require('web3');
import {} from 'web3-utils';
const web3 = new Web3('wss://wss.api.moonbase.moonbeam.network');

// event signature
// EventSignature = keccak256(Transfer(address,address,uint256))
web3.eth
  .subscribe(
    'logs', // newBlockHeaders
    {
      address: 'ContractAddress',
      topics: [
        // Don't forget to add `0x` prefix
        '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef'
      ]
    },
    (error: any, result: any) => {
      if (error) console.error(error);
    }
  )
  .on('connected', function (subscriptionId: number) {
    console.log(subscriptionId);
  })
  .on('data', function (log: any) {
    console.log(log);
  });
