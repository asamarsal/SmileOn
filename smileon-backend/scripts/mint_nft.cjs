#!/usr/bin/env node

/**
 * mint_nft.cjs
 * SmileOn ERC-721 Commemorative Photostrip Minter on Monad Testnet (Chain ID 10143)
 */

let ethers;
try {
  ethers = require('ethers');
} catch (e) {
  try {
    ethers = require('../../smileon-smartcontract/node_modules/ethers');
  } catch (e2) {
    ethers = require('../smileon-smartcontract/node_modules/ethers');
  }
}

// Parse CLI args
const args = {};
process.argv.slice(2).forEach(arg => {
  const [k, v] = arg.split('=');
  if (k && v !== undefined) {
    args[k.replace(/^--/, '')] = v;
  }
});

const recipient = args.to;
const metadataUri = args.uri || 'https://api.smileon-dapps.my.id/api/v1/nft/metadata/default';
const sessionId = args.session || 'session_' + Date.now();
const frameId = parseInt(args.frame || '1', 10);
const privateKey = args.key || process.env.MONAD_DEPLOYER_PRIVATE_KEY || 'd20ec36a1c43f1404b89f4651d5a4ec50fe6e5c363e63788e09e9aea4556215f';
const contractAddress = args.contract || process.env.MONAD_NFT_ADDRESS || '0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48';

if (!recipient || !recipient.startsWith('0x') || recipient.length !== 42) {
  console.error(JSON.stringify({
    success: false,
    error: 'Invalid recipient address. Expected 42-character 0x hex address.'
  }));
  process.exit(1);
}

// RPC List with fallback
const RPC_ENDPOINTS = [
  args.rpc,
  process.env.MONAD_FALLBACK_RPC_URL,
  'https://monad-testnet.drpc.org',
  'https://testnet-rpc.monad.xyz'
].filter(Boolean);

const ABI = [
  'function mintPhotostrip(address to, string uri, string sessionId, uint256 frameId) external returns (uint256)',
  'function totalSupply() view returns (uint256)'
];

const TRANSFER_TOPIC = '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

async function mint() {
  let lastError = null;

  for (const rpcUrl of RPC_ENDPOINTS) {
    try {
      const provider = new ethers.JsonRpcProvider(rpcUrl, 10143, { staticNetwork: true });

      const wallet = new ethers.Wallet(privateKey, provider);
      const contract = new ethers.Contract(contractAddress, ABI, wallet);

      const feeData = await provider.getFeeData();
      const nonce = await provider.getTransactionCount(wallet.address, 'pending');

      // Monad gas calculation: explicit limit to avoid RPC estimateGas errors
      const gasLimit = 350000n;
      const gasPrice = feeData.gasPrice ? (feeData.gasPrice * 12n / 10n) : 120000000000n;

      const tx = await contract.mintPhotostrip(
        recipient,
        metadataUri,
        sessionId,
        frameId,
        {
          gasLimit,
          gasPrice,
          nonce
        }
      );

      const receipt = await tx.wait(1);

      if (!receipt || receipt.status !== 1) {
        throw new Error('Transaction execution reverted or failed.');
      }

      // Parse tokenId from Transfer event (topic 3)
      let tokenId = null;
      if (receipt.logs) {
        for (const log of receipt.logs) {
          if (log.topics && log.topics[0] === TRANSFER_TOPIC && log.topics.length >= 4) {
            tokenId = BigInt(log.topics[3]).toString();
            break;
          }
        }
      }

      console.log(JSON.stringify({
        success: true,
        tx_hash: tx.hash,
        block_number: receipt.blockNumber,
        token_id: tokenId || '1',
        recipient: recipient,
        contract_address: contractAddress,
        metadata_uri: metadataUri,
        rpc_used: rpcUrl
      }));
      return;
    } catch (err) {
      lastError = err;
      // Continue to next RPC fallback
    }
  }

  console.error(JSON.stringify({
    success: false,
    error: lastError ? (lastError.message || String(lastError)) : 'All RPC endpoints failed.'
  }));
  process.exit(1);
}

mint();
