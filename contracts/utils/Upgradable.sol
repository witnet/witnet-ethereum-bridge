// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

abstract contract Upgradable {
    address internal immutable __stub;

    event Initialized(address indexed from, address stub);

    constructor () {
        __stub = address(this);
    }

    /// @dev Retrieves the immutable codehash of this instance, even if invoked as delegatecall.
    /// @return _codehash This contracts immutable codehash.
    function codehash() external view returns (bytes32 _codehash) {
        address _stub = __stub;
        assembly {
            _codehash := extcodehash(_stub)
        }
    }

    /// @dev Initialize storage-context when invoked as delegatecall. 
    /// @dev Should fail when trying to initialize same instance more than once.
    function initialize(bytes memory) virtual external;

    
    /// @dev Determines whether current instance allows being upgraded.
    /// @dev Returns value should be invariant from whoever is calling.
    function isUpgradable() virtual external view returns (bool) {
        return true;
    }

    /// @dev Retrieves named version of current implementation.
    function version() virtual external view returns (string memory);
}