# Onit Contracts

Onit accounts are [ERC4337](https://eips.ethereum.org/EIPS/eip-4337) accounts built on top of [Safe](https://safe.global/wallet) contracts. 

## Highlights

### **Passkeys**

New users create a passkey on their phone (currently only available on iOS, requiring >v15) using FaceID or TouchID. This is securely stored and is used to generate signatures for transactions. The P-256 signature is verified on-chain on the Onit contract.

This means **no more seed phrases**, you can add new memebrs to your Safe by sharing a link, the new member does not need to create an EOA account to take part.

https://github.com/onit-labs/onit-contracts/assets/68289880/b74d5d6e-79e3-4b98-97d4-aca08f25144b

### **Chat focus**

Groups can discuss and execute trades directly from an in app group chat (Telegram/Discord/Messenger integrations coming soon)

https://user-images.githubusercontent.com/68289880/225950435-df2bf9d1-63d9-49d8-8b0f-9d26ea0e4ee6.mp4

### **Extensions**

Onit groups will be extendedable with additional functionality, such as Fundraise to structure funding rounds, or Withdrawals to allow members to quickly withdraw their share from the group treasury. Other custom extensions for managing assets are in development, and groups can even develop their own extensions.

## Core Contracts

| Contract              |                                                            Address                                                            | Description                                     |
| :-------------------- | :---------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------- |
 Onit Account         | [0xf43a5dB4f70A14bbDdaC363bE8a1Cd2278bEc922](https://sepolia.basescan.org/address/0xf43a5db4f70a14bbddac363be8a1cd2278bec922#code) | ERC4337 enabled Safe with P-256 passkey owner   |
| Onit Account Factory | [0xEcCF89c619DaDf187fd3C5CeFf4C1106DaF8d109](https://sepolia.basescan.org/address/0xEcCF89c619DaDf187fd3C5CeFf4C1106DaF8d109#code) | Factory for Onit Accounts                      |

<br>
<br>
