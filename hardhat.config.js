/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-etherscan");
const CONFIG = require("./credentials.json");

module.exports = {
	solidity: {
		compilers: [
			{
				version: "0.8.4",
				settings: {
					optimizer: {
						enabled: true,
						runs: 1000,
					},
				},
			},
		],
	},
	spdxLicenseIdentifier: {
		overwrite: true,
		runOnCompile: true,
	},
	defaultNetwork: "hardhat",
	mocha: {
		timeout: 1000000000000,
	},

	networks: {
		rinkeby: {
			url: CONFIG["RINKEBY"]["URL"],
			accounts: [CONFIG["RINKEBY"]["PKEY"]],
		},
	},
	etherscan: {
		apiKey: "6WXM3S7GRG2CYWZ61EIAIJR8AVUM8NSW47",
	},

	contractSizer: {
		alphaSort: false,
		runOnCompile: true,
		disambiguatePaths: false,
	},
};
