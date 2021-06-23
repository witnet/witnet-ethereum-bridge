// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;



/**
  * @title Interface for posting and retrieving DRs to/from Witnet mainnet.
  * @author Witnet Foundation
 */
interface IWitnetRequestor {

  // Event emitted when a new DR is posted
  event PostedRequest(uint256 _id);

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the rewards.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns(uint256);

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns(uint256);

  /// @dev Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable;  

}
