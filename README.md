# Forum Group Contracts

Forum groups are [ERC4337](https://eips.ethereum.org/EIPS/eip-4337) accounts built on top of [Gnosis Safe](https://docs.gnosis.io/safe/docs/contracts_overview/) contracts. The members do not need existing EOA accounts, instead they use passkeys to generate signatures using FaceID.

<br>

## Highlights

</br>

### **Passkeys**

Users create a passkey on their phone (currently only available on iOS, requiring >v15) using FaceID or TouchID. This is securely stored in the device and is used to generate signatures for transactions. The P-256 signature is verified on-chain on the group contract.

This means **no more seed phrases**, you can add memebrs to your group by sharing a link, the new member does not need to create an EOA account to take part.

### **Chat focus**

Groups can discuss and execute trades directly from an in app group chat (Telegram/Discord/Messenger integrations coming soon)

</br>

### **Token tracking:**

Forum groups use an [ERC-1155](https://eips.ethereum.org/EIPS/eip-1155) token to track voting power, and to determine the share of the safe treasury that each member is entitled to. Groups can even choose to mint new tokens to reward members, or build their own token gating for projects.

### **Extensions:**

Forum groups will be extendedable with additional functionality, such as Fundraise to structure funding rounds, or Withdrawals to allow members to quickly withdraw their share from the group treasury. Other custom extensions for managing assets are in development, and groups can even develop their own extensions.

<br	>
<br	>

## Core Contracts

| Contract            |                                                               Address                                                                | Description                                     |
| :------------------ | :----------------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------- |
| Forum Group         | [0xd7f6b767cE27862Bb4B882D253789084D003abc2](https://mumbai.polygonscan.com/address/0xd7f6b767cE27862Bb4B882D253789084D003abc2#code) | ERC4337 enabled safe with P-256 passkey signers |
| Forum Group Factory | [0x3A1A2f67A9F42b186be986CbD4D18F2a1c0fd665](https://mumbai.polygonscan.com/address/0x3A1A2f67A9F42b186be986CbD4D18F2a1c0fd665#code) | Factory for Forum Groups                        |
|                     |

<br>
