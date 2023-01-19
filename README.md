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
| Forum Safe Module  | [0x81d724075B62a946CeAAEbd4852525C2dbE44E98](https://testnet.snowtrace.io/address/0x81d724075B62a946CeAAEbd4852525C2dbE44E98#code) | Gnosis Safe module with Forum governance and token tracking |
| Forum Safe Factory | [0x860A37200f9d17192DAD728123A375C87585112B](https://testnet.snowtrace.io/address/0x860A37200f9d17192DAD728123A375C87585112B#code) | Factory for Gnosis Safe Forum module                        |
|                    |

<br>

## Extensions

| Contract   |                                                              Address                                                               | Description                                                                      |
| :--------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------------------------------- |
| Fundraise  | [0x9936d6c44eaAFF3cc6817fcF34daE252f87874A5](https://testnet.snowtrace.io/address/0x9936d6c44eaAFF3cc6817fcF34daE252f87874A5#code) | Lets the group raise funds and distribute group tokens to contributors           |
| Withdrawal | [0x058AD8E9f0100f11FdCd4E8B4EF42814cc9373C9](https://testnet.snowtrace.io/address/0x058AD8E9f0100f11FdCd4E8B4EF42814cc9373C9#code) | Lets members set basic withdrawal tokens, or create a custom withdrawal proposal |
| PfpStaker  | [0x35f360330a3dd93461425CAb759b649586e061f0](https://testnet.snowtrace.io/address/0x35f360330a3dd93461425CAb759b649586e061f0#code) | Sets pfp for group and generates token uri                                       |

<br>
<br>

## Utilities

| Contract                    |                                                              Address                                                               | Description                                               |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------- |
| Withdrawal Transfer Manager | [0x6136dA2b7e226C9425D2784E8a6e56E68C02aa79](https://testnet.snowtrace.io/address/0x6136dA2b7e226C9425D2784E8a6e56E68C02aa79#code) | Create the payloads needed for withdrawals from groups    |
| Joepegs Proposal Handler    | [0xA50dACe79A5b55332b31FeEfe56107C6359De19e](https://testnet.snowtrace.io/address/0xA50dACe79A5b55332b31FeEfe56107C6359De19e#code) | Handler for joepegs orders                                |
| Pfp Store                   | [0xFe5f35876fD6d90b5F6E893FDB81bd6339E3f3fb](https://testnet.snowtrace.io/address/0xFe5f35876fD6d90b5F6E893FDB81bd6339E3f3fb#code) | Store where collections can add uris to display on tokens |

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
