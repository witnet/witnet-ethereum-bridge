// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./BufferLib.sol";


/**
 * @title A minimalistic implementation of “RFC 7049 Concise Binary Object Representation”
 * @notice This library leverages a buffer-like structure for step-by-step decoding of bytes so as to minimize
 * the gas cost of decoding them into a useful native type.
 * @dev Most of the logic has been borrowed from Patrick Gansterer’s cbor.js library: https://github.com/paroga/cbor-js
 * TODO: add support for Array (majorType = 4)
 * TODO: add support for Map (majorType = 5)
 * TODO: add support for Float32 (majorType = 7, additionalInformation = 26)
 * TODO: add support for Float64 (majorType = 7, additionalInformation = 27)
 */
library CBOR {
  using BufferLib for BufferLib.Buffer;

  uint64 constant internal UINT64_MAX = ~uint64(0);

  struct Value {
    BufferLib.Buffer buffer;
    uint8 initialByte;
    uint8 majorType;
    uint8 additionalInformation;
    uint64 len;
    uint64 tag;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `bool` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `bool` value.
   */
  function decodeBool(Value memory _cborValue) public pure returns(bool) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(_cborValue.majorType == 7, "Tried to read a `bool` value from a `CBOR.Value` with majorType != 7");
    if (_cborValue.len == 20) {
      return false;
    } else if (_cborValue.len == 21) {
      return true;
    } else {
      revert("Tried to read `bool` from a `CBOR.Value` with len different than 20 or 21");
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `bytes` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `bytes` value.
   */
  function decodeBytes(Value memory _cborValue) public pure returns(bytes memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == UINT64_MAX) {
      bytes memory bytesData;

      // These checks look repetitive but the equivalent loop would be more expensive.
      uint32 itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
      if (itemLength < UINT64_MAX) {
        bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        itemLength = uint32(readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType));
        if (itemLength < UINT64_MAX) {
          bytesData = abi.encodePacked(bytesData, _cborValue.buffer.read(itemLength));
        }
      }
      return bytesData;
    } else {
      return _cborValue.buffer.read(uint32(_cborValue.len));
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a `fixed16` value.
   * @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values
   * by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`
   * use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeFixed16(Value memory _cborValue) public pure returns(int32) {
    require(_cborValue.majorType == 7, "Tried to read a `fixed` value from a `CBOR.Value` with majorType != 7");
    require(_cborValue.additionalInformation == 25, "Tried to read `fixed16` from a `CBOR.Value` with additionalInformation != 25");
    return _cborValue.buffer.readFloat16();
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128[]` value whose inner values follow the same convention.
   * as explained in `decodeFixed16`.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeFixed16Array(Value memory _cborValue) public pure returns(int32[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int32[] memory array = new int32[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeFixed16(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128` value.
   */
  function decodeInt128(Value memory _cborValue) public pure returns(int128) {
    if (_cborValue.majorType == 1) {
      uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
      return int128(-1) - int128(length);
    } else if (_cborValue.majorType == 0) {
      // Any `uint64` can be safely casted to `int128`, so this method supports majorType 1 as well so as to have offer
      // a uniform API for positive and negative numbers
      return int128(decodeUint64(_cborValue));
    }
    revert("Tried to read `int128` from a `CBOR.Value` with majorType not 0 or 1");
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `int128[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `int128[]` value.
   */
  function decodeInt128Array(Value memory _cborValue) public pure returns(int128[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `int128[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    int128[] memory array = new int128[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeInt128(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `string` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as a `string` value.
   */
  function decodeString(Value memory _cborValue) public pure returns(string memory) {
    _cborValue.len = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    if (_cborValue.len == UINT64_MAX) {
      bytes memory textData;
      bool done;
      while (!done) {
        uint64 itemLength = readIndefiniteStringLength(_cborValue.buffer, _cborValue.majorType);
        if (itemLength < UINT64_MAX) {
          textData = abi.encodePacked(textData, readText(_cborValue.buffer, itemLength / 4));
        } else {
          done = true;
        }
      }
      return string(textData);
    } else {
      return string(readText(_cborValue.buffer, _cborValue.len));
    }
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `string[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `string[]` value.
   */
  function decodeStringArray(Value memory _cborValue) public pure returns(string[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `string[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    string[] memory array = new string[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeString(item);
    }

    return array;
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `uint64` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `uint64` value.
   */
  function decodeUint64(Value memory _cborValue) public pure returns(uint64) {
    require(_cborValue.majorType == 0, "Tried to read `uint64` from a `CBOR.Value` with majorType != 0");
    return readLength(_cborValue.buffer, _cborValue.additionalInformation);
  }

  /**
   * @notice Decode a `CBOR.Value` structure into a native `uint64[]` value.
   * @param _cborValue An instance of `CBOR.Value`.
   * @return The value represented by the input, as an `uint64[]` value.
   */
  function decodeUint64Array(Value memory _cborValue) public pure returns(uint64[] memory) {
    require(_cborValue.majorType == 4, "Tried to read `uint64[]` from a `CBOR.Value` with majorType != 4");

    uint64 length = readLength(_cborValue.buffer, _cborValue.additionalInformation);
    require(length < UINT64_MAX, "Indefinite-length CBOR arrays are not supported");

    uint64[] memory array = new uint64[](length);
    for (uint64 i = 0; i < length; i++) {
      Value memory item = valueFromBuffer(_cborValue.buffer);
      array[i] = decodeUint64(item);
    }

    return array;
  }

  /**
   * @notice Decode a CBOR.Value structure from raw bytes.
   * @dev This is the main factory for CBOR.Value instances, which can be later decoded into native EVM types.
   * @param _cborBytes Raw bytes representing a CBOR-encoded value.
   * @return A `CBOR.Value` instance containing a partially decoded value.
   */
  function valueFromBytes(bytes memory _cborBytes) public pure returns(Value memory) {
    BufferLib.Buffer memory buffer = BufferLib.Buffer(_cborBytes, 0);

    return valueFromBuffer(buffer);
  }

  /**
   * @notice Decode a CBOR.Value structure from raw bytes.
   * @dev This is an alternate factory for CBOR.Value instances, which can be later decoded into native EVM types.
   * @param _buffer A Buffer structure representing a CBOR-encoded value.
   * @return A `CBOR.Value` instance containing a partially decoded value.
   */
  function valueFromBuffer(BufferLib.Buffer memory _buffer) public pure returns(Value memory) {
    require(_buffer.data.length > 0, "Found empty buffer when parsing CBOR value");

    uint8 initialByte;
    uint8 majorType = 255;
    uint8 additionalInformation;
    uint64 length;
    uint64 tag = UINT64_MAX;

    bool isTagged = true;
    while (isTagged) {
      // Extract basic CBOR properties from input bytes
      initialByte = _buffer.readUint8();
      majorType = initialByte >> 5;
      additionalInformation = initialByte & 0x1f;

      // Early CBOR tag parsing.
      if (majorType == 6) {
        tag = readLength(_buffer, additionalInformation);
      } else {
        isTagged = false;
      }
    }

    require(majorType <= 7, "Invalid CBOR major type");

    return CBOR.Value(
      _buffer,
      initialByte,
      majorType,
      additionalInformation,
      length,
      tag);
  }

  // Reads the length of the next CBOR item from a buffer, consuming a different number of bytes depending on the
  // value of the `additionalInformation` argument.
  function readLength(BufferLib.Buffer memory _buffer, uint8 additionalInformation) private pure returns(uint64) {
    if (additionalInformation < 24) {
      return additionalInformation;
    }
    if (additionalInformation == 24) {
      return _buffer.readUint8();
    }
    if (additionalInformation == 25) {
      return _buffer.readUint16();
    }
    if (additionalInformation == 26) {
      return _buffer.readUint32();
    }
    if (additionalInformation == 27) {
      return _buffer.readUint64();
    }
    if (additionalInformation == 31) {
      return UINT64_MAX;
    }
    revert("Invalid length encoding (non-existent additionalInformation value)");
  }

  // Read the length of a CBOR indifinite-length item (arrays, maps, byte strings and text) from a buffer, consuming
  // as many bytes as specified by the first byte.
  function readIndefiniteStringLength(BufferLib.Buffer memory _buffer, uint8 majorType) private pure returns(uint64) {
    uint8 initialByte = _buffer.readUint8();
    if (initialByte == 0xff) {
      return UINT64_MAX;
    }
    uint64 length = readLength(_buffer, initialByte & 0x1f);
    require(length < UINT64_MAX && (initialByte >> 5) == majorType, "Invalid indefinite length");
    return length;
  }

  // Read a text string of a given length from a buffer. Returns a `bytes memory` value for the sake of genericness,
  // but it can be easily casted into a string with `string(result)`.
  // solium-disable-next-line security/no-assign-params
  function readText(BufferLib.Buffer memory _buffer, uint64 _length) private pure returns(bytes memory) {
    bytes memory result;
    for (uint64 index = 0; index < _length; index++) {
      uint8 value = _buffer.readUint8();
      if (value & 0x80 != 0) {
        if (value < 0xe0) {
          value = (value & 0x1f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 1;
        } else if (value < 0xf0) {
          value = (value & 0x0f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6 |
            (_buffer.readUint8() & 0x3f);
          _length -= 2;
        } else {
          value = (value & 0x0f) << 18 |
            (_buffer.readUint8() & 0x3f) << 12 |
            (_buffer.readUint8() & 0x3f) << 6  |
            (_buffer.readUint8() & 0x3f);
          _length -= 3;
        }
      }
      result = abi.encodePacked(result, value);
    }
    return result;
  }
}
