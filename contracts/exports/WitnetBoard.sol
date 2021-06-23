// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./IWitnetQuery.sol";
import "./IWitnetReporter.sol";
import "./IWitnetRequestor.sol";

/**
 * @title Witnet Requests Board functionality base contract.
 * @author Witnet Foundation
 */
abstract contract WitnetBoard is IWitnetQuery, IWitnetReporter, IWitnetRequestor {}
