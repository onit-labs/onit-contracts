# Forum Group Contracts

Forum groups are [ERC4337](https://eips.ethereum.org/EIPS/eip-4337) accounts built on top of [Gnosis Safe](https://docs.gnosis.io/safe/docs/contracts_overview/) contracts. The members do not need existing EOA accounts, instead they use passkeys to generate signatures using FaceID.

## Highlights

### **Passkeys**

Users create a passkey on their phone (currently only available on iOS, requiring >v15) using FaceID or TouchID. This is securely stored in the device and is used to generate signatures for transactions. The P-256 signature is verified on-chain on the group contract.

This means **no more seed phrases**, you can add memebrs to your group by sharing a link, the new member does not need to create an EOA account to take part.

https://user-images.githubusercontent.com/68289880/225950006-dd4879ef-84a3-4ebf-9a6a-b2aba46fcc86.MP4

### **Chat focus**

Groups can discuss and execute trades directly from an in app group chat (Telegram/Discord/Messenger integrations coming soon)

https://user-images.githubusercontent.com/68289880/225950435-df2bf9d1-63d9-49d8-8b0f-9d26ea0e4ee6.mp4

### **Token tracking**

Forum groups use an [ERC-1155](https://eips.ethereum.org/EIPS/eip-1155) token to track voting power, and to determine the share of the safe treasury that each member is entitled to. Groups can even choose to mint new tokens to reward members, or build their own token gating for projects.

### **Extensions**

Forum groups will be extendedable with additional functionality, such as Fundraise to structure funding rounds, or Withdrawals to allow members to quickly withdraw their share from the group treasury. Other custom extensions for managing assets are in development, and groups can even develop their own extensions.

## Core Contracts

| Contract              |                                                               Address                                                                | Description                                     |
| :-------------------- | :----------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------- |
| Forum Group           | [0xb2F3ab6F654d2A04ec7346563677E6AF801842e0](https://mumbai.polygonscan.com/address/0xb2F3ab6F654d2A04ec7346563677E6AF801842e0#code) | ERC4337 enabled safe with P-256 passkey signers |
| Forum Group Factory   | [0x299A19b63502b63335D1ec20c9088E16Eb122071](https://mumbai.polygonscan.com/address/0x299A19b63502b63335D1ec20c9088E16Eb122071#code) | Factory for Forum Groups                        |
| Forum Account         | [0x168b03131797b2F920C2FDfFDBf1c2B0ed09e1b4](https://mumbai.polygonscan.com/address/0x168b03131797b2F920C2FDfFDBf1c2B0ed09e1b4#code) | ERC4337 enabled safe with P-256 passkey signers |
| Forum Account Factory | [0x3A004B31aF5B8337681DA2DD8c2C9073b5C4100d](https://mumbai.polygonscan.com/address/0x3A004B31aF5B8337681DA2DD8c2C9073b5C4100d#code) | Factory for Forum Groups                        |
