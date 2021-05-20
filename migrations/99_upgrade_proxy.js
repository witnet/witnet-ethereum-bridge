const WitnetRequestBoardProxy = artifacts.require("WitnetRequestBoardProxy")
const WitnetRequestBoard = artifacts.require("WitnetRequestBoard")

module.exports = async function (deployer, network, accounts) {
  const WRB = await WitnetRequestBoard.deployed()
  const WRBProxy = await WitnetRequestBoardProxy.deployed()

  const currentWRB = await WRBProxy.currentWitnetRequestBoard.call()
  if (currentWRB !== WRB.address) {
    console.log(`> Upgrading 'WitnetRequestBoardProxy' singleton on '${network}' network...\n`)
    console.log("  ", "WRB owner address:", await WRB.owner.call())
    console.log("  ", "Old WRB address  :", currentWRB)
    await WRBProxy.upgradeWitnetRequestBoard(WitnetRequestBoard.address, { from: accounts[0] })
    console.log("  ", "New WRB address  :", await WRBProxy.currentWitnetRequestBoard.call())
  }
}
