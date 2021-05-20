module.exports = function (receipt, totalCost) {
  console.log("  ", "> transaction hash:\t", receipt.transactionHash)
  console.log("  ", "> block number:\t", receipt.blockNumber)
  console.log("  ", "> gas used:\t\t", receipt.cumulativeGasUsed)
  if (totalCost) {
    console.log("  ", "> total cost:\t", totalCost, "ETH")
  }
  console.log()
}
