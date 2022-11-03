import {
	ETHERSCAN_API_KEY,
	FUJI_PRIVATE_KEY,
	GOERLI_PRIVATE_KEY,
	GOERLI_RPC_URL,
	HARDHAT_NETWORK,
	MUMBAI_RPC_URL,
	OPTIMISM_API_KEY,
	POLYGONSCAN_API_KEY,
	SNOWTRACE_API_KEY
} from './config'

import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@typechain/hardhat'
import 'hardhat-contract-sizer'
import 'hardhat-deploy'
import 'hardhat-gas-reporter'
//import 'hardhat-typechain'
import { TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS } from 'hardhat/builtin-tasks/task-names'
import { subtask } from 'hardhat/config'
import { HardhatUserConfig, ProjectPathsUserConfig } from 'hardhat/types'
import 'solidity-coverage'

// TESTING - does not compile SVG files saving a lot of time
subtask(TASK_COMPILE_SOLIDITY_GET_SOURCE_PATHS).setAction(async (_, __, runSuper) => {
	const paths = await runSuper()

	return paths.filter((p) => !p.includes('SVG'))
})

/// @dev when deploying SVG on other chains, bytecodeHash should be set to none
const OPTIMIZED_COMPILER_SETTINGS = {
	version: '0.8.13',
	settings: {
		optimizer: {
			enabled: true,
			runs: 10000,
			details: {
				yul: true
			}
		},
		viaIR: true,
		metadata: {
			bytecodeHash: 'none'
		}
	}
}

// Previously used for FieldSVGs 9, 15, 16, 17, 22
const DEFAULT_COMPILER_SETTINGS = {
	version: '0.8.13',
	settings: {
		optimizer: {
			enabled: true,
			runs: 10000
		},
		metadata: {
			bytecodeHash: 'none'
		}
	}
}

interface ProjectPathsUserConfigExtended extends ProjectPathsUserConfig {
	scripts: string
}
interface HardhatUserConfigExtended extends HardhatUserConfig {
	contractSizer: Record<string, unknown>
	paths: ProjectPathsUserConfigExtended
}

const getApiKey = () => {
	switch (HARDHAT_NETWORK) {
		case 'mainnet':
		case 'goerli':
		case 'ropsten':
			return ETHERSCAN_API_KEY
		case 'polygon':
		case 'mumbai':
			return POLYGONSCAN_API_KEY
		case 'avax':
		case 'fuji':
			return SNOWTRACE_API_KEY
		case 'optimism':
		case 'kovan':
			return OPTIMISM_API_KEY
		default:
			return ''
	}
}

const config: HardhatUserConfigExtended = {
	contractSizer: {
		alphaSort: true,
		disambiguatePaths: false,
		runOnCompile: true,
		strict: false
	},
	solidity: {
		compilers: [OPTIMIZED_COMPILER_SETTINGS],
		overrides: {
			'contracts/ShieldManager/SVGs/Fields/FieldSVGs9.sol': DEFAULT_COMPILER_SETTINGS,
			'contracts/ShieldManager/SVGs/Fields/FieldSVGs15.sol': DEFAULT_COMPILER_SETTINGS,
			'contracts/ShieldManager/SVGs/Fields/FieldSVGs16.sol': DEFAULT_COMPILER_SETTINGS,
			'contracts/ShieldManager/SVGs/Fields/FieldSVGs17.sol': DEFAULT_COMPILER_SETTINGS,
			'contracts/ShieldManager/SVGs/Fields/FieldSVGs22.sol': DEFAULT_COMPILER_SETTINGS
		}
	},
	namedAccounts: {
		deployer: 0,
		alice: 1,
		bob: 2
	},
	defaultNetwork: HARDHAT_NETWORK,
	networks: {
		hardhat: {
			// allowUnlimitedContractSize: true,
			chainId: 43114,
			// gasPrice: 225000000000,
			forking: {
				url: 'https://api.avax.network/ext/bc/C/rpc',
				enabled: true,
				blockNumber: 14518261
			},
			saveDeployments: true
		},
		local: {
			url: 'http://127.0.0.1:8545/',
			gasPrice: 225000000000,
			chainId: 31337,
			accounts: [
				'0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
				'0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
				'0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
				'0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6',
				'0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a',
				'0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba'
			],
			saveDeployments: true
		},
		fuji: {
			url: 'https://api.avax-test.network/ext/bc/C/rpc',
			gasPrice: 25000000000,
			gas: 21000,
			chainId: 43113,
			accounts: [FUJI_PRIVATE_KEY],
			timeout: 2147483647,
			saveDeployments: true,
			deploy: ['deploy/run'],
			verify: {
				etherscan: {
					apiUrl: 'https://testnet.snowtrace.io',
					apiKey: SNOWTRACE_API_KEY
				}
			}
		},
		mumbai: {
			url: MUMBAI_RPC_URL,
			gasPrice: 22500000000,
			gas: 21000,
			//blockGasLimit: 8000000,
			chainId: 80001,
			accounts: [FUJI_PRIVATE_KEY], // TODO: add accounts
			timeout: 2147483647,
			saveDeployments: true,
			deploy: ['deploy/run'],
			verify: {
				etherscan: {
					apiUrl: 'https://mumbai.polygonscan.com/',
					apiKey: POLYGONSCAN_API_KEY
				}
			}
		},
		kovan: {
			url: 'https://kovan.optimism.io',
			gasPrice: 25000000000,
			gas: 21000,
			//blockGasLimit: 8000000,
			chainId: 69,
			accounts: [FUJI_PRIVATE_KEY],
			saveDeployments: true,
			deploy: ['deploy/run'],
			verify: {
				etherscan: {
					apiUrl: 'https://optimistic.etherscan.io',
					apiKey: OPTIMISM_API_KEY
				}
			}
		},
		goerli: {
			url: GOERLI_RPC_URL,
			gasPrice: 92500000000,
			gas: 21000,
			chainId: 5,
			accounts: [GOERLI_PRIVATE_KEY],
			saveDeployments: true,
			deploy: ['deploy/run'],
			verify: {
				etherscan: {
					apiUrl: 'https://goerli.etherscan.io',
					apiKey: ETHERSCAN_API_KEY
				}
			}
		},
		avax: {
			url: 'https://api.avax.network/ext/bc/C/rpc',
			gasPrice: 25000000000,
			gas: 21000,
			chainId: 43114,
			accounts: [FUJI_PRIVATE_KEY],
			saveDeployments: true,
			deploy: ['deploy/run'],
			verify: {
				etherscan: {
					apiUrl: 'https://snowtrace.io',
					apiKey: SNOWTRACE_API_KEY
				}
			}
		}
	},
	gasReporter: {
		enabled: process.env.REPORT_GAS !== undefined,
		currency: 'USD',
		token: 'AVAX',
		coinmarketcap: process.env.COINMARKETCAP_KEY,
		gasPriceApi: 'https://api.snowtrace.io/api?module=proxy&action=eth_gasPrice'
	},
	etherscan: {
		apiKey: getApiKey()
	},
	paths: {
		sources: './src/',
		tests: './test',
		cache: './cache',
		artifacts: './artifacts',
		deploy: './deploy/run',
		deployments: './deployments',
		scripts: './scripts'
	},
	mocha: {
		timeout: 2147483647
	}
}

export default config
