// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "../../contracts/WitnetProxy.sol";
import "../../contracts/exports/WitnetBoard.sol";


/**
 * @title Test Helper for the WitnetRequestBoardProxy contract
 * @dev The aim of this contract is:
 *  Raise the visibility modifier of WitnetRequestBoardProxy contract functions for testing purposes
 * @author Witnet Foundation
 */
contract WrbProxyTestHelper is WitnetProxy {

  constructor () {}
  function getWrbAddress() external view returns(address) {
    return address(delegate);
  }
  
  function upgradeWitnetRequestBoard(address _newWrb) external {
    address[] memory _reporters = new address[](1);
    _reporters[0] = msg.sender;
    upgrade(_newWrb, abi.encode(_reporters));
  }
}
