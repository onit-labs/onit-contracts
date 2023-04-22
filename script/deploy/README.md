# Deployment

## TODO

-   detail how to use the deployer lib

## Deploying a contract (for now)

yarn deploy SCRIPT_NAME CHAIN_NAME b

-   omit 'b' to not broadcast the transaction, for testing deployer locally
-   If deployment fails, adding `--gas-limit X --gas-price Y --nonce Z` may avoid `"code: -32000, message: already known, data: None"`
