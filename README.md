# Forum Contracts

## Fuji

| Contract          |                                                              Address                                                               | Description                                                     |
| :---------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------- |
| FieldGenerator    | [0x937aae28db4b2bbe9041e1467c47b987ca91e2e5](https://snowtrace.io/address/0x937aae28db4b2bbe9041e1467c47b987ca91e2e5#code) | Shield backgroud pattern                                        |
| HardwareGenerator |   [0xca09d739fab967b3698837367aa5445bd895ce58](https://snowtrace.io/address/0xca09d739fab967b3698837367aa5445bd895ce58#code)    | Shield hardware item                                            |
| FrameGenerator    |   [0x9400fd868861ba3527e301f5ea3fbfcacc30fa94](https://snowtrace.io/address/0x9400fd868861ba3527e301f5ea3fbfcacc30fa94#code)    | Shield frame                                                    |
| EmblemWeaver      |   [0xdf4823ad63af19651b05986c848d751886294843](https://snowtrace.io/address/0xdf4823ad63af19651b05986c848d751886294843#code)    | Combines the svgs produced by the above 3 into the final shield |
| AccessManager     |   [0xB3b9fcA694A9adC3Cb70AAc730f956931A184d70](https://snowtrace.io/address/0xB3b9fcA694A9adC3Cb70AAc730f956931A184d70#code)    | Stores all Forum access items + permits claiming WL        |
| ShieldManager     |   [0xC7ACEdB44CC842dfCeB13a7bDCfC027D2312CcB7](https://snowtrace.io/address/0xC7ACEdB44CC842dfCeB13a7bDCfC027D2312CcB7#code)    | Mint and build the shields produced above                       |
| ForumGroup     |   [0x00a72723e59e36E762e1e5f86Baf849E9B08BCA3](https://testnet.snowtrace.io/address/0x00a72723e59e36E762e1e5f86Baf849E9B08BCA3)    | The group multisig with governance                              |
| ForumFactory | [0x7BB55BAdDE80C6EFE41CB978415fd8E358cbF678](https://testnet.snowtrace.io/address/0x7BB55BAdDE80C6EFE41CB978415fd8E358cbF678) | Generates clones of the above and mints a shield for each       |
| PfpStaker         | [0xc5acDc2B0D21627D10Dd938e3f7bb664360b7e46](https://snowtrace.io/address/0xc5acDc2B0D21627D10Dd938e3f7bb664360b7e46#code) | Staking pfp for group                                           |
| Delegator         |   [0x84d970e8045b4E314e28659df1C7Ec6101f99283](https://testnet.snowtrace.io/address/0x84d970e8045b4E314e28659df1C7Ec6101f99283#code)    | (extension) Option to delegate voting via a seperate contract   |
| ForumGroupFundraise         |   [0x353F4a6ABCe3121402131BD627572eA137D1660f](https://testnet.snowtrace.io/address/0x353F4a6ABCe3121402131BD627572eA137D1660f#code)    | (extension) Create a fundraise round for all members   |
| ExecutionManager         |   [0xc42b16D1d254C2650888994423bFb40429460081](https://testnet.snowtrace.io/address/0xc42b16D1d254C2650888994423bFb40429460081#code)    | Handles routing of transaction to handler   |
| JoepegsProposalHandler         |   [0x6Fe187806489D4E0e04fEe4a48DdE19cD2FB8A4F](https://testnet.snowtrace.io/address/0x6Fe187806489D4E0e04fEe4a48DdE19cD2FB8A4F#code)    | Handler for joepegs orders   |


<br>

## Relays
To enable gasless transactions for certiain actions relay contracts from [Open Zeppelin Defender](https://docs.openzeppelin.com/defender/) are used. Autotasks are written in the [oz-defender](../oz-defender/) package and are used to automatically call contracts based on user inputs / database updates.


| Contract          |                                                              Address                                                               | Description                                                     |
| :---------------- | :--------------------------------------------------------------------------------------------------------------------------------: | :-------------------------------------------------------------- |
| AccessManager    | 0xe7b6a9ae5678db8bd908db0316727ab4c4940f94 | Claims whitelist or mints an item                          ||
| ForumFactory    |   0x7077644742aef5dc9345dcdacfeb2e85ce57ecd5)    | Deploys a forum                                                    |
| ShieldManager      |   0x1309bb02f6d9bf2817eb3aae221958bd5f58f5c1   | Mints a shield pass |
| 


<br>
<br>

> ⚠️ ***WARNING*** when deploying SVGs, set ```	metadata: { bytecodeHash: 'none'}``` in hardhatConfig to maintain same address cross chain