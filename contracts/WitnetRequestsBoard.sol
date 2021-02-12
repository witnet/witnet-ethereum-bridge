// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Request.sol";
import "vrf-solidity/contracts/VRF.sol";
import "./ActiveBridgeSetLib.sol";
import "witnet-ethereum-block-relay/contracts/BlockRelayProxy.sol";
import "./WitnetRequestsBoardInterface.sol";


/**
 * @title Witnet Requests Board
 * @notice Contract to bridge requests to Witnet.
 * @dev This contract enables posting requests that Witnet bridges will insert into the Witnet network.
 * The result of the requests will be posted back to this contract by the bridge nodes too.
 * @author Witnet Foundation
 */
contract WitnetRequestsBoard is WitnetRequestsBoardInterface {

  using ActiveBridgeSetLib for ActiveBridgeSetLib.ActiveBridgeSet;

  // Expiration period after which a Witnet Request can be claimed again
  // This should be at least superblock_period*2*checkpoint_period/ethereum_block_time
  // This yields 60, we double it to be conservative
  uint256 public constant CLAIM_EXPIRATION = 120;
  
  // Max gas values as calculate with gas-analysis
  // Claiming is not subject to substantial increases as it is only composed of a VRF verification 
  uint256 public constant MAX_CLAIM_DR_GAS = 216095;
  // DR inclusion is subject to increases due to number of merkle tree levels and activity slots to be removed
  // The following value corresponds to 9 merkle tree levels and one full address removal for all slots
  uint256 public constant MAX_DR_INCLUSION_GAS = 511098;
  // Result reporting is subject to increases due to number of merkle tree levels
  // The following value corresponds to 9 merkle tree levels
  uint256 public constant MAX_REPORT_RESULT_GAS  = 102496;
  // Block reporting is not subject to increases
  uint256 public constant MAX_REPORT_BLOCK_GAS = 127963;

  // Maps a block hash into true if its relayer has already been paid
  mapping (uint256 => bool) internal paidBlocks;

  struct DataRequest {
    address requestAddress;
    uint256 drOutputHash;
    uint256 inclusionReward;
    uint256 tallyReward;
    uint256 blockReward;
    uint256 gasPrice;
    bytes result;
    // Block number at which the DR was claimed for the last time
    uint256 blockNumber;
    // The epoch of the block including the last transaction related to the dr
    // (postDataRequest, reportDataRequestInclusion, reportResult)
    uint256 epoch;
    uint256 drHash;
    address payable pkhClaim;
    address payable requestor;
  }

  // Owner of the Witnet Request Board
  address public witnet;

  // Block Relay proxy prividing verification functions
  BlockRelayProxy public blockRelay;

  // Witnet Requests within the board
  DataRequest[] public requests;

  // Set of recently active bridges
  ActiveBridgeSetLib.ActiveBridgeSet public abs;

  // Replication factor for Active Bridge Set identities
  uint256 public repFactor;

  // Event emitted when a new DR is posted
  event PostedRequest(address indexed _from, uint256 _id);

  // Event emitted when a DR inclusion proof is posted
  event IncludedRequest(address indexed _from, uint256 _id);

  // Event emitted when a result proof is posted
  event PostedResult(address indexed _from, uint256 _id);

  // Ensures the reward is not greater than the value
  modifier payingRewards(uint256 _value, uint256 _inclusionReward, uint256 _tallyReward) {
    require(_value >= SafeMath.add(_inclusionReward, _tallyReward), "Transaction value needs to be equal or greater than tally plus inclusion reward");
    _;
  }

  // Ensures the poe is valid
  modifier poeValid(
    uint256[4] memory _poe,
    uint256[2] memory _publicKey,
    uint256[2] memory _uPoint,
    uint256[4] memory _vPointHelpers) {
    require(
      verifyPoe(
        _poe,
        _publicKey,
        _uPoint,
        _vPointHelpers),
      "Not a valid PoE");
    _;
  }

  // Ensures signature (sign(msg.sender)) is valid
  modifier validSignature(
    uint256[2] memory _publicKey,
    bytes memory addrSignature) {
    require(verifySig(abi.encodePacked(msg.sender), _publicKey, addrSignature), "Not a valid signature");
    _;
  }

  // Ensures the DR inclusion proof has not been reported yet
  modifier drNotIncluded(uint256 _id) {
    require(requests[_id].drHash == 0, "DR already included");
    _;
  }

  // Ensures the DR inclusion has been already reported
  modifier drIncluded(uint256 _id) {
    require(requests[_id].drHash != 0, "DR not yet included");
    _;
  }

  // Ensures the result has not been reported yet
  modifier resultNotIncluded(uint256 _id) {
    require(requests[_id].result.length == 0, "Result already included");
    _;
  }

  // Ensures the request has not been manipulated
  modifier validDrOutputHash(uint256 _id) {
    require(requests[_id].drOutputHash == uint256(sha256(Request(requests[_id].requestAddress).bytecode())),
    "The dr has been manipulated and the bytecode has changed");
    _;
  }

  // Ensures the request id exists
  modifier validId(uint256 _id) {
    require(requests.length > _id, "Id not found"); 
    _;
  }

  // Ensures the VRF is valid
  modifier vrfValid(
    uint256[4] memory _poe,
    uint256[2] memory _publicKey,
    uint256[2] memory _uPoint,
    uint256[4] memory _vPointHelpers) virtual {
    require(
      VRF.fastVerify(
        _publicKey,
        _poe,
        getLastBeacon(),
        _uPoint,
        _vPointHelpers),
      "Not a valid VRF");
    _;
  }

  // Ensures the address belongs to the active bridge set
  modifier absMember(address _address) {
    require(abs.absMembership(_address), "Not a member of the ABS");
    _;
  }

 /**
  * @notice Include an address to specify the Witnet Block Relay and a replication factor.
  * @param _blockRelayAddress BlockRelayProxy address.
  * @param _repFactor replication factor.
  */
  constructor(address _blockRelayAddress, uint8 _repFactor) public {
    blockRelay = BlockRelayProxy(_blockRelayAddress);
    witnet = msg.sender;

    // Insert an empty request so as to initialize the requests array with length > 0
    DataRequest memory request;
    requests.push(request);
    repFactor = _repFactor;
  }

  /// @dev Posts a data request into the WRB in expectation that it will be relayed and resolved in Witnet with a total reward that equals to msg.value.
  /// @param _requestAddress The request contract address which includes the request bytecode.
  /// @param _inclusionReward The amount of value that will be detracted from the transaction value and reserved for rewarding the reporting of the inclusion of the data request.
  /// @param _tallyReward The amount of value that will be detracted from the transaction value and reserved for rewarding the reporting of the final result (aka tally) of the data request.
  /// @return The unique identifier of the data request.
  function postDataRequest(address _requestAddress, uint256 _inclusionReward, uint256 _tallyReward)
    external
    payable
    payingRewards(msg.value, _inclusionReward, _tallyReward)
    override
  returns(uint256)
  {
    uint256 blockReward = SafeMath.sub(msg.value, SafeMath.add(_inclusionReward, _tallyReward));
    
    // Check if rewards are covering gas costs
    isPayingGasCosts( _inclusionReward, _tallyReward, blockReward);

    // The initial length of the `requests` array will become the ID of the request for everything related to the WRB
    uint256 id = requests.length;

    // Create a new `DataRequest` object and initialize all the non-default fields
    DataRequest memory request;
    request.requestAddress = _requestAddress;
    request.inclusionReward = _inclusionReward; 
    request.tallyReward = _tallyReward;
    request.blockReward =  blockReward;
    request.epoch = blockRelay.getLastEpoch();
    Request requestContract = Request(request.requestAddress);
    uint256 _drOutputHash = uint256(sha256(requestContract.bytecode()));
    request.drOutputHash = _drOutputHash;
    request.gasPrice = tx.gasprice;
    request.requestor = msg.sender;

    // Push the new request into the contract state
    requests.push(request);

    // Let observers know that a new request has been posted
    emit PostedRequest(msg.sender, id);

    return id;
  }

  /// @dev Increments the rewards of a data request by adding more value to it. The new request reward will be increased by msg.value minus the difference between the former tally reward and the new tally reward.
  /// @param _id The unique identifier of the data request.
  /// @param _inclusionReward The amount to be added to the inclusion reward.
  /// @param _tallyReward The amount to be added to the tally reward.
  function upgradeDataRequest(uint256 _id, uint256 _inclusionReward, uint256 _tallyReward)
    external
    payable
    payingRewards(msg.value, _inclusionReward, _tallyReward)
    resultNotIncluded(_id)
    override
  {
    // If DR included, inclusion reward should be zero
    if (requests[_id].drHash != 0) {
      require(
        _inclusionReward == 0,
        "Inclusion reward should be 0 (request reward already paid)"
      );
    }

    // Compute new rewards
    uint256 newInclusionReward = SafeMath.add(requests[_id].inclusionReward, _inclusionReward);
    uint256 newTallyReward = SafeMath.add(requests[_id].tallyReward, _tallyReward);
    uint256 newBlockReward = SafeMath.add(requests[_id].blockReward, SafeMath.sub(msg.value, SafeMath.add(_inclusionReward, _tallyReward)));
    
    // If gas price is increased, then check if new rewards cover gas costs
    if (tx.gasprice > requests[_id].gasPrice) {
      isPayingGasCosts(newInclusionReward, newTallyReward, newBlockReward);
      requests[_id].gasPrice = tx.gasprice;
    }

    // Update data request rewards
    requests[_id].inclusionReward = newInclusionReward;
    requests[_id].tallyReward = newTallyReward;
    requests[_id].blockReward = newBlockReward;
  }

  /// @dev Checks if the data requests from a list are claimable or not.
  /// @param _ids The list of data request identifiers to be checked.
  /// @return An array of booleans indicating if data requests are claimable or not.
  function checkDataRequestsClaimability(uint256[] calldata _ids) external view returns (bool[] memory) {
    uint256 idsLength = _ids.length;
    bool[] memory validIds = new bool[](idsLength);
    for (uint i = 0; i < idsLength; i++) {
      uint256 index = _ids[i];
      validIds[i] = (dataRequestCanBeClaimed(requests[index])) &&
        requests[index].drHash == 0 &&
        index < requests.length &&
        requests[index].result.length == 0;
    }

    return validIds;
  }

  /// @dev Returns the pkh of the data request claimer.
  /// @param _id The unique identifier of the data request to be checked.
  /// @return The pkh of the data request claimer.
  function getDataRequestPkhClaim(uint256 _id) external view returns (address) {
      return requests[_id].pkhClaim;
  }

  /// @dev Presents a proof of inclusion to prove that the request was posted into Witnet so as to unlock the inclusion reward that was put aside for the claiming identity (public key hash).
  /// @param _id The unique identifier of the data request.
  /// @param _poi A proof of inclusion proving that the data request appears listed in one recent block in Witnet.
  /// @param _index The index in the merkle tree.
  /// @param _blockHash The hash of the block in which the data request was inserted.
  /// @param _epoch The epoch in which the blockHash was created.
  function reportDataRequestInclusion(
    uint256 _id,
    uint256[] calldata _poi,
    uint256 _index,
    uint256 _blockHash,
    uint256 _epoch)
    external
    drNotIncluded(_id)
 {
    // Check the data request has been claimed
    require(dataRequestCanBeClaimed(requests[_id]) == false, "Data Request has not yet been claimed");

    // Ensures the request inclusion is reported after the epoch in which the request was posted
    require(
      requests[_id].epoch < _epoch,
      "The request inclusion must be reported after it is posted into the WRB");
    // Update the dr epoch
    requests[_id].epoch = _epoch;
    // Update the state upon which this function depends before the external call
    requests[_id].drHash = uint256(sha256(abi.encodePacked(requests[_id].drOutputHash, _poi[0])));
    require(
      blockRelay.verifyDrPoi(
      _poi,
      _blockHash,
      _epoch,
      _index,
      requests[_id].drOutputHash), "Invalid PoI");
    // This is the DR block inclusion reward, so we have to split it to reward the result block inclusion as well
    uint256 drRelayerPayment = requests[_id].blockReward / 2;
    // We subsctract this value from the reward that we will later pay for the inclusion of the reward block
    requests[_id].blockReward = requests[_id].blockReward - drRelayerPayment; 
    // Transfer the relayer payment to the block relayer
    address payable rewardedAddress = payable(getAddressBlockReward(_id, _blockHash));
    rewardedAddress.transfer(drRelayerPayment);
    // Transfer the DR inclusion reward to the inclusion verifier
    requests[_id].pkhClaim.transfer(requests[_id].inclusionReward);
    // Push requests[_id].pkhClaim to abs
    abs.pushActivity(requests[_id].pkhClaim, getBlockNumber());
    emit IncludedRequest(msg.sender, _id);
  }

  /// @dev Reports the result of a data request in Witnet.
  /// @param _id The unique identifier of the data request.
  /// @param _poi A proof of inclusion proving that the data in _result has been acknowledged by the Witnet network as being the final result for the data request by putting in a tally transaction inside a Witnet block.
  /// @param _index The position of the tally transaction in the tallies-only merkle tree in the Witnet block.
  /// @param _blockHash The hash of the block in which the result (tally) was inserted.
  /// @param _epoch The epoch in which the blockHash was created.
  /// @param _result The result itself as bytes.
  function reportResult(
    uint256 _id,
    uint256[] calldata _poi,
    uint256 _index,
    uint256 _blockHash,
    uint256 _epoch,
    bytes calldata _result)
    external
    drIncluded(_id)
    resultNotIncluded(_id)
    absMember(msg.sender)
 {
    // Ensures the result was published in a later block than the request
    require(requests[_id].epoch <= _epoch, "The result cannot be reported before the request is included");
    // Update epoch of the request
    requests[_id].epoch = _epoch;

    // Ensures the result byes do not have zero length
    // This would not be a valid encoding with CBOR and could trigger a reentrancy attack
    require(_result.length != 0, "Result has zero length");

    // Update the state upon which this function depends before the external call
    requests[_id].result = _result;

    uint256 resHash = uint256(sha256(abi.encodePacked(requests[_id].drHash, _result)));
    require(
      blockRelay.verifyTallyPoi(
      _poi,
      _blockHash,
      _epoch,
      _index,
      resHash), "Invalid PoI");
    address payable rewardedAddress = payable(getAddressBlockReward(_id, _blockHash));
    rewardedAddress.transfer(requests[_id].blockReward);
    msg.sender.transfer(requests[_id].tallyReward);

    emit PostedResult(msg.sender, _id);
  }

  /// @dev Retrieves the bytes of the serialization of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the data request as bytes.
  function readDataRequest(uint256 _id) external view validId(_id) validDrOutputHash(_id) returns(bytes memory) {
    Request requestContract = Request(requests[_id].requestAddress);
    return requestContract.bytecode();
  }

  /// @dev Retrieves the result (if already available) of one data request from the WRB.
  /// @param _id The unique identifier of the data request.
  /// @return The result of the DR
  function readResult(uint256 _id) external view override validId(_id) returns(bytes memory) {
    return requests[_id].result;
  }

  /// @dev Retrieves the gas price set for a specific DR ID.
  /// @param _id The unique identifier of the data request.
  /// @return The gas price set by the request creator.
  function readGasPrice(uint256 _id) external view validId(_id) returns(uint256) {
    return requests[_id].gasPrice;
  }

  /// @dev Retrieves hash of the data request transaction in Witnet.
  /// @param _id The unique identifier of the data request.
  /// @return The hash of the DataRequest transaction in Witnet.
  function readDrHash(uint256 _id) external view override validId(_id) returns(uint256) {
    return requests[_id].drHash;
  }

  /// @dev Returns the number of data requests in the WRB.
  /// @return the number of data requests in the WRB.
  function requestsCount() external view returns(uint256) {
    return requests.length;
  }

  /// @notice Wrapper around the decodeProof from VRF library.
  /// @dev Decode VRF proof from bytes.
  /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`.
  /// @return The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`.
  function decodeProof(bytes calldata _proof) external pure returns (uint[4] memory) {
    return VRF.decodeProof(_proof);
  }

  /// @notice Wrapper around the decodePoint from VRF library.
  /// @dev Decode EC point from bytes.
  /// @param _point The EC point as bytes.
  /// @return The point as `[point-x, point-y]`.
  function decodePoint(bytes calldata _point) external pure returns (uint[2] memory) {
    return VRF.decodePoint(_point);
  }

  /// @dev Wrapper around the computeFastVerifyParams from VRF library.
  /// @dev Compute the parameters (EC points) required for the VRF fast verification function..
  /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`.
  /// @param _proof The VRF proof as an array composed of `[gamma-x, gamma-y, c, s]`.
  /// @param _message The message (in bytes) used for computing the VRF.
  /// @return The fast verify required parameters as the tuple `([uPointX, uPointY], [sHX, sHY, cGammaX, cGammaY])`.
  function computeFastVerifyParams(uint256[2] calldata _publicKey, uint256[4] calldata _proof, bytes calldata _message)
    external pure returns (uint256[2] memory, uint256[4] memory)
  {
    return VRF.computeFastVerifyParams(_publicKey, _proof, _message);
  }

  /// @dev Wrapper around the gammaToHash from VRF library.
  /// @dev Convert proof to hash
  /// @param _gammaX The x coordinate of the gamma proof.
  /// @param _gammaY The y coordinate of the gamma proof.
  /// @return The resulting hash.
  function gammaToHash(uint256 _gammaX, uint256 _gammaY)
    internal pure virtual returns (uint256)
  {
    return uint256(VRF.gammaToHash(_gammaX, _gammaY));
  }

  /// @dev Updates the ABS activity with the block number provided.
  /// @param _blockNumber update the ABS until this block number.
  function updateAbsActivity(uint256 _blockNumber) external {
    require (_blockNumber <= getBlockNumber(), "The provided block number has not been reached");

    abs.updateActivity(_blockNumber);
  }

  /// @dev Verifies if the contract is upgradable.
  /// @return true if the contract upgradable.
  function isUpgradable(address _address) external view override returns(bool) {
    if (_address == witnet) {
      return true;
    }
    return false;
  }

  /// @dev Estimate the amount of reward we need to insert for a given gas price.
  /// @param _gasPrice The gas price for which we need to calculate the rewards.
  /// @return The rewards to be included for the given gas price as inclusionReward, resultReward, blockReward.
  function estimateGasCost(uint256 _gasPrice) public view override returns(uint256, uint256, uint256){
    return (
      SafeMath.mul(_gasPrice, MAX_CLAIM_DR_GAS + MAX_DR_INCLUSION_GAS), 
      SafeMath.mul(_gasPrice, MAX_REPORT_RESULT_GAS),  
      SafeMath.mul(_gasPrice, MAX_REPORT_BLOCK_GAS * 2)
    );
  }

  /// @dev Claim drs to be posted to Witnet by the node.
  /// @param _ids Data request ids to be claimed.
  /// @param _poe PoE claiming eligibility.
  /// @param _uPoint uPoint coordinates as [uPointX, uPointY] corresponding to U = s*B - c*Y.
  /// @param _vPointHelpers helpers for calculating the V point as [(s*H)X, (s*H)Y, cGammaX, cGammaY]. V = s*H + cGamma.
  function claimDataRequests(
    uint256[] memory _ids,
    uint256[4] memory _poe,
    uint256[2] memory _publicKey,
    uint256[2] memory _uPoint,
    uint256[4] memory _vPointHelpers,
    bytes memory addrSignature)
    public
    validSignature(_publicKey, addrSignature)
    poeValid(_poe,_publicKey, _uPoint,_vPointHelpers)
  returns(bool)
  {
    for (uint i = 0; i < _ids.length; i++) {
      require(
        dataRequestCanBeClaimed(requests[_ids[i]]),
        "One of the listed data requests was already claimed"
      );
      requests[_ids[i]].pkhClaim = msg.sender;
      requests[_ids[i]].blockNumber = getBlockNumber();
    }
    return true;
  }

  /// @dev Read the beacon of the last block inserted.
  /// @return bytes to be signed by the node as PoE.
  function getLastBeacon() public view virtual returns(bytes memory) {
    return blockRelay.getLastBeacon();
  }

  /// @dev Claim drs to be posted to Witnet by the node.
  /// @param _poe PoE claiming eligibility.
  /// @param _publicKey The public key as an array composed of `[pubKey-x, pubKey-y]`.
  /// @param _uPoint uPoint coordinates as [uPointX, uPointY] corresponding to U = s*B - c*Y.
  /// @param _vPointHelpers helpers for calculating the V point as [(s*H)X, (s*H)Y, cGammaX, cGammaY]. V = s*H + cGamma.
  function verifyPoe(
    uint256[4] memory _poe,
    uint256[2] memory _publicKey,
    uint256[2] memory _uPoint,
    uint256[4] memory _vPointHelpers)
    internal
    view
    vrfValid(_poe,_publicKey, _uPoint,_vPointHelpers)
  returns(bool)
  {
    uint256 vrf = gammaToHash(_poe[0], _poe[1]);
    // True if vrf/(2^{256} -1) <= repFactor/abs.activeIdentities
    if (uint256(abs.activeIdentities) < repFactor) {
      return true;
    }
    // We rewrote it as vrf <= ((2^{256} -1)/abs.activeIdentities)*repFactor to gain efficiency
    if (vrf <= ((~uint256(0)/uint256(abs.activeIdentities))*repFactor)) {
      return true;
    }

    return false;
  }

  /// @dev Verifies the validity of a signature.
  /// @param _message message to be verified.
  /// @param _publicKey public key of the signer as `[pubKey-x, pubKey-y]`.
  /// @param _addrSignature the signature to verify asas r||s||v.
  /// @return true or false depending the validity.
  function verifySig(
    bytes memory _message,
    uint256[2] memory _publicKey,
    bytes memory _addrSignature)
    internal
    pure
  returns(bool)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
            r := mload(add(_addrSignature, 0x20))
            s := mload(add(_addrSignature, 0x40))
            v := byte(0, mload(add(_addrSignature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return false;
    }

    if (v != 0 && v != 1) {
      return false;
    }
    v = 28 - v;

    bytes32 msgHash = sha256(_message);
    address hashedKey = VRF.pointToAddress(_publicKey[0], _publicKey[1]);
    return ecrecover(
      msgHash,
      v,
      r,
      s) == hashedKey;
  }

  function dataRequestCanBeClaimed(DataRequest memory _request) private view returns (bool) {
    return
      (_request.blockNumber == 0 || getBlockNumber() - _request.blockNumber > CLAIM_EXPIRATION) &&
      _request.drHash == 0 &&
      _request.result.length == 0;
  }

  /// @dev Ensures that rewards cover at least the gas cost needed for the complete DR life cycle within the Witnet Request Board.
  /// @param _inclusionReward The amount for rewarding the reporting of the inclusion of the data request.
  /// @param _tallyReward The amount for rewarding the reporting of the final result (aka tally) of the data request.
  /// @param _blockReward The amount for rewarding the reporting of the blocks containing the DR inclusion and the DR result.
  function isPayingGasCosts(uint256 _inclusionReward, uint256 _tallyReward, uint256 _blockReward) internal view {
    (uint256 minInclusionReward, uint256 minResultReward, uint256 minBlockReward) =  estimateGasCost(tx.gasprice);
    require(_inclusionReward >= minInclusionReward, "Inclusion reward should cover gas expenses. Check the estimateGasCost method.");
    require(_tallyReward >= minResultReward, "Result reward should cover gas expenses. Check the estimateGasCost method.");
    require(_blockReward >= minBlockReward, "Block reward should cover gas expenses. Check the estimateGasCost method.");
  }

  function getBlockNumber() internal view virtual returns (uint256) {
    return block.number;
  }

  /// @dev Returns the relayer address or the requester address in case the block inclusion was already paid
  /// @param _id The unique identifier of the data request.
  /// @param _blockHash The hash of the block which inclusion has to be rewarded.
  function getAddressBlockReward(uint256 _id, uint256 _blockHash) internal returns (address) {
      if (paidBlocks[_blockHash] == true) {
          return requests[_id].requestor;
      } else {
          paidBlocks[_blockHash] = true;
          return blockRelay.readRelayerAddress(_blockHash, requests[_id].epoch);
      }
  }
}
