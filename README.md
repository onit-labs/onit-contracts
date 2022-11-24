# Forum Contracts

## Core Contracts

| Contract     |                                                              Address                                                               | Description                                  |
| :----------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------- |
| ForumGroup   |   [0x652041584f7605cba3C5A66fe77Baaeb2816990d](https://testnet.snowtrace.io/address/0x652041584f7605cba3C5A66fe77Baaeb2816990d)    | The group multisig with governance           |
| ForumFactory |   [0x3a5f7f4bf6DcF427AC6e2ddA012843f3FCfbb3A3](https://testnet.snowtrace.io/address/0x3a5f7f4bf6DcF427AC6e2ddA012843f3FCfbb3A3)    | Generates clones of the Forum group          |
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
| Crowdfund                 | [0xe4Cb2539c1086F31eb2de09b69E5469aE8D23330](https://testnet.snowtrace.io/address/0xe4Cb2539c1086F31eb2de09b69E5469aE8D23330#code) | Lets people pool funds to buy an NFT, then creates a Forum group to manage the asset |
| Execution Manager         | [0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68](https://testnet.snowtrace.io/address/0x6DB6ad1b71b8566beAE682D0aF65E077850dAB68#code) | Create the payloads needed for withdrawals from groups                               |
| Joepegs Crowdfund Handler | [0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3](https://testnet.snowtrace.io/address/0xC9aAD4cB61138DE087E3D7A580988dA52017e4A3#code) | Creates transfer payload based of Joepegs order                                      |

<br>

## Utilities

| Contract                    |                                                              Address                                                               | Description                                              |
| :-------------------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :------------------------------------------------------- |
| Commission Manager          | [0x860693ca96B6Dfe9222fcD4bb0bf3D3C227700A2](https://testnet.snowtrace.io/address/0x860693ca96B6Dfe9222fcD4bb0bf3D3C227700A2#code) | Handles taking of commission on certain target contracts |
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
