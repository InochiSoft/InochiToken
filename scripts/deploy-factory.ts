const { ethers, upgrades } = require("hardhat");

async function main() {
  const Factory = await ethers.getContractFactory("Factory");
  console.log("Deploying Factory...");
  const contract = await upgrades.deployProxy(Factory, ["Inochi", "INOCHI"], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("Factory deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
