// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./WitnetRequestBoardInterface.sol";


/**
 * @title Witnet Request Board Proxy
 * @notice Contract to act as a proxy between the Witnet Bridge Interface and Contracts inheriting UsingWitnet.
 * @author Witnet Foundation
 */
contract WitnetRequestBoardProxy {

  // Struct if the information of each controller
  struct ControllerInfo {
    // Address of the Controller
    address controllerAddress;
    // The lastId of the previous Controller
    uint256 lastId;
  }

  // Witnet Request Board contract that is currently being used
  WitnetRequestBoardInterface public currentWitnetRequestBoard;

  // Last id of the WRB controller
  uint256 internal currentLastId;

  // Array with the controllers that have been used in the Proxy
  ControllerInfo[] internal controllers;


  /// =======================================================================
  /// --- Modifiers ---------------------------------------------------------

  modifier notIdentical(address _newAddress) {
    require(_newAddress != address(currentWitnetRequestBoard), "The provided Witnet Requests Board instance address is already in use");
    _;
  }


  /// =======================================================================
  /// --- Constructor -------------------------------------------------------

  /// @notice Constructor: initialize controllers list
    constructor() public {
    // Initialize the first epoch pointing to the first controller
    controllers.push(ControllerInfo({controllerAddress: address(0), lastId: 0}));
  }

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable returns(uint256) {
    uint256 n = controllers.length;
    uint256 offset = controllers[n - 1].lastId;
    // Update the currentLastId with the id in the controller plus the offSet
    currentLastId = currentWitnetRequestBoard.postDataRequest{value: msg.value}(_requestAddress) + offset;
    return currentLastId;
  }

  /// @dev Increments the reward of a data request by adding the transaction value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id) external payable {
    address wrbAddress;
    uint256 wrbOffset;
    (wrbAddress, wrbOffset) = getController(_id);
    return currentWitnetRequestBoard.upgradeDataRequest{value: msg.value}(_id - wrbOffset);
  }

  /// @dev Retrieves the DR hash of the id from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DR.
  function readDrHash (uint256 _id)
    external
    view
  returns(uint256)
  {
    // Get the address and the offset of the corresponding to id
    address wrbAddress;
    uint256 offsetWrb;
    (wrbAddress, offsetWrb) = getController(_id);
    // Return the result of the DR readed in the corresponding Controller with its own id
    WitnetRequestBoardInterface wrbWithDrHash;
    wrbWithDrHash = WitnetRequestBoardInterface(wrbAddress);
    uint256 drHash = wrbWithDrHash.readDrHash(_id - offsetWrb);
    return drHash;
  }

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR.
  function readResult(uint256 _id) external view returns(bytes memory) {
    // Get the address and the offset of the corresponding to id
    address wrbAddress;
    uint256 offSetWrb;
    (wrbAddress, offSetWrb) = getController(_id);
    // Return the result of the DR in the corresponding Controller with its own id
    WitnetRequestBoardInterface wrbWithResult;
    wrbWithResult = WitnetRequestBoardInterface(wrbAddress);
    return wrbWithResult.readResult(_id - offSetWrb);
  }

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the reward.
  /// @return The reward to be included for the given gas price.
  function estimateGasCost(uint256 _gasPrice) external view returns(uint256) {
    return currentWitnetRequestBoard.estimateGasCost(_gasPrice);
  }

  /// @notice Upgrades the Witnet Requests Board if the current one is upgradeable.
  /// @param _newAddress address of the new block relay to upgrade.
  function upgradeWitnetRequestBoard(address _newAddress) public notIdentical(_newAddress) {
    // Require current WRB to be upgradable:
    require(
        address(currentWitnetRequestBoard) == address(0) 
          || currentWitnetRequestBoard.isUpgradable(msg.sender)
        , "The upgrade has been rejected by the current implementation"
      );

    // Map the currentLastId to the corresponding witnetRequestBoardAddress and add it to controllers
    controllers.push(ControllerInfo({controllerAddress: _newAddress, lastId: currentLastId}));

    // Upgrade the WRB
    currentWitnetRequestBoard = WitnetRequestBoardInterface(_newAddress);
  }

  /// @notice Gets the controller from an Id.
  /// @param _id id of a Data Request from which we get the controller.
  function getController(uint256 _id) internal view returns(address _controllerAddress, uint256 _offset) {
    // Check id is bigger than 0
    require(_id > 0, "Non-existent controller for id 0");

    uint256 n = controllers.length;
    // If the id is bigger than the lastId of a Controller, read the result in that Controller
    for (uint i = n; i > 0; i--) {
      if (_id > controllers[i - 1].lastId) {
        return (controllers[i - 1].controllerAddress, controllers[i - 1].lastId);
      }
    }
  }

}
