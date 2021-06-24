const truffleAssert = require("truffle-assertions")
const WitnetRequestBoard = artifacts.require("WitnetRequestBoardTestHelper")
const RequestContract = artifacts.require("WitnetRequest")
const WrbProxyHelper = artifacts.require("WrbProxyTestHelper")
const Witnet = artifacts.require("Witnet")

contract("Witnet Requests Board Proxy", accounts => {
  describe("Witnet Requests Board Proxy test suite", () => {
    const contractOwner = accounts[0]
    const requestSender = accounts[1]

    let witnet
    let wrbInstance1
    let wrbInstance2
    let wrbInstance3
    let proxy
    let wrb

    before(async () => {
      witnet = await Witnet.deployed()
      await WitnetRequestBoard.link(Witnet, witnet.address)
      wrbInstance1 = await WitnetRequestBoard.new([contractOwner], true)
      wrbInstance2 = await WitnetRequestBoard.new([contractOwner], true)
      wrbInstance3 = await WitnetRequestBoard.new([contractOwner], false)
      proxy = await WrbProxyHelper.new({ from: accounts[2] })
      proxy.upgradeWitnetRequestBoard(wrbInstance1.address, { from: contractOwner })
      wrb = await WitnetRequestBoard.at(proxy.address)
    })

    it("should revert when trying to upgrade the same WRB", async () => {
      // It should revert because the WRB to be upgrated is already in use
      await truffleAssert.reverts(
        proxy.upgradeWitnetRequestBoard(wrbInstance1.address, { from: contractOwner }),
        "nothing to upgrade"
      )
    })

    it("should revert when inserting id 0", async () => {
      // It should revert because of non-existent id 0
      await truffleAssert.reverts(
        wrb.upgradeDataRequest(0, { from: requestSender }),
        "not yet posted"
      )
    })

    it("should post a data request and update the currentLastId", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const request = await RequestContract.new(drBytes)

      // Post the data request through the Proxy
      const tx1 = wrb.postDataRequest(request.address, {
        from: requestSender,
        value: web3.utils.toWei("0.5", "ether"),
      })
      const txHash1 = await waitForHash(tx1)
      const txReceipt1 = await web3.eth.getTransactionReceipt(txHash1)

      // The id of the data request
      const id1 = txReceipt1.logs[txReceipt1.logs.length - 1].data

      // check the currentLastId has been updated in the Proxy when posting the data request
      assert.equal(true, await proxy.checkLastId.call(id1))
    })

    it("should revert when trying to upgrade from non owner address", async () => {
      await truffleAssert.reverts(
        proxy.upgradeWitnetRequestBoard(wrbInstance2.address, { from: requestSender }),
        "unable to initialize"
      )
    })

    it("should upgrade proxy if called from owner address", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const request = await RequestContract.new(drBytes)

      // Post the data request through the Proxy
      const tx1 = wrb.postDataRequest(request.address, {
        from: requestSender,
        value: web3.utils.toWei("0.5", "ether"),
      })
      const txHash1 = await waitForHash(tx1)
      const txReceipt1 = await web3.eth.getTransactionReceipt(txHash1)

      // The id of the data request, it should be equal 2 since is the second DR
      const id1 = txReceipt1.logs[0].data
      assert.equal(id1, 2)

      // Upgrade the WRB address to wrbInstance2 (destroying wrbInstace1)
      await proxy.upgradeWitnetRequestBoard(
        wrbInstance2.address,
        { from: contractOwner }
      )

      // The current wrb in the proxy should be equal to wrbInstance2
      assert.equal(await proxy.wrb.call(), wrbInstance2.address)
    })

    it("should post a data request to new WRB and keep previous data request routes", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const request = await RequestContract.new(drBytes)

      // The id of the data request
      const id2 = await wrb.postDataRequest.call(request.address, {
        from: requestSender,
        value: web3.utils.toWei("0.5", "ether"),
      })
      assert.equal(id2, 3)

      // Post the data request through the Proxy
      await waitForHash(
        wrb.postDataRequest(request.address, {
          from: requestSender,
          value: web3.utils.toWei("0.5", "ether"),
        })
      )

      // Reading previous data request (<3) should work:
      await wrb.readDr(2)
    })

    it("should post a data request to WRB and read the result", async () => {
      // The data request to be posted
      const drBytes = web3.utils.fromAscii("This is a DR")
      const request = await RequestContract.new(drBytes)

      // The id of the data request with result "hello"
      const id2 = await wrb.postDataRequest.call(request.address, {
        from: requestSender,
        value: web3.utils.toWei("0.5", "ether"),
      })
      assert.equal(id2, 4)

      // Post the data request through the Proxy
      await waitForHash(
        wrb.postDataRequest(request.address, {
          from: requestSender,
          value: web3.utils.toWei("0.5", "ether"),
        })
      )

      // Read the result of the DR
      const result = await wrb.readResult.call(id2)
      assert.equal(result, web3.utils.fromAscii("hello"))
    })

    it("should read the result of a dr of and old wrb", async () => {
      // Upgrade the WRB address to wrbInstance3
      await proxy.upgradeWitnetRequestBoard(wrbInstance3.address, {
        from: contractOwner,
      })

      // Read the result of the DR
      const result = await wrb.readResult.call(4)
      assert.equal(result, web3.utils.fromAscii("hello"))
    })

    it("should revert when trying to upgrade a non upgradable WRB", async () => {
      // It should revert when trying to upgrade the wrb since wrbInstance3 is not upgradable
      await truffleAssert.reverts(
        proxy.upgradeWitnetRequestBoard(wrbInstance1.address, { from: contractOwner }),
        "not upgradable"
      )
    })
  })
})

const waitForHash = txQ =>
  new Promise((resolve, reject) =>
    txQ.on("transactionHash", resolve).catch(reject)
  )
