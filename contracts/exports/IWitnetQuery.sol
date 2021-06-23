// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Witnet Request Board querying interface.
 * @notice Sub-interface of a Witnet Request Board (WRB).
 * @dev It defines how to interact with the WRB in order to:
 * @dev - Read DR metadata.
 * @dev - Retrieve DR result, if any.
 * @author Witnet Foundation
 */
interface IWitnetQuery {

  /// @dev Retrieves the bytes of the serialization of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the data request as bytes.
  function readDataRequest(uint256 _id) external view returns (bytes memory);

  /// @dev Retrieves the DR transaction hash of the id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DR transaction
  function readDrTxHash (uint256 _id) external view returns(uint256);

  /// @dev Retrieves the gas price set for a specific DR ID.
  /// @param _id The unique identifier of the data request.
  /// @return The gas price set by the request creator.
  function readGasPrice(uint256 _id) external view returns (uint256);

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult (uint256 _id) external view returns(bytes memory);

  /// @dev Returns the number of data requests in the WRB.
  /// @return the number of data requests in the WRB.
  function requestsCount() external view returns (uint256);

}