const fs = require("fs")
const WitnetRequestBoard = artifacts.require("WitnetRequestBoard")

module.exports = async function (deployer, network, accounts) {
  network = network.split("-")[0]

  const addresses = require("./addresses.json")
  if (network in addresses.networks && addresses.networks[network].WitnetRequestBoard) {
    WitnetRequestBoard.address = addresses.networks[network].WitnetRequestBoard
  } else {
    console.log(`> Deploying new instance of 'WitnetRequestBoard' into '${network}' network...`)
    await deployer.deploy(WitnetRequestBoard, [accounts[0]], { from: accounts[0] })
    addresses.networks[network].WitnetRequestBoard = WitnetRequestBoard.address
  }

  fs.writeFileSync("./migrations/addresses.json", JSON.stringify(addresses, null, 2))
}
