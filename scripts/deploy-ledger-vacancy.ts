const { ethers, upgrades } = require("hardhat");
import "@openzeppelin/hardhat-upgrades";

async function main() {
  const Ledger = await ethers.getContractFactory("Ledger");
  console.log("Deploying Ledger...");
  const contract = await upgrades.deployProxy(Ledger, ["Vacancy", "VACANCY"], {
    initializer: "initialize",
    kind: "transparent",
  });
  await contract.deployed();
  console.log("Ledger deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
