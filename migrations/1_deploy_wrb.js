const addresses = require("./addresses.json")
const WitnetProxy = artifacts.require("WitnetProxy")
const WitnetRequestBoard = artifacts.require("WitnetRequestBoard")

module.exports = async function (deployer, network, accounts) {
  network = network.split("-")[0]
  if (network in addresses && addresses[network].WitnetProxy) {
    WitnetProxy.address = addresses[network].WitnetProxy
  } else {
    console.log(`> Migrating WitnetRequestBoard and WitnetProxy into ${network} network...`)
    await deployer.deploy(WitnetRequestBoard)
    const proxy = await deployer.deploy(WitnetProxy)
    await proxy.upgrade(
      WitnetRequestBoard.address,
      web3.eth.abi.encodeParameter(
        "address[]",
        [accounts[0]]
      )
    )
  }
}
