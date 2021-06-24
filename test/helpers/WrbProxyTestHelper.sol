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

  function checkLastId(uint256 _id) external returns(bool) {
    // solhint-disable-next-line
    (bool _success, bytes memory _retdata) = address(wrb).delegatecall(abi.encodeWithSignature("requestsCount()"));
    require(_success, "WrbProxyTestHelper: cannot delegate call");
    uint256 _count = abi.decode(_retdata, (uint256));
    return (_id == _count);
  }

  function getWrbAddress() external view returns(address) {
    return address(wrb);
  }
  
  function upgradeWitnetRequestBoard(address _newWrb) external {
    address[] memory _reporters = new address[](1);
    _reporters[0] = msg.sender;
    upgrade(_newWrb, abi.encode(_reporters));
  }
}
