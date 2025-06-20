const { ethers } = require("hardhat");

async function main() {
  console.log("🌱 Starting PlantSentience deployment to Core Blockchain...");
  console.log("=" .repeat(60));
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("🔑 Deploying with account:", deployer.address);
  
  // Check deployer balance
  const balance = await deployer.getBalance();
  console.log("💰 Account balance:", ethers.utils.formatEther(balance), "CORE");
  
  if (balance.eq(0)) {
    throw new Error("❌ Deployer account has no CORE tokens!");
  }
  
  console.log("\n📋 Getting contract factory...");
  
  // Get the contract factory
  const PlantSentience = await ethers.getContractFactory("PlantSentience");
  
  console.log("🚀 Deploying PlantSentience contract...");
  console.log("⏳ Please wait for transaction confirmation...");
  
  // Deploy the contract
  const plantSentience = await PlantSentience.deploy();
  
  console.log("⏳ Waiting for deployment confirmation...");
  
  // Wait for the contract to be deployed
  await plantSentience.deployed();
  
  console.log("\n🎉 PlantSentience contract deployed successfully!");
  console.log("=" .repeat(60));
  console.log("📋 Contract Details:");
  console.log("   • Contract Address:", plantSentience.address);
  console.log("   • Transaction Hash:", plantSentience.deployTransaction.hash);
  console.log("   • Block Number:", plantSentience.deployTransaction.blockNumber);
  console.log("   • Gas Limit:", plantSentience.deployTransaction.gasLimit.toString());
  console.log("   • Gas Price:", ethers.utils.formatUnits(plantSentience.deployTransaction.gasPrice, "gwei"), "Gwei");
  
  // Verify contract deployment by calling read functions
  console.log("\n🔍 Verifying contract deployment...");
  
  try {
    const totalPlants = await plantSentience.totalPlants();
    console.log("✅ Total plants initialized:", totalPlants.toString());
    
    const nextPlantId = await plantSentience.nextPlantId();
    console.log("✅ Next plant ID:", nextPlantId.toString());
    
    const healthThreshold = await plantSentience.HEALTH_THRESHOLD();
    console.log("✅ Health threshold:", healthThreshold.toString());
    
    console.log("✅ Contract verification successful!");
    
  } catch (error) {
    console.error("❌ Contract verification failed:", error.message);
    throw error;
  }
  
  // Test a basic function call
  console.log("\n🧪 Running basic functionality test...");
  
  try {
    // Test getting plants by owner (should return empty array)
    const ownerPlants = await plantSentience.getPlantsByOwner(deployer.address);
    console.log("✅ Owner plants query successful. Count:", ownerPlants.length);
    
  } catch (error) {
    console.error("❌ Basic functionality test failed:", error.message);
  }
  
  // Calculate deployment cost
  const deploymentReceipt = await plantSentience.deployTransaction.wait();
  const gasUsed = deploymentReceipt.gasUsed;
  const gasPrice = plantSentience.deployTransaction.gasPrice;
  const deploymentCost = gasUsed.mul(gasPrice);
  
  console.log("\n💸 Deployment Cost Analysis:");
  console.log("   • Gas Used:", gasUsed.toString());
  console.log("   • Gas Price:", ethers.utils.formatUnits(gasPrice, "gwei"), "Gwei");
  console.log("   • Total Cost:", ethers.utils.formatEther(deploymentCost), "CORE");
  
  // Create deployment summary
  const deploymentInfo = {
    contractName: "PlantSentience",
    contractAddress: plantSentience.address,
    transactionHash: plantSentience.deployTransaction.hash,
    blockNumber: plantSentience.deployTransaction.blockNumber,
    gasUsed: gasUsed.toString(),
    gasPrice: gasPrice.toString(),
    deploymentCost: deploymentCost.toString(),
    deployer: deployer.address,
    network: "Core Blockchain Testnet",
    chainId: 1114,
    timestamp: new Date().toISOString(),
    rpcUrl: "https://rpc.test2.btcs.network"
  };
  
  // Save deployment info to file
  const fs = require('fs');
  const path = require('path');
  
  // Ensure directory exists
  if (!fs.existsSync('deployments')) {
    fs.mkdirSync('deployments');
  }
  
  const fileName = `deployments/PlantSentience-${Date.now()}.json`;
  fs.writeFileSync(fileName, JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n💾 Deployment Summary:");
  console.log("=" .repeat(60));
  console.log("🌱 PlantSentience Smart Contract");
  console.log("🌐 Network: Core Blockchain Testnet");
  console.log("📍 Contract Address:", plantSentience.address);
  console.log("👤 Deployer:", deployer.address);
  console.log("📊 Block Number:", plantSentience.deployTransaction.blockNumber);
  console.log("💾 Deployment info saved to:", fileName);
  console.log("=" .repeat(60));
  
  console.log("\n🔗 Next Steps:");
  console.log("1. Verify your contract on Core Blockchain explorer");
  console.log("2. Test plant registration functionality");
  console.log("3. Set up IoT sensors for health monitoring");
  console.log("4. Configure caregiver permissions as needed");
  
  console.log("\n🎊 Deployment completed successfully!");
}

// Handle deployment execution
main()
  .then(() => {
    console.log("\n✅ Script executed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Deployment failed with error:");
    console.error(error);
    process.exit(1);
  });
