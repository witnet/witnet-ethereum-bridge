// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;



/**
 * @title Witnet Requests Board Interface
 * @notice Interface of a Witnet Request Board (WRB)
 * It defines how to interact with the WRB in order to support:
 *  - Post and upgrade a data request
 *  - Read the result of a dr
 * @author Witnet Foundation
 */
interface WitnetRequestBoardInterface {

  // Event emitted when a new DR is posted
  event PostedRequest(uint256 _id);

  // Event emitted when a result is reported
  event PostedResult(uint256 _id);

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns(uint256);

  /// @dev Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable;

  /// @dev Retrieves the DR transaction hash of the id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DR transaction
  function readDrTxHash (uint256 _id) external view returns(uint256);

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult (uint256 _id) external view returns(bytes memory);

  /// @notice Verifies if the Witnet Request Board can be upgraded.
  /// @return true if contract is upgradable.
  function isUpgradable(address _address) external view returns(bool);

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the rewards.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns(uint256);
}
