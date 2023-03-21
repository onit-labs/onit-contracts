# Deployment

## TODO

-   detail how to use the deployer lib
-   build all varaibles into the deployer via env

## Deploying a contract (for now)

forge deploy [SCRIPT_NAME] [RPCURL] [CHAIN_ID] [PRIVATE_KEY] [ETHERSCAN_API_KEY] --broadcast

-   omit --broadcast to test local
-   If deployment fails, adding `--gas-limit X --gas-price Y --nonce Z` may avoid `"code: -32000, message: already known, data: None"`
