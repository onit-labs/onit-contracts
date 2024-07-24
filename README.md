# Onit Contracts

Onit accounts are a fork of the [Base Smart Wallet](https://github.com/coinbase/smart-wallet). They are deigned to easily onboard new users with passkeys, and have been modified to allow the account to easily work as an owner on a Safe. 

## Highlights

### **Passkeys**

New users create a passkey on their phone (currently only available on iOS, requiring >v15) using FaceID or TouchID. This is securely stored and is used to generate signatures for transactions. The P-256 signature is verified on-chain on the Onit contract.

This means **no more seed phrases**, you can add new memebrs to your Safe by sharing a link, the new member does not need to create an EOA account to take part.

https://github.com/onit-labs/onit-contracts/assets/68289880/b74d5d6e-79e3-4b98-97d4-aca08f25144b

### **Chat focus**

Groups can discuss and execute trades directly from an [XMTP](https://xmtp.org/) group chat

https://github.com/onit-labs/onit-contracts/assets/68289880/475d865e-a1ba-4d6f-a27e-68373df5a543


### **Extensions**

Onit groups will be extendedable with additional functionality, such as Fundraise to structure funding rounds, or Withdrawals to allow members to quickly withdraw their share from the group treasury. Other custom extensions for managing assets are in development, and groups can even develop their own extensions.

## Core Contracts

| Contract              |                                                            Address                                                            | Description                                     |
| :-------------------- | :---------------------------------------------------------------------------------------------------------------------------: | :---------------------------------------------- |
 Onit Account         | [0xe324DA4192aA61684717C2F8C994Ee0C34B15B72](https://sepolia.basescan.org/address/0xe324da4192aa61684717c2f8c994ee0c34b15b72#code) | Smart wallet with EOA or passkey owners   |
| Onit Account Factory | [0x8472B610aDEabC68ebb27069EE18d88dF7254B2B](https://sepolia.basescan.org/address/0x8472b610adeabc68ebb27069ee18d88df7254b2b#code) | Factory for Onit Accounts                      |

<br>
<br>
