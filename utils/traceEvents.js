const shortenAddr = require("./shortenAddr")

module.exports = async function (logs, web3) {
  for (let i = 0; i < logs.length; i++) {
    const event = logs[i].event
    const args = logs[i].args
    let params = ""

    switch (event) {
      case "PostedRequest":
      case "PostedResult":
        params = `from: ${shortenAddr(args[0])}, id: ${args[1].toString(16)}`
        break

      default:
        continue
    }
    let tabs = "\t"
    if (event.length < 13) tabs = "\t\t"
    console.log("    ", `>> ${event}${tabs}(${params})`)
  }
}
