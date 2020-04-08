pragma solidity >=0.5.3 <0.7.0;

import "./Request.sol";
import "./Witnet.sol";
import "./WitnetRequestsBoardProxy.sol";


/**
 * @title The UsingWitnet contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Witnet network.
 */
contract UsingWitnet {
  using Witnet for Witnet.Result;

  WitnetRequestsBoardProxy internal wrb;

 /**
  * @notice Include an address to specify the WitnetRequestsBoard.
  * @param _wrb WitnetRequestsBoard address.
  */
  constructor(address _wrb) public {
    wrb = WitnetRequestsBoardProxy(_wrb);
  }

  // Provides a convenient way for client contracts extending this to block the execution of the main logic of the
  // contract until a particular request has been successfully accepted into Witnet
  modifier witnetRequestAccepted(uint256 _id) {
    require(witnetCheckRequestAccepted(_id), "Witnet request is not yet accepted into the Witnet network");
    _;
  }

  /**
  * @notice Send a new request to the Witnet network
  * @dev Call to `post_dr` function in the WitnetRequestsBoard contract
  * @param _request An instance of the `Request` contract
  * @param _tallyReward Reward specified for the user which post the Data Request result.
  * @return Sequencial identifier for the request included in the WitnetRequestsBoard
  */
  function witnetPostRequest(Request _request, uint256 _tallyReward) internal returns (uint256) {
    return wrb.postDataRequest.value(msg.value)(_request.bytecode(), _tallyReward);
  }

  /**
  * @notice Check if a request has been accepted into Witnet.
  * @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
  * parties) before this method returns `true`.
  * @param _id The sequential identifier of a request that has been previously sent to the WitnetRequestsBoard.
  * @return A boolean telling if the request has been already accepted or not. `false` do not mean rejection, though.
  */
  function witnetCheckRequestAccepted(uint256 _id) internal view returns (bool) {
    // Find the request in the
    uint256 drHash = wrb.readDrHash(_id);
    // If the hash of the data request transaction in Witnet is not the default, then it means that inclusion of the
    // request has been proven to the WRB.
    return drHash != 0;
  }

  /**
  * @notice Upgrade the rewards for a Data Request previously included.
  * @dev Call to `upgrade_dr` function in the WitnetRequestsBoard contract.
  * @param _id The sequential identifier of a request that has been previously sent to the WitnetRequestsBoard.
  * @param _tallyReward Reward specified for the user which post the Data Request result.
  */
  function witnetUpgradeRequest(uint256 _id, uint256 _tallyReward) internal {
    wrb.upgradeDataRequest.value(msg.value)(_id, _tallyReward);
  }

  /**
  * @notice Read the result of a resolved request.
  * @dev Call to `read_result` function in the WitnetRequestsBoard contract.
  * @param _id The sequential identifier of a request that was posted to Witnet.
  * @return The result of the request as an instance of `Result`.
  */
  function witnetReadResult(uint256 _id) internal view returns (Witnet.Result memory) {
    return Witnet.resultFromCborBytes(wrb.readResult(_id));
  }
}
