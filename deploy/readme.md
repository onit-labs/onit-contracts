# 1) Deploy

[Hardhat-Deploy](https://github.com/wighawag/hardhat-deploy) adds some great functions to hardhat for deploying, documenting, and testing contracts. It will run the deploy scripts in the folder **deploy/run**. Tags exist at the bottom of each file and can be used to run specific files. 

**To deploy the contracts:**

1. See the tag indicating the file or files to run.

```
func.tags = ['SVG']
```

2. Run

```
yarn hardhat deploy --network fuji --tags SVG
```

_omit --tags to run all files_

Once deployed a 'deployments' folder will be created in the 'contracts' folder which includes a breakdown of each deployment and the contract (constructor args etc)

<br/>

*Running the [00_deploy_SVGs.ts](./run/00_deploy_SVGs.ts) file will deploy all files in the [SVGs](../contracts/ShieldManager/SVGs) folder and write the details to a file called deployedSVGs_NETWORK.json file. This file will be used in the other deploy files and so the SVGs must be deployed before the regular Shield deploy files are run.*

<br/>

# 2) Verification


**To verify contracts, after successfully deploying run the following command**

```
yarn hardhat ts-node scripts/verifyDeployments.ts CONTRACT_NAME1 CONTRACT_NAME2 ...
```

Where CONTRACT_NAME1, CONTRACT_NAME2 etc are the names of the contracts you want to verify. If no contracts are listed, all contracts in the deployments folder will be verified.

```HARDHAT_NETWORK``` in the .env file should be set to match the network where verification will take place 


# 3) ABI Update
**To use the contracts in the frontend, the config/contracts.ts file needs updated**

1) Update `config/contracts.ts` and `abis/internal/addresses.ts` files with the latest contract info


2) Update the abis
```
yarn ts-node scripts/update-contract-abis.ts
```
