import { ethers, network } from "hardhat";
import * as fs from "fs";
import * as path from "path";

async function main() {
  console.log("==================================================");
  console.log("  Deploying SmileOn Smart Contracts on Monad      ");
  console.log("==================================================");
  console.log(`Network Name: ${network.name}`);
  console.log(`Chain ID:     ${network.config.chainId}`);

  const [deployer] = await ethers.getSigners();
  console.log(`Deployer Address: ${deployer.address}`);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(`Deployer Balance: ${ethers.formatEther(balance)} MON`);

  // Treasury address (default to deployer if not specified in env)
  const treasuryAddress = process.env.TREASURY_ADDRESS || deployer.address;
  console.log(`Treasury Address: ${treasuryAddress}`);

  // 1. Deploy SmileOnPaymentHub
  console.log("\n[1/2] Deploying SmileOnPaymentHub...");
  const PaymentHubFactory = await ethers.getContractFactory("SmileOnPaymentHub");
  const paymentHub = await PaymentHubFactory.deploy(deployer.address, treasuryAddress);
  await paymentHub.waitForDeployment();
  const paymentHubAddress = await paymentHub.getAddress();
  console.log(`✓ SmileOnPaymentHub deployed at: ${paymentHubAddress}`);

  // 2. Deploy SmileOnNFT
  console.log("\n[2/2] Deploying SmileOnNFT...");
  const NFTFactory = await ethers.getContractFactory("SmileOnNFT");
  const nft = await NFTFactory.deploy(deployer.address);
  await nft.waitForDeployment();
  const nftAddress = await nft.getAddress();
  console.log(`✓ SmileOnNFT deployed at: ${nftAddress}`);

  // Save deployment artifact
  const deploymentInfo = {
    network: network.name,
    chainId: network.config.chainId,
    deployedAt: new Date().toISOString(),
    deployer: deployer.address,
    treasury: treasuryAddress,
    contracts: {
      SmileOnPaymentHub: {
        address: paymentHubAddress,
        explorerUrl: `https://testnet.monadexplorer.com/address/${paymentHubAddress}`,
      },
      SmileOnNFT: {
        address: nftAddress,
        explorerUrl: `https://testnet.monadexplorer.com/address/${nftAddress}`,
      },
    },
  };

  const outputPath = path.join(__dirname, "../deployed-addresses.json");
  fs.writeFileSync(outputPath, JSON.stringify(deploymentInfo, null, 2));
  console.log(`\n✓ Deployment manifest saved to: ${outputPath}`);

  console.log("\n==================================================");
  console.log("  Deployment Complete! Monad Explorer Links:       ");
  console.log(`  PaymentHub: https://testnet.monadexplorer.com/address/${paymentHubAddress}`);
  console.log(`  NFT:        https://testnet.monadexplorer.com/address/${nftAddress}`);
  console.log("==================================================");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
