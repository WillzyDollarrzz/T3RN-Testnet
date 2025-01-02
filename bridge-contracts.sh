#!/bin/bash

echo "Setting up Project Directory..."
npm init -y
npm install --save-dev hardhat
npx hardhat 

echo "Installing necessary dependencies..."
sudo apt update && sudo apt upgrade -y
npm install --save-dev @nomicfoundation/hardhat-toolbox
npm install --save-dev dotenv


echo "Configuring hardhat.config.js file..."
cat > hardhat.config.js <<EOL
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    opSepolia: {
      url: "https://sepolia.optimism.io/",
      accounts: [process.env.PRIVATE_KEY]
    },
    baseSepolia: {
      url: "https://sepolia.base.org/",
      accounts: [process.env.PRIVATE_KEY]
    },
    blastSepolia: {
      url: "https://sepolia.blast.io/",
      accounts: [process.env.PRIVATE_KEY]
    },
    arbSepolia: {
      url: "https://arbitrum-sepolia-rpc.publicnode.com",
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
EOL

echo "Setting Up Private Key..."
echo "Enter your Private Key:"
read PRIVATE_KEY
echo "PRIVATE_KEY=$PRIVATE_KEY" > .env

echo "Coding The Smart Contract..."
cat > contracts/bridge.sol <<EOL
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract AutoBridgeReceiver {
    address public immutable owner;

    event ReceivedETH(address indexed sender, uint256 amount);
    event ERC20Transferred(address indexed token, address indexed to, uint256 amount);
    event TokensProcessed(address indexed token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function processIncomingTokens(address token) public {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to process");

        bool success = IERC20(token).transfer(owner, balance);
        require(success, "Token transfer failed");

        emit TokensProcessed(token, balance);
    }

    receive() external payable {
        emit ReceivedETH(msg.sender, msg.value);
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }

    function emergencyWithdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");

        (bool success, ) = owner.call{value: balance}("");
        require(success, "ETH transfer failed");
    }

    function emergencyWithdrawERC20(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        bool success = IERC20(token).transfer(owner, balance);
        require(success, "Token transfer failed");
    }

    fallback() external payable {
        emit ReceivedETH(msg.sender, msg.value);
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "ETH transfer failed");
    }
}
EOL


echo "Creating Deployment Files..."
mkdir scripts

cat > scripts/deployonbase.js <<EOL
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AutoBridgeReceiver = await hre.ethers.getContractFactory("AutoBridgeReceiver");
    console.log("Deploying bridge contract...");

    const receiver = await AutoBridgeReceiver.deploy();
    console.log("Deployment in Progress...");
    await receiver.waitForDeployment();
    const contractAddress = await receiver.getAddress();
    const txHash = receiver.deploymentTransaction().hash;

    console.log("Bridge contract for base sepolia to op sepolia deployed -->", contractAddress);
    console.log("Transaction link: https://sepolia.basescan.org/tx/" + txHash);
}

main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
});
EOL

cat > scripts/deployonop.js <<EOL
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AutoBridgeReceiver = await hre.ethers.getContractFactory("AutoBridgeReceiver");
    console.log("Deploying bridge contract...");

    const receiver = await AutoBridgeReceiver.deploy();
    console.log("Deployment in Progress...");
    await receiver.waitForDeployment();
    const contractAddress = await receiver.getAddress();
    const txHash = receiver.deploymentTransaction().hash;

    console.log("Bridge contract for op sepolia to base sepolia deployed -->", contractAddress);
    console.log("Transaction link: https://sepolia-optimism.etherscan.io/tx/" + txHash);
}

main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
});
EOL

cat > scripts/deployonblast.js <<EOL
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AutoBridgeReceiver = await hre.ethers.getContractFactory("AutoBridgeReceiver");
    console.log("Deploying bridge contract...");

    const receiver = await AutoBridgeReceiver.deploy();
    console.log("Deployment in Progress...");
    await receiver.waitForDeployment();
    const contractAddress = await receiver.getAddress();
    const txHash = receiver.deploymentTransaction().hash;

    console.log("Bridge contract for blast sepolia to base/arb/op deployed -->", contractAddress);
    console.log("Transaction link: https://sepolia.blastscan.io/tx/" + txHash);
}

main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
});
EOL

cat > scripts/deployonarb.js <<EOL
const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contract with account:", deployer.address);

    const AutoBridgeReceiver = await hre.ethers.getContractFactory("AutoBridgeReceiver");
    console.log("Deploying bridge contract...");

    const receiver = await AutoBridgeReceiver.deploy();
    console.log("Deployment in Progress...");
    await receiver.waitForDeployment();
    const contractAddress = await receiver.getAddress();
    const txHash = receiver.deploymentTransaction().hash;

    console.log("Bridge contract for arb sepolia to base sepolia -->", contractAddress);
    console.log("Transaction link: https://sepolia.arbiscan.io/tx/" + txHash);
}

main().catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
});
EOL


echo "Compiling the Contract..."
npx hardhat compile


echo "Deploying Contracts On Each Network..."
npx hardhat run scripts/deployonbase.js --network baseSepolia
npx hardhat run scripts/deployonop.js --network opSepolia
npx hardhat run scripts/deployonblast.js --network blastSepolia
npx hardhat run scripts/deployonarb.js --network arbSepolia

echo "Part 1 - Completed!" 
echo "Ensure You Save The Above Contract Address Somewhere, It'll Be Used In Part 2!"
echo "Follow @willzydollarrzz On X For More Guides Like This!"
