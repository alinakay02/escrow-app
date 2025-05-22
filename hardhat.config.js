require("dotenv").config();
require("@nomiclabs/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",

  paths: {
    sources: "./contracts",
    tests:    "./test",
    scripts:  "./scripts"
  },
  
  networks: {
    teth: {
      url: process.env.TETH_RPC_URL,
      accounts: [process.env.PRIVATE_KEY]
    },
    localhost: {
      url: "http://127.0.0.1:8545"
    }
  }
};