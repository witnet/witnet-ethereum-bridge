// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

// import "../../contracts/data/WitnetBoardData.sol";
import "../../contracts/exports/IWitnetRequestor.sol";


/**
 * @title Witnet Requests Board Version 1
 * @notice Contract to bridge requests to Witnet
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network
  * The result of the requests will be posted back to this contract by the bridge nodes too.
  * The contract has been created for testing purposes
 * @author Witnet Foundation
 */
contract WitnetRequestBoardTestHelper is IWitnetRequestor {

  struct DataRequest {
    address requestAddress;
    uint256 reward;
    bytes result;
    uint256 timestamp;
    uint256 drTxHash;
    address payable pkhClaim;
  }

  DataRequest[] public requests;

  address public witnet;

  // List of addresses authorized to post blocks
  address[] public committee;

  // Is upgradable
  bool public upgradable;

  constructor (address[] memory _committee, bool _upgradable) {
    witnet = msg.sender;
    upgradable = _upgradable;

    // Insert an empty request so as to initialize the requests array with length > 0
    DataRequest memory request;
    requests.push(request);
    committee = _committee;
  }

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress) external payable override returns(uint256) {
    uint256 _id = requests.length;
    DataRequest memory dr;
    requests.push(dr);

    requests[_id].requestAddress = _requestAddress;
    requests[_id].reward = msg.value;
    requests[_id].result = "hello";
    requests[_id].timestamp = 0;
    requests[_id].drTxHash = 0;
    requests[_id].pkhClaim = payable(address(0));

    emit PostedRequest(_id);

    return _id;
  }

  /// @dev Increments the rewards of a data request by adding more value to it.
  /// @param _id The unique identifier of the data request.
  function upgradeDataRequest(uint256 _id)
    external
    payable
    override
  {
    requests[_id].reward += msg.value;
  }

  /// @dev Retrieves hash of the data request transaction in Witnet
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DataRequest transaction in Witnet
  function readDrTxHash (uint256 _id) external view returns(uint256) {
    return requests[_id].drTxHash;
  }

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult (uint256 _id) external view returns(bytes memory) {
    return requests[_id].result;
  }

  /// @dev Verifies if the contract is upgradable
  /// @return true if the contract upgradable
  /* solhint-disable-next-line no-unused-vars*/
  function isUpgradable(address) external view returns(bool) {
    return upgradable;
  }

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @return The rewards to be included for the given gas price as inclusionReward, resultReward, blockReward.
  function estimateGasCost(uint256) external view override returns(uint256){
    return 0;
  }

}
