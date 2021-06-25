// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./WitnetBoardData.sol";

/**
 * @title Witnet whitelist storage layout, for centralized request boards.
 * @author Witnet Foundation
 */
abstract contract WitnetBoardDataWhitelists is WitnetBoardData {  
  struct SWitnetBoardWhitelists {
    mapping (address => bool) isReporter_;
  }

  constructor() {
    __whitelists().isReporter_[msg.sender] = true;
  }

  modifier onlyReporters {
    require(__whitelists().isReporter_[msg.sender], "WitnetBoardDataWhitelists: unauthorized reporter");
    _;
  }  

  function __whitelists() internal pure returns (SWitnetBoardWhitelists storage _struct) {
    assembly {
      _struct.slot := WITNET_BOARD_WHITELISTS_SLOTHASH
    }
  }
  
  bytes32 internal constant WITNET_BOARD_WHITELISTS_SLOTHASH = "WitnetBoard.Whitelists";
}
