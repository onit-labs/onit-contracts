require('dotenv').config({ path: '.env' })

// - General
export const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL || ''
export const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || ''
export const FUJI_PRIVATE_KEY = process.env.FUJI_PRIVATE_KEY || ''
export const GOERLI_PRIVATE_KEY = process.env.GOERLI_PRIVATE_KEY || ''

// Block Explorers
export const SNOWTRACE_API_KEY = process.env.SNOWTRACE_API_KEY || ''
export const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || ''
export const POLYGONSCAN_API_KEY = process.env.POLYGONSCAN_API_KEY || ''
export const OPTIMISM_API_KEY = process.env.OPTIMISM_API_KEY || ''

// Networks
export const HARDHAT_NETWORK = process.env.HARDHAT_NETWORK || ''
export const AVAX_MAINET_CHAINID = '43114'
export const AVAX_FUJI_CHAINID = '43113'

// Storage
export const NFT_STORAGE_KEY = process.env.NFT_STORAGE_KEY || ''
export const ACCESS_PASS_METADATA =
	'https://sijfvwgogeeiztgdosfu.supabase.co/storage/v1/object/public/item-pass-metadata/'

// - Contract ABIs

// - Network Units

// OpenZeppelin Defender
export const AVAX_SHIELD_MANAGER_RELAY = '0x1309bb02f6d9bf2817eb3aae221958bd5f58f5c1'
export const AVAX_ACCESS_MANAGER_RELAY = '0xe7b6a9ae5678db8bd908db0316727ab4c4940f94'

// Tokens
export const WAVAX_MAINNET_CONTRACT_ADDRESS = '0xd00ae08403b9bbb9124bb305c09058e32c39a48c'
export const AVAX_ADDRESS = WAVAX_MAINNET_CONTRACT_ADDRESS
export const WAVAX_TESTNET_CONTRACT_ADDRESS = '0xb31f66aa3c1e785363f0875a1b74e27b85fd66c7'
export const USDC_ADDRESS = '0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e'
export const DAI_ADDRESS = '0xd586e7f844cea2f87f50152665bcbc2c279d8d70'

// Routers
export const TRADERJOE_ROUTER_ADDRESS = '0x60aE616a2155Ee3d9A68541Ba4544862310933d4'

//  Utils
export const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

// Joepegs Handler
const MATCH_ASK_WITH_TAKER_BID_USING_AVAX_AND_WAVAX_FUNCTION_SIG = '0x97800e4d'
const MATCH_ASK_WITH_TAKER_BID_FUNCTION_SIG = '0x38e29209'
const MATCH_BID_WITH_TAKER_ASK_FUNCTION_SIG = '0x3b6d032e'
const CANCEL_ALL_ORDERS_FOR_SENDER_FUNCTION_SIG = '0xcbd2ec65'
const CANCEL_MULTIPLE_MAKER_ORDERS_FUNCTION_SIG = '0x9e53a69a'

export const COMMISSION_FREE_FUNCTIONS = [
	CANCEL_MULTIPLE_MAKER_ORDERS_FUNCTION_SIG,
	CANCEL_ALL_ORDERS_FOR_SENDER_FUNCTION_SIG
]
export const COMMISSION_BASED_FUNCTIONS = [
	MATCH_ASK_WITH_TAKER_BID_USING_AVAX_AND_WAVAX_FUNCTION_SIG,
	MATCH_ASK_WITH_TAKER_BID_FUNCTION_SIG,
	MATCH_BID_WITH_TAKER_ASK_FUNCTION_SIG
]
