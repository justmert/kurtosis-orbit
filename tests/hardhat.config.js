require("@nomicfoundation/hardhat-toolbox");

// Default test accounts from kurtosis-orbit
const ACCOUNTS = {
  funnel: {
    privateKey:
      "0xb6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659",
    address: "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
  },
  sequencer: {
    privateKey:
      "0xcb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65",
    address: "0xe2148eE53c0755215Df69b2616E552154EdC584f",
  },
  validator: {
    privateKey:
      "0x182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890",
    address: "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe",
  },
  l2owner: {
    privateKey:
      "0xdc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36",
    address: "0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927",
  },
};

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
