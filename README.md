# Bad Baby Bear Bots Smart Contracts

> WARNING: The contracts provided here are as is. BBBB does not 
warrant that these will work on a live environment. It is possible 
that these contracts are out dated and it is possible for Gratitude to 
update these contracts without prior notification. Use at your own risk.

The contracts defined here are to allow auditors to evaluate the code 
that are being developed and specifically for the purpose of the 
Gratitude NFT project. 

Official Website: [https://www.badbabybearbots.com/](https://www.badbabybearbots.com/)
White Paper: [https://docs.google.com/document/d/1WOZT4IzW9-pRdN9mGkqC4G8YFxXeuy-m9QvMcNw4_sE](https://docs.google.com/document/d/1WOZT4IzW9-pRdN9mGkqC4G8YFxXeuy-m9QvMcNw4_sE)

## 1. Provenance Strategy

The following describes how this project will implement a fair NFT
sale and minting.

 1. Art will be generated using an art engine similar to [this](https://github.com/HashLips/hashlips_art_engine).
 2. The final generated art will be hashed using [CIDs](https://docs.ipfs.io/concepts/content-addressing/) 
    and each art CID will be added to its relative metadata.
 3. Each art metadata will be hashed using [CIDs](https://docs.ipfs.io/concepts/content-addressing/) 
    and the provenance hash will be a sequence of these.
 4. Before the NFT sale, the art as well as the provenance hash will be 
    posted.
 5. When the contract is deployed, the code will reserve the first 16 NFTs for the team. 
 6. The sale will begin as described on the `START_DATE` specified in 
    `BadBabyBearBotsCollection.sol`. Minting merely assigns token IDs to owners.
 7. No art will be revealed *(assigned to a token ID)* until `withdraw` 
    is called, in which the starting image assigned will depend 
    on the last block number recorded.

## 2. Self Regulation

The following describes how the contracts will prevent any scams and/or
rug pulls on our side.

 1. The `BadBabyBearBotsCollection.sol` has the BBBB multisig wallet 
    and the DAO hard coded when deployed. In the `withdraw` function
    the funds will be transferred to only these contracts and cannot 
    change (immutable)
 2. The `BBBBMultisigWallet.sol` will be the only smart wallet used to 
    disburse funds to suppliers. Requesters and approvers will be 
    assigned at the discretion of BBBB. The wallet will prevent 
    requests more than **20 ETH**
 2. The `BBBBDAOFI.sol` will be the only smart wallet used to disburse 
    funds to NFT and blockchain projects. Requesters can only be BBBB 
    and approvers can only be NFT holders. The wallet will prevent 
    requests more than **5 ETH**

### Preventing Rug Pulls from the Multisig Wallet

Only 1 request per teir is allowed per respective cooldown. This means
it would take at best 10 months to withdraw 465 ETH. 

<pre>
·------------------|------------|------------|----------------·
| Threshold        · Approvers  · Cooldown   · Max per Month  |
···················|············|············|·················
| Up to 0.05 ETH   ·     1      · 1 day      · 1.5 ETH        |
···················|············|············|·················
| Up to 0.50 ETH   ·     2      · 3 days     · 5 ETH          |
···················|············|············|·················
| Up to 5.00 ETH   ·     3      · 7 days     · 20 ETH         |
···················|············|············|·················
| Up to 20.0 ETH   ·     4      · 30 days    · 20 ETH         |
·------------------|------------|------------|----------------·
| Total                                        46.5 ETH       |
·------------------|------------|------------|----------------·
</pre>

All transactions have metadata with more information about each 
transaction. It would look like the following. The total of the 
amount should be equal to the request amount.

```json
[
   {
      "amount": "0.00001",
      "beneficiary": "Netlify",
      "purpose": "Serverless charge",
      "website": "https://netlify.com",
      "reference": 10000000
   },
   {
      "amount": "0.05",
      "beneficiary": "Designer A",
      "purpose": "Payment for Invoice",
      "reference": 10000001
   }
]
```

### Preventing Rug Pulls from the DAO

The following table shows all the possible tier approvals.

<pre>
·------------------|------------·
| Threshold        · Approvers  |
···················|·············
| Up to 0.1 ETH    ·     1      | 
···················|·············
| Up to 0.5 ETH    ·     2      |
···················|·············
| Up to 1.0 ETH    ·     3      |
···················|·············
| Up to 5.0 ETH    ·     4      |
·------------------|------------·
</pre>

All transactions have metadata with more information about each 
transaction. It would look like the following. The total of the 
amount should be equal to the request amount.

```json
{
   "amount": "0.1",
   "beneficiary": "An external NFT Project",
   "purpose": "Gas",
   "website": "https://nft-example.com/",
   "reference": 10000000
}
```

## 3. Auditing

### Install

```bash
$ cp .env.sample to .env
$ npm install
```

You will need to provide a private key to deploy to a testnet and a 
Coin Market Cap Key to see gas price conversions when testing.

### Testing

Make sure in `.env` to set the `BLOCKCHAIN_NETWORK` to `hardhat`.

```bash
$ npm test
```

### Reports

The following is an example gas report from the tests ran in this 
project and could change based on the cost of `ETH` itself.

<pre>
·-------------------------------------------|---------------------------|-------------|-----------------------------·
|            Solc version: 0.8.9            ·  Optimizer enabled: true  ·  Runs: 200  ·  Block limit: 12450000 gas  │
············································|···························|·············|······························
|  Methods                                  ·              200 gwei/gas               ·       2390.37 usd/eth       │
······························|·············|·············|·············|·············|···············|··············
|  Contract                   ·  Method     ·  Min        ·  Max        ·  Avg        ·  # calls      ·  usd (avg)  │
······························|·············|·············|·············|·············|···············|··············
|  BadBabyBearBotsCollection  ·  mint       ·     158992  ·     277577  ·     218285  ·            2  ·     104.36  │
······························|·············|·············|·············|·············|···············|··············
|  BadBabyBearBotsCollection  ·  withdraw   ·          -  ·          -  ·      64994  ·            1  ·      31.07  │
······························|·············|·············|·············|·············|···············|··············
|  BBBBMultisigWallet         ·  approve    ·      58044  ·      75144  ·      66594  ·            4  ·      31.84  │
······························|·············|·············|·············|·············|···············|··············
|  BBBBMultisigWallet         ·  grantRole  ·     101228  ·     118328  ·     104078  ·            6  ·      49.76  │
······························|·············|·············|·············|·············|···············|··············
|  BBBBMultisigWallet         ·  request    ·      81743  ·      86413  ·      84078  ·            2  ·      40.20  │
······························|·············|·············|·············|·············|···············|··············
|  BBBBMultisigWallet         ·  withdraw   ·          -  ·          -  ·      64891  ·            2  ·      31.02  │
······························|·············|·············|·············|·············|···············|··············
|  Deployments                              ·                                         ·  % of limit   ·             │
············································|·············|·············|·············|···············|··············
|  BadBabyBearBotsCollection                ·          -  ·          -  ·    7066154  ·       56.8 %  ·    3378.14  │
············································|·············|·············|·············|···············|··············
|  BBBBMultisigWallet                       ·          -  ·          -  ·    1944767  ·       15.6 %  ·     929.74  │
·-------------------------------------------|-------------|-------------|-------------|---------------|-------------·
</pre>

### Verifying Contracts

```bash
$ npx hardhat verify --network testnet 0x12345678890 ""
```