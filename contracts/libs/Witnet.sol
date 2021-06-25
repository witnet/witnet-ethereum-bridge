// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./CBOR.sol";

/**
 * @title A library for decoding Witnet request results
 * @notice The library exposes functions to check the Witnet request success.
 * and retrieve Witnet results from CBOR values into solidity types.
 */
library Witnet {
  using CBOR for WitnetTypes.CBOR;

  /**
   * @notice Decode raw CBOR bytes into a WitnetTypes.Result instance.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `WitnetTypes.Result` instance.
   */
  function resultFromCborBytes(bytes calldata _cborBytes) external pure returns(WitnetTypes.Result memory) {
    WitnetTypes.CBOR memory cborValue = CBOR.valueFromBytes(_cborBytes);
    return resultFromCborValue(cborValue);
  }

  /**
   * @notice Decode a CBOR value into a WitnetTypes.Result instance.
   * @param _cborValue An instance of `WitnetTypes.Value`.
   * @return A `WitnetTypes.Result` instance.
   */
  function resultFromCborValue(WitnetTypes.CBOR memory _cborValue) public pure returns(WitnetTypes.Result memory) {
    // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
    // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
    bool success = _cborValue.tag != 39;
    return WitnetTypes.Result(success, _cborValue);
  }

  /**
   * @notice Tell if a WitnetTypes.Result is successful.
   * @param _result An instance of WitnetTypes.Result.
   * @return `true` if successful, `false` if errored.
   */
  function isOk(WitnetTypes.Result memory _result) external pure returns(bool) {
    return _result.success;
  }

  /**
   * @notice Tell if a WitnetTypes.Result is errored.
   * @param _result An instance of WitnetTypes.Result.
   * @return `true` if errored, `false` if successful.
   */
  function isError(WitnetTypes.Result memory _result) external pure returns(bool) {
    return !_result.success;
  }

  /**
   * @notice Decode a bytes value from a WitnetTypes.Result as a `bytes` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `bytes` decoded from the WitnetTypes.Result.
   */
  function asBytes(WitnetTypes.Result memory _result) external pure returns(bytes memory) {
    require(_result.success, "Tried to read bytes value from errored WitnetTypes.Result");
    return _result.value.decodeBytes();
  }

  /**
   * @notice Decode an error code from a WitnetTypes.Result as a member of `WitnetTypes.ErrorCodes`.
   * @param _result An instance of `WitnetTypes.Result`.
   * @return The `CBORValue.Error memory` decoded from the WitnetTypes.Result.
   */
  function asErrorCode(WitnetTypes.Result memory _result) external pure returns(WitnetTypes.ErrorCodes) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return WitnetTypes.ErrorCodes.Unknown;
    }

    return supportedErrorOrElseUnknown(error[0]);
  }

  /**
   * @notice Generate a suitable error message for a member of `WitnetTypes.ErrorCodes` and its corresponding arguments.
   * @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
   * @param _result An instance of `WitnetTypes.Result`.
   * @return A tuple containing the `CBORValue.Error memory` decoded from the `WitnetTypes.Result`, plus a loggable error message.
   */

  function asErrorMessage(WitnetTypes.Result memory _result) public pure returns (WitnetTypes.ErrorCodes, string memory) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return (WitnetTypes.ErrorCodes.Unknown, "Unknown error (no error code)");
    }
    WitnetTypes.ErrorCodes errorCode = supportedErrorOrElseUnknown(error[0]);
    bytes memory errorMessage;

    if (errorCode == WitnetTypes.ErrorCodes.SourceScriptNotCBOR && error.length >= 2) {
        errorMessage = abi.encodePacked("Source script #", utoa(error[1]), " was not a valid CBOR value");
    } else if (errorCode == WitnetTypes.ErrorCodes.SourceScriptNotArray && error.length >= 2) {
        errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not an Array of calls");
    } else if (errorCode == WitnetTypes.ErrorCodes.SourceScriptNotRADON && error.length >= 2) {
        errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not a valid RADON script");
    } else if (errorCode == WitnetTypes.ErrorCodes.RequestTooManySources && error.length >= 2) {
        errorMessage = abi.encodePacked("The request contained too many sources (", utoa(error[1]), ")");
    } else if (errorCode == WitnetTypes.ErrorCodes.ScriptTooManyCalls && error.length >= 4) {
        errorMessage = abi.encodePacked(
          "Script #",
          utoa(error[2]),
          " from the ",
          stageName(error[1]),
          " stage contained too many calls (",
          utoa(error[3]),
          ")"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.UnsupportedOperator && error.length >= 5) {
        errorMessage = abi.encodePacked(
        "Operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage is not supported"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.HTTP && error.length >= 3) {
        errorMessage = abi.encodePacked(
          "Source #",
          utoa(error[1]),
          " could not be retrieved. Failed with HTTP error code: ",
          utoa(error[2] / 100),
          utoa(error[2] % 100 / 10),
          utoa(error[2] % 10)
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.RetrievalTimeout && error.length >= 2) {
        errorMessage = abi.encodePacked(
          "Source #",
          utoa(error[1]),
          " could not be retrieved because of a timeout"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.Underflow && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Underflow at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.Overflow && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Overflow at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.DivisionByZero && error.length >= 5) {
        errorMessage = abi.encodePacked(
          "Division by zero at operator code 0x",
          utohex(error[4]),
          " found at call #",
          utoa(error[3]),
          " in script #",
          utoa(error[2]),
          " from ",
          stageName(error[1]),
          " stage"
        );
    } else if (errorCode == WitnetTypes.ErrorCodes.BridgeMalformedRequest) {
        errorMessage = "The structure of the request is invalid and it cannot be parsed";
    } else if (errorCode == WitnetTypes.ErrorCodes.BridgePoorIncentives) {
        errorMessage = "The request has been rejected by the bridge node due to poor incentives";
    } else if (errorCode == WitnetTypes.ErrorCodes.BridgeOversizedResult) {
        errorMessage = "The request result length exceeds a bridge contract defined limit";
    } else {
        errorMessage = abi.encodePacked("Unknown error (0x", utohex(error[0]), ")");
    }

    return (errorCode, string(errorMessage));
  }

  /**
   * @notice Decode a raw error from a `WitnetTypes.Result` as a `uint64[]`.
   * @param _result An instance of `WitnetTypes.Result`.
   * @return The `uint64[]` raw error as decoded from the `WitnetTypes.Result`.
   */
  function asRawError(WitnetTypes.Result memory _result) public pure returns(uint64[] memory) {
    require(!_result.success, "Tried to read error code from successful WitnetTypes.Result");
    return _result.value.decodeUint64Array();
  }

  /**
   * @notice Decode a boolean value from a WitnetTypes.Result as an `bool` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `bool` decoded from the WitnetTypes.Result.
   */
  function asBool(WitnetTypes.Result memory _result) external pure returns(bool) {
    require(_result.success, "Tried to read `bool` value from errored WitnetTypes.Result");
    return _result.value.decodeBool();
  }

  /**
   * @notice Decode a fixed16 (half-precision) numeric value from a WitnetTypes.Result as an `int32` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `int128` decoded from the WitnetTypes.Result.
   */
  function asFixed16(WitnetTypes.Result memory _result) external pure returns(int32) {
    require(_result.success, "Tried to read `fixed16` value from errored WitnetTypes.Result");
    return _result.value.decodeFixed16();
  }

  /**
   * @notice Decode an array of fixed16 values from a WitnetTypes.Result as an `int128[]` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `int128[]` decoded from the WitnetTypes.Result.
   */
  function asFixed16Array(WitnetTypes.Result memory _result) external pure returns(int32[] memory) {
    require(_result.success, "Tried to read `fixed16[]` value from errored WitnetTypes.Result");
    return _result.value.decodeFixed16Array();
  }

  /**
   * @notice Decode a integer numeric value from a WitnetTypes.Result as an `int128` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `int128` decoded from the WitnetTypes.Result.
   */
  function asInt128(WitnetTypes.Result memory _result) external pure returns(int128) {
    require(_result.success, "Tried to read `int128` value from errored WitnetTypes.Result");
    return _result.value.decodeInt128();
  }

  /**
   * @notice Decode an array of integer numeric values from a WitnetTypes.Result as an `int128[]` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `int128[]` decoded from the WitnetTypes.Result.
   */
  function asInt128Array(WitnetTypes.Result memory _result) external pure returns(int128[] memory) {
    require(_result.success, "Tried to read `int128[]` value from errored WitnetTypes.Result");
    return _result.value.decodeInt128Array();
  }

  /**
   * @notice Decode a string value from a WitnetTypes.Result as a `string` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `string` decoded from the WitnetTypes.Result.
   */
  function asString(WitnetTypes.Result memory _result) external pure returns(string memory) {
    require(_result.success, "Tried to read `string` value from errored WitnetTypes.Result");
    return _result.value.decodeString();
  }

  /**
   * @notice Decode an array of string values from a WitnetTypes.Result as a `string[]` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `string[]` decoded from the WitnetTypes.Result.
   */
  function asStringArray(WitnetTypes.Result memory _result) external pure returns(string[] memory) {
    require(_result.success, "Tried to read `string[]` value from errored WitnetTypes.Result");
    return _result.value.decodeStringArray();
  }

  /**
   * @notice Decode a natural numeric value from a WitnetTypes.Result as a `uint64` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `uint64` decoded from the WitnetTypes.Result.
   */
  function asUint64(WitnetTypes.Result memory _result) external pure returns(uint64) {
    require(_result.success, "Tried to read `uint64` value from errored WitnetTypes.Result");
    return _result.value.decodeUint64();
  }

  /**
   * @notice Decode an array of natural numeric values from a WitnetTypes.Result as a `uint64[]` value.
   * @param _result An instance of WitnetTypes.Result.
   * @return The `uint64[]` decoded from the WitnetTypes.Result.
   */
  function asUint64Array(WitnetTypes.Result memory _result) external pure returns(uint64[] memory) {
    require(_result.success, "Tried to read `uint64[]` value from errored WitnetTypes.Result");
    return _result.value.decodeUint64Array();
  }

  /**
   * @notice Convert a stage index number into the name of the matching Witnet request stage.
   * @param _stageIndex A `uint64` identifying the index of one of the Witnet request stages.
   * @return The name of the matching stage.
   */
  function stageName(uint64 _stageIndex) public pure returns(string memory) {
    if (_stageIndex == 0) {
      return "retrieval";
    } else if (_stageIndex == 1) {
      return "aggregation";
    } else if (_stageIndex == 2) {
      return "tally";
    } else {
      return "unknown";
    }
  }

  /**
   * @notice Get an `WitnetTypes.ErrorCodes` item from its `uint64` discriminant.
   * @param _discriminant The numeric identifier of an error.
   * @return A member of `WitnetTypes.ErrorCodes`.
   */
  function supportedErrorOrElseUnknown(uint64 _discriminant) private pure returns(WitnetTypes.ErrorCodes) {
      return WitnetTypes.ErrorCodes(_discriminant);
  }

  /**
   * @notice Convert a `uint64` into a 1, 2 or 3 characters long `string` representing its.
   * three less significant decimal values.
   * @param _u A `uint64` value.
   * @return The `string` representing its decimal value.
   */
  function utoa(uint64 _u) private pure returns(string memory) {
    if (_u < 10) {
      bytes memory b1 = new bytes(1);
      b1[0] = bytes1(uint8(_u) + 48);
      return string(b1);
    } else if (_u < 100) {
      bytes memory b2 = new bytes(2);
      b2[0] = bytes1(uint8(_u / 10) + 48);
      b2[1] = bytes1(uint8(_u % 10) + 48);
      return string(b2);
    } else {
      bytes memory b3 = new bytes(3);
      b3[0] = bytes1(uint8(_u / 100) + 48);
      b3[1] = bytes1(uint8(_u % 100 / 10) + 48);
      b3[2] = bytes1(uint8(_u % 10) + 48);
      return string(b3);
    }
  }

  /**
   * @notice Convert a `uint64` into a 2 characters long `string` representing its two less significant hexadecimal values.
   * @param _u A `uint64` value.
   * @return The `string` representing its hexadecimal value.
   */
  function utohex(uint64 _u) private pure returns(string memory) {
    bytes memory b2 = new bytes(2);
    uint8 d0 = uint8(_u / 16) + 48;
    uint8 d1 = uint8(_u % 16) + 48;
    if (d0 > 57)
      d0 += 7;
    if (d1 > 57)
      d1 += 7;
    b2[0] = bytes1(d0);
    b2[1] = bytes1(d1);
    return string(b2);
  }
}
