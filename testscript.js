const { ethers } = require("ethers");
const args = process.argv.slice(2);
// pass in rpcUrl as first param.

const rpcUrl = args[0]; // devnet RPC URL ex -> "http://127.0.0.1:30371"
const provider = new ethers.JsonRpcProvider(rpcUrl);
const privateKey = "0x12d7de8621a77640c9241b2595ba78ce443d05e94090365ab3bb5e19df82c625";
// this is the prefunded dev account -> 0xE34aaF64b29273B7D567FCFc40544c014EEe9970
const wallet = new ethers.Wallet(privateKey, provider); // Wallet connected to provider

async function sendMaticEthers() {
    try {
        const toAddress = wallet.address; // Send to self
        const value = ethers.parseEther("0.01"); // 0.01 Matic in Ether (Matic uses same units)

        const tx = {
            to: toAddress,
            value: value,
            gasLimit: 21000,
            gasPrice: 0 // Or getGasPrice from provider if needed
        };

        const signedTx = await wallet.signTransaction(tx);
        const rawTx = signedTx; 

        console.log("Raw Transaction:", rawTx);

        const transactionResponse = await wallet.sendTransaction(rawTx);
        // This transaction response contains the tx hash
        console.log("Transaction Response:", transactionResponse); 
        // Wait for receipt
        const receipt = await transactionResponse.wait(); 
        console.log("Transaction Receipt:", receipt);

    } catch (error) {
        console.error("Error sending transaction:", error);
    }
}

sendMaticEthers();