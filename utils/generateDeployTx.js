const EthTx = require("ethereumjs-tx").Transaction
const ethUtils = require("ethereumjs-util")
const rawTransaction = require("./rawTransaction")

module.exports = function (json, r, s, gasprice, gaslimit) {
  const rawTx = rawTransaction(json, r, s, gasprice, gaslimit)
  const tx = new EthTx(rawTx)

  const res = {
    bytecode: rawTx.data,
    contractAddr: ethUtils.toChecksumAddress(
      "0x" + ethUtils.generateAddress(
        tx.getSenderAddress(),
        ethUtils.toBuffer(0)
      ).toString("hex")
    ),
    gasLimit: rawTx.gasLimit.toString(),
    gasPrice: rawTx.gasPrice.toString(),
    rawTx: "0x" + tx.serialize().toString("hex"),
    sender: ethUtils.toChecksumAddress("0x" + tx.getSenderAddress().toString("hex")),
  }
  return res
}
