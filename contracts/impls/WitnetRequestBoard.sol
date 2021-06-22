// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;


import "../exports/WitnetRequestBoardInterface.sol";
import "../exports/Request.sol";

/**
 * @title Witnet Requests Board mocked
 * @notice Contract to bridge requests to Witnet for testing purposes.
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
 * The result of the requests will be posted back to this contract by the bridge nodes too.
 * @author Witnet Foundation
 */
contract WitnetRequestBoard is WitnetRequestBoardInterface {
    // TODO: update max report result gas value
    uint256 public constant ESTIMATED_REPORT_RESULT_GAS = 102496;

    struct DataRequest {
        address requestAddress;
        uint256 drOutputHash;
        uint256 reward;
        uint256 gasPrice;
        bytes result;
        uint256 drTxHash;
    }

    // Owner of the Witnet Request Board
    address public owner;

    // Map of addresses to a bool, true if they are committee members
    mapping(address => bool) public isInCommittee;

    // Witnet Requests within the board
    DataRequest[] public requests;

    // Only the committee defined when deploying the contract should be able to report results
    modifier isAuthorized() {
        require(isInCommittee[msg.sender] == true, "Sender not authorized");
        _;
    }

    // Ensures the result has not been reported yet
    modifier resultNotIncluded(uint256 _id) {
        require(requests[_id].result.length == 0, "Result already included");
        _;
    }

    // Ensures the request has not been manipulated
    modifier validDrOutputHash(uint256 _id) {
        require(
            requests[_id].drOutputHash ==
                computeDrOutputHash(Request(requests[_id].requestAddress).bytecode()),
            "The dr has been manipulated and the bytecode has changed"
        );
        _;
    }

    // Ensures the request id exists
    modifier validId(uint256 _id) {
        require(requests.length > _id, "Id not found");
        _;
    }

    /// @notice Initilizes a centralized Witnet Request Board with an authorized committee.
    /// @param _committee list of authorized addresses.
    constructor(address[] memory _committee) {
        owner = msg.sender;
        for (uint256 i = 0; i < _committee.length; i++) {
            isInCommittee[_committee[i]] = true;
        }
        // Insert an empty request so as to initialize the requests array with length > 0
        DataRequest memory request;
        requests.push(request);
    }

    /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
    /// @param _requestAddress The request contract address which includes the request bytecode.
    /// @return The unique identifier of the data request.
    function postDataRequest(address _requestAddress)
        external
        payable
        override
        returns (uint256)
    {
        // Checks the tally reward is covering gas cost
        uint256 minResultReward = tx.gasprice * ESTIMATED_REPORT_RESULT_GAS;
        require(
            msg.value >= minResultReward,
            "Result reward should cover gas expenses. Check the estimateGasCost method."
        );

        uint256 _id = requests.length;

        DataRequest memory request;
        request.requestAddress = _requestAddress;
        request.reward = msg.value;
        Request requestContract = Request(request.requestAddress);
        request.drOutputHash = computeDrOutputHash(requestContract.bytecode());
        request.gasPrice = tx.gasprice;
        // Push the new request into the contract state
        requests.push(request);

        // Let observers know that a new request has been posted
        emit PostedRequest(_id);

        return _id;
    }

    /// @dev Increments the reward of a data request by adding the transaction value to it.
    /// @param _id The unique identifier of the data request.
    function upgradeDataRequest(uint256 _id)
        external
        payable
        override
        resultNotIncluded(_id)
    {
        uint256 newReward = requests[_id].reward + msg.value;

        // If gas price is increased, then check if new rewards cover gas costs
        if (tx.gasprice > requests[_id].gasPrice) {
            // Checks the reward is covering gas cost
            uint256 minResultReward = tx.gasprice * ESTIMATED_REPORT_RESULT_GAS;
            require(
                newReward >= minResultReward,
                "Result reward should cover gas expenses. Check the estimateGasCost method."
            );
            requests[_id].gasPrice = tx.gasprice;
        }

        // Update data request reward
        requests[_id].reward = newReward;
    }

    /// @dev Reports the result of a data request in Witnet.
    /// @param _id The unique identifier of the data request.
    /// @param _drTxHash The unique hash of the request.
    /// @param _result The result itself as bytes.
    function reportResult(
        uint256 _id,
        uint256 _drTxHash,
        bytes calldata _result
    ) external isAuthorized() validId(_id) resultNotIncluded(_id) {
        require(_drTxHash != 0, "Data request transaction cannot be zero");
        // Ensures the result byes do not have zero length
        // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
        require(_result.length != 0, "Result has zero length");

        requests[_id].drTxHash = _drTxHash;
        requests[_id].result = _result;

        emit PostedResult(_id);
        payable(msg.sender).transfer(requests[_id].reward);
    }

    /// @dev Retrieves the bytes of the serialization of one data request from the WRB.
    /// @param _id The unique identifier of the data request.
    /// @return The result of the data request as bytes.
    function readDataRequest(uint256 _id)
        external
        view
        validId(_id)
        validDrOutputHash(_id)
        returns (bytes memory)
    {
        Request requestContract = Request(requests[_id].requestAddress);
        return requestContract.bytecode();
    }

    /// @dev Retrieves the result (if already available) of one data request from the WRB.
    /// @param _id The unique identifier of the data request.
    /// @return The result of the DR.
    function readResult(uint256 _id)
        external
        view
        override
        validId(_id)
        returns (bytes memory)
    {
        require(requests[_id].drTxHash != 0, "The request has not yet been resolved");
        return requests[_id].result;
    }

    /// @dev Retrieves the gas price set for a specific DR ID.
    /// @param _id The unique identifier of the data request.
    /// @return The gas price set by the request creator.
    function readGasPrice(uint256 _id)
        external
        view
        validId(_id)
        returns (uint256)
    {
        return requests[_id].gasPrice;
    }

    /// @dev Retrieves hash of the data request transaction in Witnet.
    /// @param _id The unique identifier of the data request.
    /// @return The hash of the DataRequest transaction in Witnet.
    function readDrTxHash(uint256 _id)
        external
        view
        override
        validId(_id)
        returns (uint256)
    {
        return requests[_id].drTxHash;
    }

    /// @dev Returns the number of data requests in the WRB.
    /// @return the number of data requests in the WRB.
    function requestsCount() external view returns (uint256) {
        return requests.length;
    }

    /// @dev Verifies if the contract is upgradable.
    /// @return true if the contract upgradable.
    function isUpgradable(address _address)
        external
        view
        override
        returns (bool)
    {
        if (_address == owner) {
            return true;
        }
        return false;
    }

    /// @dev Estimate the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the reward.
    /// @return The reward to be included for the given gas price.
    function estimateGasCost(uint256 _gasPrice)
        external
        pure
        override
        returns (uint256)
    {
        return _gasPrice * ESTIMATED_REPORT_RESULT_GAS;
    }
    
    /// @dev Computes the output hash of a request from its bytecode.
    /// @param _bytecode The bytecode of the request.
    /// @return The output hash of the request.
    function computeDrOutputHash(bytes memory _bytecode)
        public
        pure
        returns (uint256)
    {
        return uint256(sha256(_bytecode));
    }
}
