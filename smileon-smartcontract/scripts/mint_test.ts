import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Caller:", deployer.address);
  
  const nftAddress = "0xd685CCC9EF93b027e0D1EF05d4eDf83EC0385d48";
  const nft = await ethers.getContractAt("SmileOnNFT", nftAddress, deployer);
  
  console.log("Contract Name:", await nft.name());
  console.log("Contract Symbol:", await nft.symbol());
  console.log("Contract Owner:", await nft.owner());
}

main().catch((e) => {
  console.error("Error:", e);
  process.exit(1);
});
