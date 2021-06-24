// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


import "../../contracts/exports/WitnetRequest.sol";


/**
 * @title The serialized form of a Witnet data request
 */
contract RequestTestHelper is WitnetRequest {

 /**
  * @dev A `WitnetRequest` is constructed around a `bytes memory` value containing a well-formed Witnet data request serialized
  * using Protocol Buffers. However, we cannot verify its validity at this point. This implies that contracts using
  * the WRB should not be considered trustless before a valid Proof-of-Inclusion has been posted for the requests.
  * The hash of the request is computed in the constructor to guarantee consistency. Otherwise there could be a
  * mismatch and a data request could be resolved with the result of another.
  * @param _bytecode Witnet request in bytes.
  */
  constructor(bytes memory _bytecode) WitnetRequest(_bytecode) {
    bytecode = _bytecode;
  }

  function modifyBytecode(bytes memory _bytecode) public {
    bytecode = _bytecode;
  }
}