// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "./Request.sol";
import "./WitnetRequestBoardProxy.sol";
import "./libs/Witnet.sol";

/**
 * @title The UsingWitnet contract
 * @notice Contract writers can inherit this contract in order to create Witnet data requests.
 */
contract UsingWitnet {
  using Witnet for Witnet.Result;

  WitnetRequestBoardProxy internal wrb;

 /**
  * @notice Include an address to specify the WitnetRequestBoard.
  * @param _wrb WitnetRequestBoard address.
  */
  constructor(address _wrb) public {
    wrb = WitnetRequestBoardProxy(_wrb);
  }

  // Provides a convenient way for client contracts extending this to block the execution of the main logic of the
  // contract until a particular request has been successfully resolved by Witnet
  modifier witnetRequestResolved(uint256 _id) {
    require(witnetCheckRequestResolved(_id), "Witnet request is not yet resolved by the Witnet network");
    _;
  }

 /**
  * @notice Send a new request to the Witnet network with transaction value as result report reward.
  * @dev Call to `post_dr` function in the WitnetRequestBoard contract.
  * @param _request An instance of the `Request` contract.
  * @return Sequencial identifier for the request included in the WitnetRequestBoard.
  */
  function witnetPostRequest(Request _request) internal returns (uint256) {
    return wrb.postDataRequest{value: msg.value}(address(_request));
  }

 /**
  * @notice Check if a request has been resolved by Witnet.
  * @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
  * parties) before this method returns `true`.
  * @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
  * @return A boolean telling if the request has been already resolved or not.
  */
  function witnetCheckRequestResolved(uint256 _id) internal view returns (bool) {
    // If the result of the data request in Witnet is not the default, then it means that it has been reported as resolved.
    return wrb.readResult(_id).length != 0;
  }

 /**
  * @notice Upgrade the reward for a Data Request previously included.
  * @dev Call to `upgrade_dr` function in the WitnetRequestBoard contract.
  * @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
  */
  function witnetUpgradeRequest(uint256 _id) internal {
    wrb.upgradeDataRequest{value: msg.value}(_id);
  }

 /**
  * @notice Read the result of a resolved request.
  * @dev Call to `read_result` function in the WitnetRequestBoard contract.
  * @param _id The unique identifier of a request that was posted to Witnet.
  * @return The result of the request as an instance of `Result`.
  */
  function witnetReadResult(uint256 _id) internal view returns (Witnet.Result memory) {
    return Witnet.resultFromCborBytes(wrb.readResult(_id));
  }

 /**
  * @notice Estimate the reward amount.
  * @dev Call to `estimate_gas_cost` function in the WitnetRequestBoard contract.
  * @param _gasPrice The gas price for which we want to retrieve the estimation.
  * @return The reward to be included for the given gas price.
  */
  function witnetEstimateGasCost(uint256 _gasPrice) internal view returns (uint256) {
    return wrb.estimateGasCost(_gasPrice);
  }
}
