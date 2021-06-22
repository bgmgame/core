require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html

const accounts = {
  mnemonic: process.env.MNEMONIC || "test test test test test test test test test test test junk",
  // initialIndex: 18
  // accountsBalance: "990000000000000000000",
}

task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.5.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey:"6IQTZTMD392X2U2SYZBABWDS8KB6D8UD4T"
  },
  defaultNetwork: "local",
  networks: {
    local: {
      url: `http://localhost:8545`,
      accounts,
      attachs:{
           feeTo: "0xbcd4042de499d14e55001ccbb24a551f3b954096",//accounts[10]
           dev:'0xcd3B766CCDd6AE721141F452C550Ca635964ce71',//acount[15]
           wbnb:"0x5FbDB2315678afecb367f032d93F642f64180aa3",
           usdt:"0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
           busd:"0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
           husd:"0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
           dai:"0xa62835D1A6bf5f521C4e2746E1F51c923b8f3483",
           ut:"0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
           bgm:'0x5f3f1dBD7B74C6B46e8c44f98792A1dAf8d69154',

           router:"0x224d544641969f228d81a4F7635AE92A18EC995c",
           
           bgmpool:'0x06816f66538CB5bf17243F6C404D841e0ac96B69',

           refstore:"0x2Dd78Fd9B8F40659Af32eF98555B8b31bC97A351",
           refs:"0x81AE7583f06C2Bc141b9141FB9D701F0F2f59133",
           
           lp:"0x68F5621191A75aa1212dbC49d7A8512Af059fb7F",
           profitshare:"0x359570B3a0437805D0a71457D61AD26a28cAC9A2",
           repurchase:"0xc9952Fc93Fa9bE383ccB39008c786b9f94eAc95d",
           bgmbackup:"0xDde063eBe8E85D666AD99f731B4Dbf8C98F29708",
           nonfeelender:'0xB3650921A544d33190F1A4740bE423Ec713980eE',
           
      }
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      gasPrice: 120 * 1000000000,
      chainId: 1,
    },
    heco:{
      url: `https://http-mainnet-node.huobichain.com`,
      accounts,
      gasPrice: 1*1000000000,
      chainId: 128,
      loggingEnabled: true,
      blockGasLimit:0x280de80,
      attachs:{
          fee: "0xC18f3F15aa3c72A3592D281941d6dAaCF4769bE6",
          aaa:"0x3FB9ff40B3783370a43E383818ED8871598BeA44",
          bbb:"0x410787af2871D0c18A74065CA35e860ee66f8A35",
          ccc:"0xCA55A6c422D93f42087B635faC014f7946DEeF5d",
          ddd:"0x9902DDb630D9528d5BdAFac5e6a78BC1181fDD70",
           usdt:"0xa71edc38d189767582c38a3145b5873052c3e47a",
           husd:"0x0298c2b32eae4da002a15f36fdf7615bea3da047",
           wht :"0x5545153ccfca01fbd7dd11c0b23ba694d9509a6f",
           uniswap:{
             factory:"0x92e68911333e95D9a495eCd1e92ad3Db72043567",
             router: "0xB2A9BC4ddEE98B59A6db85275eB39e408aef6c7D",
           },
           bgm : "0xD194759Dca7bC007E126eAf5d7981b58621C15BC",
           feecollector: "0x8E7B480ABDF2144939459236431F0a032Af8B6E0",
           tokenlock: "0x8f1699346fbE3BD9E152D2B760727455AEaa6D0B",
           sweeper: "0xC18f3F15aa3c72A3592D281941d6dAaCF4769bE6",
           references: "0x598105a9ff477a510C24f6afd2DB4ac0bFd2166B",
           oracle: "0xb47416FfdC9cfD0E527281e808f680798deeA5bf",
           startblock: "5558407",
           swapmining: "0x785Effd455700596ec9Df58C3b0193e99DABC9BA",
           bgmpool: "0xC5Be318a1255EE3B5968747f61Bf51e536FAfead",
           bonuspool: "0x14E239267C809Ca8C8F27B198aD4BdE2E3CCD2ab",
           paramfeecalctor: "0x2908a1242D479d6EB994258E487464356A671c3c",
        }
    }
  }
};

