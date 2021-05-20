const fs = require("fs")
const Migrations = artifacts.require("Migrations")

module.exports = async function (deployer, network) {
  if (!fs.existsSync("./migrations/addresses.json")) {
    await fs.open("./migrations/addresses.json", "w", function (err, file) {
      if (err) throw new Error("Fatal: cannot create ./migrations/addreses.json")
      console.log("> Created ./migrations/addresses.json file.")
    })
  }

  // Prepare "addresses.json" structure if necessary:
  let addresses = await fs.readFileSync("./migrations/addresses.json")
  if (addresses.length === 0) addresses = "{}"
  addresses = JSON.parse(addresses)

  let changes = false
  if (!("networks" in addresses)) {
    addresses.networks = {}
    changes = true
  }
  if (!(network in addresses.networks)) {
    addresses.networks[network] = {}
    changes = true
  }
  if (!("singletons" in addresses)) {
    addresses.singletons = {}
    changes = true
  }
  if (!("libraries" in addresses.singletons)) {
    addresses.singletons.libraries = {}
    changes = true
  }
  if (!("contracts" in addresses.singletons)) {
    addresses.singletons.contracts = {}
    changes = true
  }
  if (changes) {
    await fs.writeFileSync("./migrations/addresses.json", JSON.stringify(addresses, null, 2))
  }

  // Deploy "Migrations" contract:
  await deployer.deploy(Migrations)
}
