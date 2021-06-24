// SPDX-License-Identifier: MIT

pragma solidity 0.8.5;

// Inherits:
import "../../data/WitnetBoardDataWhitelists.sol";
import "../../exports/WitnetRequestBoardInterface.sol";
import "../../exports/WitnetBoard.sol";
import "../../utils/Destructible.sol";
import "../../utils/Upgradable.sol";

// Uses:
import "../../exports/WitnetRequest.sol";

/**
 * @title Witnet Requests Board mocked
 * @notice Contract to bridge requests to Witnet for testing purposes.
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
 * The result of the requests will be posted back to this contract by the bridge nodes too.
 * @author Witnet Foundation
 */
contract WitnetRequestBoard
    is 
        Destructible,
        Upgradable, 
        WitnetBoard, 
        WitnetBoardDataWhitelists
{
    uint256 internal constant __ESTIMATED_REPORT_RESULT_GAS = 102496;

    constructor() {
        // sets instance as initialized:
        __data().instance = address(this);
    }


    // ================================================================================================================
    // --- Overrides 'Destructible' -----------------------------------------------------------------------------------

    function destroy() external override onlyOwner {
        selfdestruct(payable(msg.sender));
    }


    // ================================================================================================================
    // --- Overrides 'Upgradable' -------------------------------------------------------------------------------------

    /// @dev Initialize storage-context when invoked as delegatecall. 
    /// @dev Should fail when trying to initialize same instance more than once.
    function initialize(bytes memory _initData) virtual external override {
        address _owner = __data().owner;
        if (_owner == address(0)) {
            // set owner if not yet set
            _owner = msg.sender;
            __data().owner = _owner;
        }

        // only owner can initialize:
        require(msg.sender == _owner, "WitnetRequestBoard: only owner");

        // current instance cannot be initialized more than once:
        require(__data().instance != __stub, "WitnetRequestBoard: already initialized");
        __data().instance = __stub;

        // do actual initialization:
        setReporters(abi.decode(_initData, (address[])));
        emit Initialized(msg.sender, __stub);
    }

    /// @dev Retrieves named version of current implementation.
    function version() virtual external pure override returns (string memory) {
        return "WitnetRequestBoard-Centralized-v0.3.0";
    }


    // ================================================================================================================
    // --- Utility functions not declared within an interface ---------------------------------------------------------

    function setReporters(address[] memory reporters)
        public
        virtual
        onlyOwner
    {
        for (uint ix = 0; ix < reporters.length; ix ++) {
            address _reporter = reporters[ix];
            if (_reporter != address(0)) {
                __whitelists().isReporter_[_reporter] = true;
            }
        }
    }

    /// @dev Retrieves the whole DR post record from the WRB.
    /// @param id The unique identifier of a previously posted data request.
    /// @return The DR record.
    function readDr(uint256 id)
        external view
        virtual
        wasPosted(id)
        returns (WitnetTypes.DataRequest memory)
    {
        return __checkDr(id);
    }
    
    /// @dev Retrieves RADON bytecode of a previously posted DR.
    /// @param id The unique identifier of the previously posted DR.
    /// @return _bytecode The RADON bytecode. Fails if changed after being posted.
    function readDataRequest(uint256 id)
        external view
        virtual
        wasPosted(id)
        returns (bytes memory _bytecode)
    {
        WitnetTypes.DataRequest storage _dr = __dataRequest(id);
        _bytecode = WitnetRequest(_dr.addr).bytecode();
        require(
            WitnetTypes.computeDataRequestCodehash(_bytecode) == _dr.codehash,
            "WitnetRequestBoard: manipulated request"
        );
    }

    /// @dev Retrieves the gas price set for a previously posted DR.
    /// @param id The unique identifier of a previously posted DR.
    /// @return The latest gas price set by either the DR requestor, or upgrader.
    function readGasPrice(uint256 id)
        external view
        virtual
        wasPosted(id)
        returns (uint256)
    {
        return __dataRequest(id).gasprice;
    }

    /// @dev Reports the result of a data request solved by Witnet network.
    /// @param id The unique identifier of the data request.
    /// @param txhash Hash of the solving tally transaction in Witnet.
    /// @param result The result itself as bytes.
    function reportResult(
            uint256 id,
            uint256 txhash,
            bytes calldata result
        )
        external
        virtual
        onlyReporters
        wasPosted(id)
        resultNotYetReported(id)
    {
        require(txhash != 0, "WitnetRequestBoard: tx hash cannot be zero");
        // Ensures the result byes do not have zero length
        // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
        require(result.length != 0, "WitnetRequestBoard: result cannot be empty");

        
        SWitnetBoardDataRequest storage _req = __data().requests[id];
        _req.dr.txhash = txhash;
        _req.result = result;

        emit PostedResult(id);
        payable(msg.sender).transfer(_req.dr.reward);
    }

    
    // ================================================================================================================
    // --- Implements 'WitnetRequestBoardInterface' -------------------------------------------------------------------

    /// @dev Retrieves Witnet tx hash of a previously solved DR.
    /// @param id The unique identifier of a previously posted data request.
    /// @return The hash of the DataRequest transaction in Witnet.
    function readDrTxHash(uint256 id)
        external view        
        virtual override
        wasPosted(id)
        returns (uint256)
    {
        return __dataRequest(id).txhash;
    }   
    
    /// @dev Retrieves the result (if already available) of one data request from the WRB.
    /// @param id The unique identifier of the data request.
    /// @return The result of the DR.
    function readResult(uint256 id)
        external view
        virtual override        
        wasPosted(id)
        returns (bytes memory)
    {
        SWitnetBoardDataRequest storage _req = __data().requests[id];
        require(_req.dr.txhash != 0, "WitnetRequestBoard: not yet solved");
        return _req.result;
    }  

    /// @dev Returns the number of posted data requests in the WRB.
    /// @return The number of posted data requests in the WRB.
    function requestsCount() external virtual view returns (uint256) {
        return __data().noRequests;
    }

    /// @dev Estimate the amount of reward we need to insert for a given gas price.
    /// @param gasPrice The gas price for which we need to calculate the rewards.
    /// @return The reward to be included for the given gas price.
    function estimateGasCost(uint256 gasPrice)
        external pure
        virtual override
        returns (uint256)
    {
        return gasPrice * __ESTIMATED_REPORT_RESULT_GAS;
    }
    
    /// @dev Posts a data request into the WRB in expectation that it will be relayed 
    /// @dev and resolved in Witnet with a total reward that equals to msg.value.
    /// @param requestAddr The Witnet request contract address which provides actual RADON bytecode.
    /// @return _id The unique identifier of the posted DR.
    function postDataRequest(address requestAddr)
        public payable
        virtual override
        returns (uint256 _id)
    {
        require(requestAddr != address(0), "WitnetRequestBoard: null request");

        // Checks the tally reward is covering gas cost
        uint256 minResultReward = tx.gasprice * __ESTIMATED_REPORT_RESULT_GAS;
        require(msg.value >= minResultReward, "WitnetRequestBoard: reward too low");

        _id = ++ __data().noRequests;
        WitnetTypes.DataRequest storage _dr = __dataRequest(_id);

        _dr.addr = requestAddr;
        _dr.requestor = msg.sender;
        _dr.codehash = WitnetTypes.computeDataRequestCodehash(
            WitnetRequest(requestAddr).bytecode()
        );
        _dr.gasprice = tx.gasprice;
        _dr.reward = msg.value;

        // Let observers know that a new request has been posted
        emit PostedRequest(_id);
    }

    /// @dev Increments the reward of a data request by adding the transaction value to it.
    /// @param id The unique identifier of a previously posted data request.
    function upgradeDataRequest(uint256 id)
        external payable
        virtual override        
        wasPosted(id)        
    {
        WitnetTypes.DataRequest storage _dr = __dataRequest(id);
        require(_dr.txhash == 0, "WitnetRequestBoard: already solved");

        uint256 _newReward = _dr.reward + msg.value;

        // If gas price is increased, then check if new rewards cover gas costs
        if (tx.gasprice > _dr.gasprice) {
            // Checks the reward is covering gas cost
            uint256 _minResultReward = tx.gasprice * __ESTIMATED_REPORT_RESULT_GAS;
            require(
                _newReward >= _minResultReward,
                "WitnetRequestBoard: reward too low"
            );
            _dr.gasprice = tx.gasprice;
        }
        _dr.reward = _newReward;
    }


    // ================================================================================================================
    // --- Private functions ------------------------------------------------------------------------------------------

    function __checkDr(uint256 id)
        private view returns (WitnetTypes.DataRequest storage _dr)
    {
        _dr = __dataRequest(id);
        bytes memory _bytecode = WitnetRequest(_dr.addr).bytecode();
        require(
            WitnetTypes.computeDataRequestCodehash(_bytecode) == _dr.codehash,
            "WitnetRequestBoard: manipulated request"
        );
    }
}
