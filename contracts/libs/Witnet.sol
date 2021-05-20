// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./CBOR.sol";


/**
 * @title A library for decoding Witnet request results
 * @notice The library exposes functions to check the Witnet request success.
 * and retrieve Witnet results from CBOR values into solidity types.
 */
library Witnet {
  using CBOR for CBOR.Value;

  /*
   *  STRUCTS
   */
  struct Result {
    bool success;
    CBOR.Value cborValue;
  }

  /*
   *  ENUMS
   */
  enum ErrorCodes {
    // 0x00: Unknown error. Something went really bad!
    Unknown,
    // Script format errors
    /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
    SourceScriptNotCBOR,
    /// 0x02: The CBOR value decoded from a source script is not an Array.
    SourceScriptNotArray,
    /// 0x03: The Array value decoded form a source script is not a valid RADON script.
    SourceScriptNotRADON,
    /// Unallocated
    ScriptFormat0x04,
    ScriptFormat0x05,
    ScriptFormat0x06,
    ScriptFormat0x07,
    ScriptFormat0x08,
    ScriptFormat0x09,
    ScriptFormat0x0A,
    ScriptFormat0x0B,
    ScriptFormat0x0C,
    ScriptFormat0x0D,
    ScriptFormat0x0E,
    ScriptFormat0x0F,
    // Complexity errors
    /// 0x10: The request contains too many sources.
    RequestTooManySources,
    /// 0x11: The script contains too many calls.
    ScriptTooManyCalls,
    /// Unallocated
    Complexity0x12,
    Complexity0x13,
    Complexity0x14,
    Complexity0x15,
    Complexity0x16,
    Complexity0x17,
    Complexity0x18,
    Complexity0x19,
    Complexity0x1A,
    Complexity0x1B,
    Complexity0x1C,
    Complexity0x1D,
    Complexity0x1E,
    Complexity0x1F,
    // Operator errors
    /// 0x20: The operator does not exist.
    UnsupportedOperator,
    /// Unallocated
    Operator0x21,
    Operator0x22,
    Operator0x23,
    Operator0x24,
    Operator0x25,
    Operator0x26,
    Operator0x27,
    Operator0x28,
    Operator0x29,
    Operator0x2A,
    Operator0x2B,
    Operator0x2C,
    Operator0x2D,
    Operator0x2E,
    Operator0x2F,
    // Retrieval-specific errors
    /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
    HTTP,
    /// 0x31: Retrieval of at least one of the sources timed out.
    RetrievalTimeout,
    /// Unallocated
    Retrieval0x32,
    Retrieval0x33,
    Retrieval0x34,
    Retrieval0x35,
    Retrieval0x36,
    Retrieval0x37,
    Retrieval0x38,
    Retrieval0x39,
    Retrieval0x3A,
    Retrieval0x3B,
    Retrieval0x3C,
    Retrieval0x3D,
    Retrieval0x3E,
    Retrieval0x3F,
    // Math errors
    /// 0x40: Math operator caused an underflow.
    Underflow,
    /// 0x41: Math operator caused an overflow.
    Overflow,
    /// 0x42: Tried to divide by zero.
    DivisionByZero,
    /// Unallocated
    Math0x43,
    Math0x44,
    Math0x45,
    Math0x46,
    Math0x47,
    Math0x48,
    Math0x49,
    Math0x4A,
    Math0x4B,
    Math0x4C,
    Math0x4D,
    Math0x4E,
    Math0x4F,
    // Other errors
    /// 0x50: Received zero reveals
    NoReveals,
    /// 0x51: Insufficient consensus in tally precondition clause
    InsufficientConsensus,
    /// 0x52: Received zero commits
    InsufficientCommits,
    /// 0x53: Generic error during tally execution
    TallyExecution,
    /// Unallocated
    OtherError0x54,
    OtherError0x55,
    OtherError0x56,
    OtherError0x57,
    OtherError0x58,
    OtherError0x59,
    OtherError0x5A,
    OtherError0x5B,
    OtherError0x5C,
    OtherError0x5D,
    OtherError0x5E,
    OtherError0x5F,
    /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
    MalformedReveal,
    /// Unallocated
    OtherError0x61,
    OtherError0x62,
    OtherError0x63,
    OtherError0x64,
    OtherError0x65,
    OtherError0x66,
    OtherError0x67,
    OtherError0x68,
    OtherError0x69,
    OtherError0x6A,
    OtherError0x6B,
    OtherError0x6C,
    OtherError0x6D,
    OtherError0x6E,
    OtherError0x6F,
    // Access errors
    /// 0x70: Tried to access a value from an index using an index that is out of bounds
    ArrayIndexOutOfBounds,
    /// 0x71: Tried to access a value from a map using a key that does not exist
    MapKeyNotFound,
    /// Unallocated
    OtherError0x72,
    OtherError0x73,
    OtherError0x74,
    OtherError0x75,
    OtherError0x76,
    OtherError0x77,
    OtherError0x78,
    OtherError0x79,
    OtherError0x7A,
    OtherError0x7B,
    OtherError0x7C,
    OtherError0x7D,
    OtherError0x7E,
    OtherError0x7F,
    OtherError0x80,
    OtherError0x81,
    OtherError0x82,
    OtherError0x83,
    OtherError0x84,
    OtherError0x85,
    OtherError0x86,
    OtherError0x87,
    OtherError0x88,
    OtherError0x89,
    OtherError0x8A,
    OtherError0x8B,
    OtherError0x8C,
    OtherError0x8D,
    OtherError0x8E,
    OtherError0x8F,
    OtherError0x90,
    OtherError0x91,
    OtherError0x92,
    OtherError0x93,
    OtherError0x94,
    OtherError0x95,
    OtherError0x96,
    OtherError0x97,
    OtherError0x98,
    OtherError0x99,
    OtherError0x9A,
    OtherError0x9B,
    OtherError0x9C,
    OtherError0x9D,
    OtherError0x9E,
    OtherError0x9F,
    OtherError0xA0,
    OtherError0xA1,
    OtherError0xA2,
    OtherError0xA3,
    OtherError0xA4,
    OtherError0xA5,
    OtherError0xA6,
    OtherError0xA7,
    OtherError0xA8,
    OtherError0xA9,
    OtherError0xAA,
    OtherError0xAB,
    OtherError0xAC,
    OtherError0xAD,
    OtherError0xAE,
    OtherError0xAF,
    OtherError0xB0,
    OtherError0xB1,
    OtherError0xB2,
    OtherError0xB3,
    OtherError0xB4,
    OtherError0xB5,
    OtherError0xB6,
    OtherError0xB7,
    OtherError0xB8,
    OtherError0xB9,
    OtherError0xBA,
    OtherError0xBB,
    OtherError0xBC,
    OtherError0xBD,
    OtherError0xBE,
    OtherError0xBF,
    OtherError0xC0,
    OtherError0xC1,
    OtherError0xC2,
    OtherError0xC3,
    OtherError0xC4,
    OtherError0xC5,
    OtherError0xC6,
    OtherError0xC7,
    OtherError0xC8,
    OtherError0xC9,
    OtherError0xCA,
    OtherError0xCB,
    OtherError0xCC,
    OtherError0xCD,
    OtherError0xCE,
    OtherError0xCF,
    OtherError0xD0,
    OtherError0xD1,
    OtherError0xD2,
    OtherError0xD3,
    OtherError0xD4,
    OtherError0xD5,
    OtherError0xD6,
    OtherError0xD7,
    OtherError0xD8,
    OtherError0xD9,
    OtherError0xDA,
    OtherError0xDB,
    OtherError0xDC,
    OtherError0xDD,
    OtherError0xDE,
    OtherError0xDF,
    // Bridge errors: errors that only belong in inter-client communication
    /// 0xE0: Requests that cannot be parsed must always get this error as their result.
    /// However, this is not a valid result in a Tally transaction, because invalid requests
    /// are never included into blocks and therefore never get a Tally in response.
    BridgeMalformedRequest,
    /// 0xE1: Witnesses exceeds 100
    BridgePoorIncentives,
    /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
    /// amount of value that is unjustifiably high when compared with the reward they will be getting
    BridgeOversizedResult,
    /// Unallocated
    OtherError0xE3,
    OtherError0xE4,
    OtherError0xE5,
    OtherError0xE6,
    OtherError0xE7,
    OtherError0xE8,
    OtherError0xE9,
    OtherError0xEA,
    OtherError0xEB,
    OtherError0xEC,
    OtherError0xED,
    OtherError0xEE,
    OtherError0xEF,
    OtherError0xF0,
    OtherError0xF1,
    OtherError0xF2,
    OtherError0xF3,
    OtherError0xF4,
    OtherError0xF5,
    OtherError0xF6,
    OtherError0xF7,
    OtherError0xF8,
    OtherError0xF9,
    OtherError0xFA,
    OtherError0xFB,
    OtherError0xFC,
    OtherError0xFD,
    OtherError0xFE,
    // This should not exist:
    /// 0xFF: Some tally error is not intercepted but should
    UnhandledIntercept
  }

  /*
   * Result impl's
   */

  /**
   * @notice Decode raw CBOR bytes into a Result instance.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `Result` instance.
   */
  function resultFromCborBytes(bytes calldata _cborBytes) external pure returns(Result memory) {
    CBOR.Value memory cborValue = CBOR.valueFromBytes(_cborBytes);
    return resultFromCborValue(cborValue);
  }

  /**
   * @notice Decode a CBOR value into a Result instance.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return A `Result` instance.
   */
  function resultFromCborValue(CBOR.Value memory _cborValue) public pure returns(Result memory) {
    // Witnet uses CBOR tag 39 to represent RADON error code identifiers.
    // [CBOR tag 39] Identifiers for CBOR: https://github.com/lucas-clemente/cbor-specs/blob/master/id.md
    bool success = _cborValue.tag != 39;
    return Result(success, _cborValue);
  }

  /**
   * @notice Tell if a Result is successful.
   * @param _result An instance of Result.
   * @return `true` if successful, `false` if errored.
   */
  function isOk(Result memory _result) public pure returns(bool) {
    return _result.success;
  }

  /**
   * @notice Tell if a Result is errored.
   * @param _result An instance of Result.
   * @return `true` if errored, `false` if successful.
   */
  function isError(Result memory _result) public pure returns(bool) {
    return !_result.success;
  }

  /**
   * @notice Decode a bytes value from a Result as a `bytes` value.
   * @param _result An instance of Result.
   * @return The `bytes` decoded from the Result.
   */
  function asBytes(Result memory _result) public pure returns(bytes memory) {
    require(_result.success, "Tried to read bytes value from errored Result");
    return _result.cborValue.decodeBytes();
  }

  /**
   * @notice Decode an error code from a Result as a member of `ErrorCodes`.
   * @param _result An instance of `Result`.
   * @return The `CBORValue.Error memory` decoded from the Result.
   */
  function asErrorCode(Result memory _result) public pure returns(ErrorCodes) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return ErrorCodes.Unknown;
    }

    return supportedErrorOrElseUnknown(error[0]);
  }

  /**
   * @notice Generate a suitable error message for a member of `ErrorCodes` and its corresponding arguments.
   * @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
   * @param _result An instance of `Result`.
   * @return A tuple containing the `CBORValue.Error memory` decoded from the `Result`, plus a loggable error message.
   */
  function asErrorMessage(Result memory _result) public pure returns(ErrorCodes, string memory) {
    uint64[] memory error = asRawError(_result);
    if (error.length == 0) {
      return (ErrorCodes.Unknown, "Unknown error (no error code)");
    }
    ErrorCodes errorCode = supportedErrorOrElseUnknown(error[0]);
    bytes memory errorMessage;

    if (errorCode == ErrorCodes.SourceScriptNotCBOR && error.length >= 2) {
      errorMessage = abi.encodePacked("Source script #", utoa(error[1]), " was not a valid CBOR value");
    } else if (errorCode == ErrorCodes.SourceScriptNotArray && error.length >= 2) {
      errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not an Array of calls");
    } else if (errorCode == ErrorCodes.SourceScriptNotRADON && error.length >= 2) {
      errorMessage = abi.encodePacked("The CBOR value in script #", utoa(error[1]), " was not a valid RADON script");
    } else if (errorCode == ErrorCodes.RequestTooManySources && error.length >= 2) {
      errorMessage = abi.encodePacked("The request contained too many sources (", utoa(error[1]), ")");
    } else if (errorCode == ErrorCodes.ScriptTooManyCalls && error.length >= 4) {
      errorMessage = abi.encodePacked(
        "Script #",
        utoa(error[2]),
        " from the ",
        stageName(error[1]),
        " stage contained too many calls (",
        utoa(error[3]),
        ")"
      );
    } else if (errorCode == ErrorCodes.UnsupportedOperator && error.length >= 5) {
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
    } else if (errorCode == ErrorCodes.HTTP && error.length >= 3) {
      errorMessage = abi.encodePacked(
        "Source #",
        utoa(error[1]),
        " could not be retrieved. Failed with HTTP error code: ",
        utoa(error[2] / 100),
        utoa(error[2] % 100 / 10),
        utoa(error[2] % 10)
      );
    } else if (errorCode == ErrorCodes.RetrievalTimeout && error.length >= 2) {
      errorMessage = abi.encodePacked(
        "Source #",
        utoa(error[1]),
        " could not be retrieved because of a timeout."
      );
    } else if (errorCode == ErrorCodes.Underflow && error.length >= 5) {
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
    } else if (errorCode == ErrorCodes.Overflow && error.length >= 5) {
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
    } else if (errorCode == ErrorCodes.DivisionByZero && error.length >= 5) {
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
    } else {
      errorMessage = abi.encodePacked("Unknown error (0x", utohex(error[0]), ")");
    }

    return (errorCode, string(errorMessage));
  }

  /**
   * @notice Decode a raw error from a `Result` as a `uint64[]`.
   * @param _result An instance of `Result`.
   * @return The `uint64[]` raw error as decoded from the `Result`.
   */
  function asRawError(Result memory _result) public pure returns(uint64[] memory) {
    require(!_result.success, "Tried to read error code from successful Result");
    return _result.cborValue.decodeUint64Array();
  }

  /**
   * @notice Decode a fixed16 (half-precision) numeric value from a Result as an `int32` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _result An instance of Result.
   * @return The `int128` decoded from the Result.
   */
  function asFixed16(Result memory _result) public pure returns(int32) {
    require(_result.success, "Tried to read `fixed16` value from errored Result");
    return _result.cborValue.decodeFixed16();
  }

  /**
   * @notice Decode an array of fixed16 values from a Result as an `int128[]` value.
   * @param _result An instance of Result.
   * @return The `int128[]` decoded from the Result.
   */
  function asFixed16Array(Result memory _result) public pure returns(int32[] memory) {
    require(_result.success, "Tried to read `fixed16[]` value from errored Result");
    return _result.cborValue.decodeFixed16Array();
  }

  /**
   * @notice Decode a integer numeric value from a Result as an `int128` value.
   * @param _result An instance of Result.
   * @return The `int128` decoded from the Result.
   */
  function asInt128(Result memory _result) public pure returns(int128) {
    require(_result.success, "Tried to read `int128` value from errored Result");
    return _result.cborValue.decodeInt128();
  }

  /**
   * @notice Decode an array of integer numeric values from a Result as an `int128[]` value.
   * @param _result An instance of Result.
   * @return The `int128[]` decoded from the Result.
   */
  function asInt128Array(Result memory _result) public pure returns(int128[] memory) {
    require(_result.success, "Tried to read `int128[]` value from errored Result");
    return _result.cborValue.decodeInt128Array();
  }

  /**
   * @notice Decode a string value from a Result as a `string` value.
   * @param _result An instance of Result.
   * @return The `string` decoded from the Result.
   */
  function asString(Result memory _result) public pure returns(string memory) {
    require(_result.success, "Tried to read `string` value from errored Result");
    return _result.cborValue.decodeString();
  }

  /**
   * @notice Decode an array of string values from a Result as a `string[]` value.
   * @param _result An instance of Result.
   * @return The `string[]` decoded from the Result.
   */
  function asStringArray(Result memory _result) public pure returns(string[] memory) {
    require(_result.success, "Tried to read `string[]` value from errored Result");
    return _result.cborValue.decodeStringArray();
  }

  /**
   * @notice Decode a natural numeric value from a Result as a `uint64` value.
   * @param _result An instance of Result.
   * @return The `uint64` decoded from the Result.
   */
  function asUint64(Result memory _result) public pure returns(uint64) {
    require(_result.success, "Tried to read `uint64` value from errored Result");
    return _result.cborValue.decodeUint64();
  }

  /**
   * @notice Decode an array of natural numeric values from a Result as a `uint64[]` value.
   * @param _result An instance of Result.
   * @return The `uint64[]` decoded from the Result.
   */
  function asUint64Array(Result memory _result) public pure returns(uint64[] memory) {
    require(_result.success, "Tried to read `uint64[]` value from errored Result");
    return _result.cborValue.decodeUint64Array();
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
   * @notice Get an `ErrorCodes` item from its `uint64` discriminant.
   * @param _discriminant The numeric identifier of an error.
   * @return A member of `ErrorCodes`.
   */
  function supportedErrorOrElseUnknown(uint64 _discriminant) private pure returns(ErrorCodes) {
      return ErrorCodes(_discriminant);
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
      b1[0] = byte(uint8(_u) + 48);
      return string(b1);
    } else if (_u < 100) {
      bytes memory b2 = new bytes(2);
      b2[0] = byte(uint8(_u / 10) + 48);
      b2[1] = byte(uint8(_u % 10) + 48);
      return string(b2);
    } else {
      bytes memory b3 = new bytes(3);
      b3[0] = byte(uint8(_u / 100) + 48);
      b3[1] = byte(uint8(_u % 100 / 10) + 48);
      b3[2] = byte(uint8(_u % 10) + 48);
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
    b2[0] = byte(d0);
    b2[1] = byte(d1);
    return string(b2);
  }
}
