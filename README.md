# Forum Contracts

## Core Contracts

| Contract     |                                                              Address                                                               | Description                                  |
| :----------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------- |
| ForumGroup   |   [0x57D4Ee29103D88eF61863e431eedF84d3af63663](https://testnet.snowtrace.io/address/0x57D4Ee29103D88eF61863e431eedF84d3af63663)    | The group multisig with governance           |
| ForumFactory |   [0x2fb3C50CbE919Bb9d2Cc6dd38955685b909647DA](https://testnet.snowtrace.io/address/0x2fb3C50CbE919Bb9d2Cc6dd38955685b909647DA)    | Generates clones of the Forum group          |
| PfpStaker    | [0xd841FA25916660ac0E2E24186aC1e7a065842e13](https://testnet.snowtrace.io/address/0xd841FA25916660ac0E2E24186aC1e7a065842e13#code) | Stakes pfp for group and generates token uri |

<br>

## Extensions

| Contract   |                                                              Address                                                               | Description                                                                      |
| :--------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------- |
| Fundraise  | [0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd](https://testnet.snowtrace.io/address/0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd#code) | Lets the group raise funds and distribute group tokens to contributors           |
| Withdrawal | [0x1960F4c8652322bb0094e378d63C0c5d24C6d1DD](https://testnet.snowtrace.io/address/0x1960F4c8652322bb0094e378d63C0c5d24C6d1DD#code) | Lets members set basic withdrawal tokens, or create a custom withdrawal proposal |

<br>

## Crowdfund

| Contract                  |                                                              Address                                                               | Description                                                                          |
| :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------- |
| Crowdfund                 | [0xF1e58124bf242Db492838486Fdb6807361376a46](https://testnet.snowtrace.io/address/0xF1e58124bf242Db492838486Fdb6807361376a46#code) | Lets people pool funds to buy an NFT, then creates a Forum group to manage the asset |
| Execution Manager         | [0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68](https://testnet.snowtrace.io/address/0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68#code) | Create the payloads needed for withdrawals from groups                               |
| Joepegs Crowdfund Handler | [0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3](https://testnet.snowtrace.io/address/0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3#code) | Creates transfer payload based of Joepegs order                                      |

<br>

## Utilities

| Contract                    |                                                              Address                                                               | Description                                              |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------- |
| Commission Manager          | [0xdc7b525229B59C575DaCE87efD56f6f1Ed6d8D10](https://testnet.snowtrace.io/address/0xdc7b525229B59C575DaCE87efD56f6f1Ed6d8D10#code) | Handles taking of commission on certain target contracts |
| Withdrawal Transfer Manager | [0xAAd9FdF1f41298FD2C5b3d48a4088FfFcA8B74cD](https://testnet.snowtrace.io/address/0xAAd9FdF1f41298FD2C5b3d48a4088FfFcA8B74cD#code) | Create the payloads needed for withdrawals from groups   |
| Joepegs Proposal Handler    | [0xA50dACe79A5b55332b31FeEfe56107C6359De19e](https://testnet.snowtrace.io/address/0xA50dACe79A5b55332b31FeEfe56107C6359De19e#code) | Handler for joepegs orders                               |

<br>

## Relays

To enable gasless transactions for certiain actions relay contracts from [Open Zeppelin Defender](https://docs.openzeppelin.com/defender/) are used. Autotasks are written in the [oz-defender](../oz-defender/) package and are used to automatically call contracts based on user inputs / database updates.

| Contract     |                   Address                   |   Description   |
| :----------- | :-----------------------------------------: | :-------------: |
| ForumFactory | 0x7077644742aef5dc9345dcdacfeb2e85ce57ecd5) | Deploys a forum |

<br>
<br>
