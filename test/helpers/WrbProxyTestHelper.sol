// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../../contracts/WitnetRequestBoardProxy.sol";


/**
 * @title Test Helper for the WitnetRequestBoardProxy contract
 * @dev The aim of this contract is:
 *  Raise the visibility modifier of WitnetRequestBoardProxy contract functions for testing purposes
 * @author Witnet Foundation
 */
contract WrbProxyTestHelper is WitnetRequestBoardProxy {

  constructor (address _witnetRequestBoardAddress) public WitnetRequestBoardProxy(/*_witnetRequestBoardAddress*/) {
    upgradeWitnetRequestBoard(_witnetRequestBoardAddress);
  }

  function checkLastId(uint256 _id) external view returns(bool) {
    return _id == currentLastId;
  }

  function getWrbAddress() external view returns(address) {
    return address(currentWitnetRequestBoard);
  }

  function getControllerAddress(uint256 _id) external view returns(address) {
    address wrb;
    uint256 offset;
    (wrb, offset) = getController(_id);
    return wrb;
  }

}
