# Forum Contracts

## Core Contracts

| Contract     |                                                              Address                                                               | Description                                  |
| :----------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------- |
| ForumGroup   |   [0xDe497d34Fe6A731459Bd6aeFd943A2FD2D684eAC](https://testnet.snowtrace.io/address/0xDe497d34Fe6A731459Bd6aeFd943A2FD2D684eAC)    | The group multisig with governance           |
| ForumFactory |   [0x2907657eD64b0127D29C0039013CD20cDDd370d3](https://testnet.snowtrace.io/address/0x2907657eD64b0127D29C0039013CD20cDDd370d3)    | Generates clones of the Forum group          |
| PfpStaker    | [0x579b986a23393A0EA4D2981073b3c9b819c21643](https://testnet.snowtrace.io/address/0x579b986a23393A0EA4D2981073b3c9b819c21643#code) | Stakes pfp for group and generates token uri |

<br>

## Extensions

| Contract   |                                                              Address                                                               | Description                                                                      |
| :--------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------- |
| Fundraise  | [0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd](https://testnet.snowtrace.io/address/0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd#code) | Lets the group raise funds and distribute group tokens to contributors           |
| Withdrawal | [0x601fB2a8e98411cc4cBA3663f4841A7E36455a34](https://testnet.snowtrace.io/address/0x601fB2a8e98411cc4cBA3663f4841A7E36455a34#code) | Lets members set basic withdrawal tokens, or create a custom withdrawal proposal |

<br>

## Crowdfund

| Contract                  |                                                              Address                                                               | Description                                                                          |
| :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------- |
| Crowdfund                 | [0x88Af3DfB1CfC14032bcd392F26e91B30C2a717D9](https://testnet.snowtrace.io/address/0x88Af3DfB1CfC14032bcd392F26e91B30C2a717D9#code) | Lets people pool funds to buy an NFT, then creates a Forum group to manage the asset |
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
