const ethUtils = require("ethereumjs-util")
const fs = require("fs")
const utils = require("../utils")

const SingletonFactory = artifacts.require("SingletonFactory")

module.exports = async function (deployer, network, accounts) {
  const addresses = require("./addresses.json")
  const singletons = require("./singletons.json")

  const from = singletons.from || deployer.networks[network].from || accounts[0]

  // Generate SingletonFactory deployment transaction:
  const res = utils.generateDeployTx(
    SingletonFactory.toJSON(),
    singletons.sender.r,
    singletons.sender.s,
    singletons.sender.gasprice,
    singletons.sender.gas
  )

  const deployedCode = await web3.eth.getCode(res.contractAddr)

  if (deployedCode.length <= 3) {
    // Deploy SingletonFactory instance, if not yet deployed on this `network`:
    utils.traceHeader("Inception of 'SingletonFactory':")

    const balance = await web3.eth.getBalance(from)
    const estimatedGas = res.gasLimit
    const value = estimatedGas * res.gasPrice
    let makerBalance = await web3.eth.getBalance(res.sender)

    if (makerBalance < value) {
      // transfer ETH funds to sender address, if currently not enough:
      await web3.eth.sendTransaction({
        from: from,
        to: res.sender,
        value: value - makerBalance,
      })
      makerBalance = await web3.eth.getBalance(res.sender)
    }

    const tx = await web3.eth.sendSignedTransaction(res.rawTx)
    utils.traceTx(tx, web3.utils.fromWei((balance - await web3.eth.getBalance(from)).toString()))
  } else {
    utils.traceHeader("Singleton factory: 'SingletonFactory")
  }

  // Set SingletonFactory address on current network:
  SingletonFactory.address = res.contractAddr
  const factory = await SingletonFactory.deployed()

  // Trace factory relevant data:
  console.log("  ", "> sender's balance:\t",
    `${web3.utils.fromWei((await web3.eth.getBalance(res.sender)).toString(), "ether")} ETH`
  )
  console.log("  ", "> factory codehash:\t", web3.utils.soliditySha3(await web3.eth.getCode(res.contractAddr)))
  console.log("  ", "> factory sender:\t", res.sender)
  console.log("  ", "> factory address:\t", factory.address)
  console.log("  ", "> factory nonce:\t", await web3.eth.getTransactionCount(factory.address))
  console.log("")

  // Process all singleton libraries referred in config file:
  for (const lib in singletons.libs) {
    const artifact = artifacts.require(lib)
    const salt = singletons.libs[lib].salt
      ? "0x" + ethUtils.setLengthLeft(ethUtils.toBuffer(singletons.libs[lib].salt), 32).toString("hex")
      : "0x0"

    let bytecode = artifact.toJSON().bytecode
    if (singletons.libs[lib].links) {
      singletons.libs[lib].links.forEach(
        // Join dependent library address(es) into the library bytecode to be deployed:
        // Please note: dependent libraries should have been previously deployed,
        //   so order in which libraries are declared in the config file actually matters.
        sublib => {
          const sublibArtifact = artifacts.require(sublib)
          const sublibAddr = sublibArtifact.address.slice(2).toLowerCase()
          const sublibMark = `__${sublibArtifact.contractName}${"_".repeat(38 - sublibArtifact.contractName.length)}`
          bytecode = bytecode.split(sublibMark).join(sublibAddr)
        }
      )
    }
    artifact.bytecode = bytecode

    const libAddr = await factory.determineAddr.call(bytecode, salt)

    if ((await web3.eth.getCode(libAddr)).length <= 3) {
      // Deploy library instance, if not yet deployed on this `network`:
      utils.traceHeader(`Singleton inception of library '${lib}':`)

      const balance = await web3.eth.getBalance(from)
      const gas = singletons.libs[lib].gas || 10 ** 6
      const tx = await factory.deploy(bytecode, salt, { from: from, gas: gas })
      utils.traceTx(tx.receipt, web3.utils.fromWei((balance - await web3.eth.getBalance(from)).toString()))
    } else {
      utils.traceHeader(`Singleton library: '${lib}'`)
    }

    artifact.address = libAddr

    const libCodehash = web3.utils.soliditySha3(await web3.eth.getCode(artifact.address))
    if (!libCodehash) {
      throw new Error(`Fatal: unable to deploy library '${lib}' as singleton. Try providing more gas.`)
    }

    console.log("  ", "> library codehash:\t", libCodehash)
    console.log("  ", "> library address:\t", artifact.address)
    console.log()

    addresses.singletons.libraries[lib] = libAddr
  }

  fs.writeFileSync("./migrations/addresses.json", JSON.stringify(addresses, null, 2))
}
