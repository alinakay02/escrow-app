require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    customTestnet: {
      url: "http://93.95.97.136:8545",
      accounts: [process.env.PRIVATE_KEY].filter(Boolean)
    }
  }
};