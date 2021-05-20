// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../../contracts/Request.sol";
import "../../contracts/libs/Witnet.sol";
import "../../contracts/UsingWitnet.sol";


/**
 * @title Test Helper for the UsingWitnet contract
 * @dev The aim of this contract is:
 * 1. Raise the visibility modifier of UsingWitnet contract functions for testing purposes
 * @author Witnet Foundation
 */
contract UsingWitnetTestHelper is UsingWitnet {
  using Witnet for Witnet.Result;

  Witnet.Result public result;

  constructor (address _wrbAddress) public UsingWitnet(_wrbAddress) { }

  function _witnetPostRequest(Request _request) external payable returns(uint256 id) {
    return witnetPostRequest(_request);
  }

  function _witnetUpgradeRequest(uint256 _id) external payable {
    witnetUpgradeRequest(_id);
  }

  function _witnetReadResult(uint256 _requestId) external returns(Witnet.Result memory) {
    result = witnetReadResult(_requestId);
    return result;
  }

  function _witnetEstimateGasCost(uint256 _gasPrice) external returns(uint256) {
    return witnetEstimateGasCost(_gasPrice);
  }

  function _witnetAsUint64() external view returns(uint64) {
    return result.asUint64();
  }

  function _witnetCheckRequestResolved(uint256 _id) external view returns (bool) {
  // If the result of the data request in Witnet is not the default, then it means that it has been reported as resolved.
  return wrb.readResult(_id).length != 0;
  }

}
