// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

import "./utils/Upgradable.sol";

contract WitnetProxy {
  Upgradable public wrb;

  constructor () {}

  receive() external payable {
    revert("WitnetProxy: no ETH accepted");
  }

  // solhint-disable-next-line
  fallback() external payable {
    address _wrb = address(wrb);
    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize())
      // solhint-disable-next-line
      let result := delegatecall(gas(), _wrb, ptr, calldatasize(), 0, 0)
      let size := returndatasize()
      returndatacopy(ptr, 0, size)
      switch result
        case 0  { revert(ptr, size) }
        default { return(ptr, size) }
    }
  }

  function upgrade(address _newWrb, bytes memory _initData) public {
    require(_newWrb != address(0), "WitnetProxy: null wrb");
    require(_newWrb != address(wrb), "WitnetProxy: nothing to upgrade");
    if (address(wrb) != address(0)) {
      require(wrb.isUpgradable(), "WitnetProxy: not upgradable");
    }
    // solhint-disable-next-line
    (bool _wasInitialized,) = _newWrb.delegatecall(
      abi.encodeWithSignature("initialize(bytes)", _initData)
    );
    require(_wasInitialized, "WitnetProxy: unable to initialize new wrb");
    wrb = Upgradable(_newWrb);
  }
}
