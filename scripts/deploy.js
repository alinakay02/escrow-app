const hre = require("hardhat");

async function main() {
  console.log("Deploying contracts...");

  // Deploy Factory
  const EscrowFactory = await hre.ethers.getContractFactory("EscrowFactory");
  const factory = await EscrowFactory.deploy();
  await factory.waitForDeployment();

  console.log("EscrowFactory deployed to:", await factory.getAddress());

  // Get deployed contract addresses
  const [marketplaceAddr, userProfileAddr] = await factory.getContracts();
  console.log("EscrowMarketplace deployed to:", marketplaceAddr);
  console.log("UserProfile deployed to:", userProfileAddr);

  // Verify contracts if not on local network
  if (network.name !== "localhost" && network.name !== "hardhat") {
    console.log("Verifying contracts...");
    
    await hre.run("verify:verify", {
      address: await factory.getAddress(),
      constructorArguments: [],
    });

    await hre.run("verify:verify", {
      address: marketplaceAddr,
      constructorArguments: [],
    });

    await hre.run("verify:verify", {
      address: userProfileAddr,
      constructorArguments: [],
    });
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
