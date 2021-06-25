// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./WitnetRequestBoardInterface.sol";

/**
 * @title Witnet Requests Board functionality base contract.
 * @author Witnet Foundation
 */
abstract contract WitnetBoard is WitnetRequestBoardInterface {

    receive() external payable {
        revert("WitnetBoard: no ETH accepted");
    }
    fallback() external payable {
        revert("WitnetBoard: not implemented");
    }
}
