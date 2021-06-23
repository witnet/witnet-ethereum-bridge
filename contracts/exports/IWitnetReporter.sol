// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Interface used by Witnet bridge nodes to report solved DRs (ie. from Witnet mainnet).
 * @author Witnet Foundation
 */
interface IWitnetReporter {

  // Event emitted when a result is reported
  event PostedResult(uint256 _id);
  
  /// @dev Reports the result of a data request in Witnet.
  /// @param _id The unique identifier of the data request.
  /// @param _drTxHash The unique hash of the request.
  /// @param _result The result itself as bytes.
  function reportResult(uint256 _id, uint256 _drTxHash, bytes calldata _result) external;

}
