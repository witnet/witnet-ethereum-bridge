const {
  // expectEvent,
  expectRevert,
} = require("@openzeppelin/test-helpers")
// const { expect } = require("chai")

const WRB = artifacts.require("WitnetRequestBoard")
const WRBProxy = artifacts.require("WitnetProxy")
const UsingWitnetTestHelper = artifacts.require("UsingWitnetTestHelper")
const Request = artifacts.require("WitnetRequest")
const Witnet = artifacts.require("Witnet")

const truffleAssert = require("truffle-assertions")

contract("UsingWitnet", accounts => {
  describe("UsingWitnet \"happy path\" test case. " +
    "This covers pretty much all the life cycle of a Witnet request.", () => {
    const requestHex = "0x01"
    const resultHex = "0x1a002fefd8"
    const resultDecimal = 3141592
    const drTxHash = "0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    const reward = web3.utils.toWei("1", "ether")

    let witnet, clientContract, wrb, proxy, request, requestId, result
    let lastAccount0Balance

    const ownerAccount = accounts[0]
    const reporterAccount = accounts[1]

    before(async () => {
      witnet = await Witnet.deployed()
      if (!proxy) {
        // create one and only proxy contract:
        proxy = await WRBProxy.new({ from: ownerAccount })
        // let 'wrb' artifact always point to proxy address
        wrb = await WRB.at(proxy.address)
      }
      // notwithstanding, upgrade proxy on each iteration...
      await proxy.upgrade(
        // ...to new implementation instance:
        (await WRB.new({ from: ownerAccount })).address,
        // ...resetting reporters whitelist:
        web3.eth.abi.encodeParameter("address[]", [reporterAccount]),
        // ...from owner account.
        { from: ownerAccount }
      )
      await UsingWitnetTestHelper.link(Witnet, witnet.address)
      clientContract = await UsingWitnetTestHelper.new(proxy.address)
      lastAccount0Balance = await web3.eth.getBalance(accounts[0])
    })

    it("should create a Witnet request", async () => {
      request = await Request.new(requestHex)
      const internalBytes = await request.bytecode()
      assert.equal(internalBytes, requestHex)
    })

    it("should post a Witnet request into the wrb", async () => {
      requestId = await returnData(clientContract._witnetPostRequest(
        request.address,
        {
          from: accounts[1],
          value: reward,
        }
      ))
      assert.equal(requestId, 1)
    })

    it("should have posted and read the same bytes", async () => {
      const internalBytes = await wrb.readDataRequest(requestId)
      assert.equal(internalBytes, requestHex)
    })

    it("should have set the correct rewards", async () => {
      // Retrieve rewards
      const drInfo = await wrb.readDr(requestId)
      const drReward = drInfo.reward.toString()
      assert.equal(drReward, reward)
    })

    it("requester balance should decrease", async () => {
      const afterBalance = await web3.eth.getBalance(accounts[0])
      assert(afterBalance < lastAccount0Balance)
      lastAccount0Balance = afterBalance
    })

    it("client contract balance should remain stable", async () => {
      const usingWitnetBalance = await web3.eth.getBalance(clientContract.address)
      assert.equal(usingWitnetBalance, 0)
    })

    it("WRB balance should increase", async () => {
      const wrbBalance = await web3.eth.getBalance(wrb.address)
      assert.equal(wrbBalance, reward)
    })

    it("should upgrade the rewards of an existing Witnet request", async () => {
      await returnData(clientContract._witnetUpgradeRequest(requestId, {
        from: accounts[1],
        value: reward,
      }))
    })

    it("should have upgraded the rewards correctly", async () => {
      // Retrieve reward
      const drInfo = await wrb.readDr(requestId)
      const drReward = drInfo.reward.toString()
      assert.equal(drReward, reward * 2)
    })

    it("requester balance should decrease after rewards upgrade", async () => {
      const afterBalance = await web3.eth.getBalance(accounts[1])
      assert(afterBalance < lastAccount0Balance - reward)
      lastAccount0Balance = afterBalance
    })

    it("client contract balance should remain stable after rewards upgrade", async () => {
      const usingWitnetBalance = await web3.eth.getBalance(clientContract.address)
      assert.equal(usingWitnetBalance, 0)
    })

    it("WRB balance should increase after rewards upgrade", async () => {
      const wrbBalance = await web3.eth.getBalance(wrb.address)
      assert.equal(wrbBalance, reward * 2)
    })

    it("should fail if posting result from unauthorized reporter", async () => {
      await expectRevert(
        wrb.reportResult(requestId, drTxHash, resultHex, { from: ownerAccount }),
        "unauthorized reporter"
      )
    })

    it("should post the result of the request into the WRB", async () => {
      await returnData(wrb.reportResult(requestId, drTxHash, resultHex, {
        from: reporterAccount,
      }))
      const result = await wrb.readResult(requestId)
      assert.equal(result, resultHex)
    })

    it("should check if the request is resolved", async () => {
      assert.equal(await clientContract._witnetCheckRequestResolved(requestId), true)
    })

    it("should pull the result from the WRB back into the client contract", async () => {
      await clientContract._witnetReadResult(requestId, { from: accounts[0] })
      result = await clientContract.result()
      assert.equal(result.success, true)
      assert.equal(result.value.buffer.data, resultHex)
    })

    it("should decode result successfully", async () => {
      const actualResultDecimal = await clientContract._witnetAsUint64.call()
      assert.equal(actualResultDecimal.toString(), resultDecimal.toString())
    })
  })

  describe("UsingWitnet \"happy path\" test case with a false result.", () => {
    const requestHex = "0x02"
    const resultHex = "0xd82701"
    const drTxHash = "0xe3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

    const reward = web3.utils.toWei("1", "ether")

    const ownerAccount = accounts[0]
    const reporterAccount = accounts[1]

    let witnet, clientContract, wrb, proxy, request, requestId, result

    before(async () => {
      witnet = await Witnet.deployed()
      if (!proxy) {
        // create one and only proxy contract:
        proxy = await WRBProxy.new()
        // let 'wrb' artifact always point to proxy address
        wrb = await WRB.at(proxy.address)
        // initialize 'wrb' artifact,
        //   setting 'ownerAccount' as owner
        //   and 'reporterAccount' as authorized reporter:
        await proxy.upgrade(
          (await WRB.new()).address,
          web3.eth.abi.encodeParameter("address[]", [reporterAccount]),
          { from: ownerAccount }
        )
      }
      await UsingWitnetTestHelper.link(Witnet, witnet.address)
      clientContract = await UsingWitnetTestHelper.new(wrb.address)
    })

    it("should create a Witnet request", async () => {
      request = await Request.new(requestHex)
      const internalBytes = await request.bytecode()
      assert.equal(internalBytes, requestHex)
    })

    it("should pass the data request to the wrb", async () => {
      requestId = await returnData(clientContract._witnetPostRequest(
        request.address,
        {
          from: accounts[0],
          value: reward,
        }
      ))
      assert.equal(requestId, 1)
    })

    it("should check the request is not yet resolved", async () => {
      assert.equal(await clientContract._witnetCheckRequestResolved(requestId), false)
    })

    it("should fail if posting result from unauthorized reporter", async () => {
      await expectRevert(
        wrb.reportResult(requestId, drTxHash, resultHex, { from: ownerAccount }),
        "unauthorized reporter"
      )
    })

    it("should report the result in the WRB", async () => {
      await returnData(wrb.reportResult(requestId, drTxHash, resultHex, {
        from: reporterAccount,
      }))
      const result = await wrb.readResult(requestId)
      assert.equal(result, resultHex)
    })

    it("should pull the result from the WRB back to the client contract", async () => {
      await clientContract._witnetReadResult(requestId, { from: accounts[1] })
      result = await clientContract.result()
      assert.equal(result.value.buffer.data, resultHex)
    })

    it("should detect the result is false", async () => {
      await clientContract._witnetReadResult(requestId, { from: accounts[1] })
      result = await clientContract.result()
      assert.equal(result.success, false)
    })

    it("should be able to estimate gas cost and post the DR", async () => {
      const gasPrice = 20000
      const estimatedReward = await clientContract._witnetEstimateGasCost.call(gasPrice)
      await truffleAssert.passes(
        clientContract._witnetPostRequest(request.address, {
          from: accounts[1],
          value: estimatedReward,
          gasPrice: gasPrice,
        }),
        "Estimated rewards should cover the gas costs"
      )
    })
  })
})

function waitForHash (tx) {
  return new Promise((resolve, reject) =>
    tx.on("transactionHash", resolve).catch(reject)
  )
}

async function returnData (tx) {
  const txHash = await waitForHash(tx)
  const txReceipt = await web3.eth.getTransactionReceipt(txHash)
  if (txReceipt.logs && txReceipt.logs.length > 0) {
    const decoded = web3.eth.abi.decodeLog(
      [
        {
          type: "uint256",
          name: "id",
        }, {
          type: "address",
          name: "from",
        },
      ],
      txReceipt.logs[0].data,
      txReceipt.logs[0].topics
    )
    return decoded.id
  }
}
