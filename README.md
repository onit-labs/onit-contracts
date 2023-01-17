# Forum Group Contracts

Forum groups are built on top of [Gnosis Safe](https://docs.gnosis.io/safe/docs/contracts_overview/) contracts. The Forum Safe Module adds governace and token tracking to the Safe, and even allows for further extensions to be added.

<br>
<br>

**Benefits include:**

-   **Token tracking:** Forum groups use an [ERC-1155](https://eips.ethereum.org/EIPS/eip-1155) token to track voting power, and to determine the share of the safe treasury that each member is entitled to. Groups can even choose to mint new tokens to reward members, or build their own token gating for projects.
-   **Faster Execution:** Transactions can be executed on the Safe without having to wait for a previous transaction to be processed. Guards can be enabled to prevent this if desired.
-   **Extensions:** Forum groups can be extended with additional functionality, such as Fundraise to structure funding rounds, or Withdrawals to allow members to quickly withdraw their share from the group treasury. Other custom extensions for managing assets are in development, and groups can even develop their own extensions.

<br	>
<br	>

## Core Contracts

| Contract           |                                                              Address                                                               | Description                                                 |
| :----------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------------------- |
| Forum Safe Module  | [0x85B202bb2d68dC24b31faF06F6895Cc71C5F4b5A](https://testnet.snowtrace.io/address/0x85B202bb2d68dC24b31faF06F6895Cc71C5F4b5A#code) | Gnosis Safe module with Forum governance and token tracking |
| Forum Safe Factory | [0x652B0E6B8C1fD7519152F233e125213a64d8125c](https://testnet.snowtrace.io/address/0x652B0E6B8C1fD7519152F233e125213a64d8125c#code) | Factory for Gnosis Safe Forum module                        |
|  |

<br>

## Extensions

| Contract   |                                                              Address                                                               | Description                                                                      |
| :--------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------- |
| Fundraise  | [0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd](https://testnet.snowtrace.io/address/0x76cF12497A6d9b314149Eb8CceDbAF001cA9d1fd#code) | Lets the group raise funds and distribute group tokens to contributors           |
| Withdrawal | [0x601fB2a8e98411cc4cBA3663f4841A7E36455a34](https://testnet.snowtrace.io/address/0x601fB2a8e98411cc4cBA3663f4841A7E36455a34#code) | Lets members set basic withdrawal tokens, or create a custom withdrawal proposal |
| PfpStaker  | [0x579b986a23393A0EA4D2981073b3c9b819c21643](https://testnet.snowtrace.io/address/0x579b986a23393A0EA4D2981073b3c9b819c21643#code) | Stakes pfp for group and generates token uri                                     |

<br>
<br>

## Utilities

| Contract                    |                                                              Address                                                               | Description                                            |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------- |
| Withdrawal Transfer Manager | [0xAAd9FdF1f41298FD2C5b3d48a4088FfFcA8B74cD](https://testnet.snowtrace.io/address/0xAAd9FdF1f41298FD2C5b3d48a4088FfFcA8B74cD#code) | Create the payloads needed for withdrawals from groups |
| Joepegs Proposal Handler    | [0xA50dACe79A5b55332b31FeEfe56107C6359De19e](https://testnet.snowtrace.io/address/0xA50dACe79A5b55332b31FeEfe56107C6359De19e#code) | Handler for joepegs orders                             |

<br>

<br>
<br>

# Forum Crowdfunds

Forum Crowdfunds are a way to pool funds to buy any NFT. Anyone can start a crowdfund and when the target is reached, the NFT is purchased and all ccontributors are added as owners to a Forum Group, with each receiving a share of the treasury proportional to their contribution.

| Contract                  |                                                              Address                                                               | Description                                                                          |
| :------------------------ | :--------------------------------------------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------------- |
| Crowdfund                 | [0x88Af3DfB1CfC14032bcd392F26e91B30C2a717D9](https://testnet.snowtrace.io/address/0x88Af3DfB1CfC14032bcd392F26e91B30C2a717D9#code) | Lets people pool funds to buy an NFT, then creates a Forum group to manage the asset |
| Execution Manager         | [0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68](https://testnet.snowtrace.io/address/0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68#code) | Create the payloads needed for withdrawals from groups                               |
| Joepegs Crowdfund Handler | [0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3](https://testnet.snowtrace.io/address/0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3#code) | Creates transfer payload based of Joepegs order                                      |
