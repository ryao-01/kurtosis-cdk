const { Web3 } = require("web3")

const args = process.argv.slice(2);
const rpcUrl = args[0]; // devnet RPC URL ex -> "http://127.0.0.1:30371"
const web3 = new Web3(rpcUrl);

const privateKey = "0x12d7de8621a77640c9241b2595ba78ce443d05e94090365ab3bb5e19df82c625";
const account = web3.eth.accounts.privateKeyToAccount(privateKey);
const fromAddress = account.address;

const toAddress = fromAddress; 
const valueWei = web3.utils.toHex('10000000000000000'); // 0.01 Matic in Wei (hex)
const gasPriceHex = web3.utils.toHex(0); 
const gasLimitHex = web3.utils.toHex(21000);
let nonceHex;
let chainIdHex;

async function sendMatic() {
  try {
    nonceHex = await web3.eth.getTransactionCount(fromAddress, 'latest');
    chainIdHex = await web3.eth.getChainId(); // Get chain ID dynamically

    const txParams = {
      nonce: nonceHex,
      gasPrice: gasPriceHex,
      gasLimit: gasLimitHex,
      to: toAddress,
      value: valueWei,
      data: '0x0', // No data for Matic transfer
      chainId: chainIdHex,
    };

    const signedTx = await account.signTransaction(txParams);
    const rawTx = signedTx.rawTransaction;

    console.log('Raw Transaction:', rawTx);

    const receipt = await web3.eth.sendSignedTransaction(rawTx);
    console.log('Transaction Receipt:', receipt);

  } catch (error) {
    console.error('Error sending transaction:', error);
  }
}

sendMatic();
