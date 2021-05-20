const ethUtils = require("ethereumjs-util")
const fs = require("fs")
const utils = require("../utils")

const SingletonFactory = artifacts.require("SingletonFactory")
const WitnetRequestBoard = artifacts.require("WitnetRequestBoard")

module.exports = async function (deployer, network, accounts) {
  const addresses = require("./addresses.json")

  const factory = await SingletonFactory.deployed()
  const wrb = await WitnetRequestBoard.deployed()

  const singletons = require("./singletons.json")
  const artifact = artifacts.require("WitnetRequestBoardProxy")
  const contract = artifact.contractName

  if (singletons.contracts[contract]) {
    const from = singletons.from || deployer.networks[network].from || accounts[0]

    const salt = singletons.contracts[contract].salt
      ? "0x" + ethUtils.setLengthLeft(ethUtils.toBuffer(singletons.contracts[contract].salt), 32).toString("hex")
      : "0x0"

    let bytecode = artifact.toJSON().bytecode
    if (singletons.contracts[contract].links) {
      singletons.contracts[contract].links.forEach(
        // Join every dependent library address into the contract bytecode to be deployed:
        lib => {
          const libArtifact = artifacts.require(lib)
          const libAddr = libArtifact.address.slice(2).toLowerCase()
          const libMark = `__${libArtifact.contractName}${"_".repeat(38 - libArtifact.contractName.length)}`
          bytecode = bytecode.split(libMark).join(libAddr)
        }
      )
    }
    artifact.bytecode = bytecode

    const contractAddr = await factory.determineAddr.call(bytecode, salt)

    if ((await web3.eth.getCode(contractAddr)).length <= 3) {
      // Deploy contract instance, if not yet deployed on this `network`:
      utils.traceHeader(`Singleton inception of contract '${contract}':`)

      const balance = await web3.eth.getBalance(from)
      const gas = singletons.contracts[contract].gas || 10 ** 6

      // Compose initialization call: 'upgradeWitnetRequestBoard(wrb.address)'
      const initCall = "0x47b1e79b000000000000000000000000" + wrb.address.slice(2)

      const tx = await factory.deployAndInit(bytecode, initCall, salt, { from, gas })
      utils.traceEvents(tx.logs)
      utils.traceTx(tx.receipt, web3.utils.fromWei((balance - await web3.eth.getBalance(from)).toString()))
    } else {
      utils.traceHeader(`Singleton contract: '${contract}'`)
    }

    artifact.address = contractAddr
    const contractCodehash = web3.utils.soliditySha3(await web3.eth.getCode(artifact.address))
    if (!contractCodehash) {
      throw new Error(`Fatal: unable to deploy contract '${contract}' as singleton. Try providing more gas.`)
    }

    console.log("  ", "> contract codehash:  ", web3.utils.soliditySha3(await web3.eth.getCode(artifact.address)))
    console.log("  ", "> contract address:   ", artifact.address)
    console.log("  ", "> current WRB address:", await (await artifact.deployed()).currentWitnetRequestBoard())
    if (singletons.contracts[contract].links && singletons.contracts[contract].links.length > 0) {
      console.log("  ", "> linked libraries:\t", JSON.stringify(singletons.contracts[contract].links))
    }
    addresses.singletons.contracts[contract] = contractAddr
  }

  console.log()
  fs.writeFileSync("./migrations/addresses.json", JSON.stringify(addresses, null, 2))
}
