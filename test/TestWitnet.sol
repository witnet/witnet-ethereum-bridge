// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "truffle/Assert.sol";
import "../contracts/libs/Witnet.sol";


contract WitnetTest {
  using Witnet for WitnetTypes.Result;

  // Test the `Witnet.stageNames` pure method, which gives strings with the names for the different Witnet request
  // stages
  function testStageNames() external {
    Assert.equal(Witnet.stageName(0), "retrieval", "Stage name for stage #1 should be \"retrieval\"");
    Assert.equal(Witnet.stageName(1), "aggregation", "Stage name for stage #1 should be \"aggregation\"");
    Assert.equal(Witnet.stageName(2), "tally", "Stage name for stage #1 should be \"tally\"");
    
  }

  // Test decoding of `RadonError` error codes
  function testErrorCodes1() external {
    WitnetTypes.ErrorCodes errorCodeEmpty = Witnet.resultFromCborBytes(hex"D82780").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x00 = Witnet.resultFromCborBytes(hex"D8278100").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x01 = Witnet.resultFromCborBytes(hex"D8278101").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x02 = Witnet.resultFromCborBytes(hex"D8278102").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x03 = Witnet.resultFromCborBytes(hex"D8278103").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x10 = Witnet.resultFromCborBytes(hex"D8278110").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x11 = Witnet.resultFromCborBytes(hex"D8278111").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x20 = Witnet.resultFromCborBytes(hex"D827811820").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x30 = Witnet.resultFromCborBytes(hex"D827811830").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x31 = Witnet.resultFromCborBytes(hex"D827811831").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x40 = Witnet.resultFromCborBytes(hex"D827811840").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x41 = Witnet.resultFromCborBytes(hex"D827811841").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x42 = Witnet.resultFromCborBytes(hex"D827811842").asErrorCode();
    Assert.equal(
      uint(errorCodeEmpty),
      uint(WitnetTypes.ErrorCodes.Unknown),
      "empty error code `[]` should be `WitnetTypes.ErrorCodes.Unknown`"
    );
    Assert.equal(
      uint(errorCode0x00),
      uint(WitnetTypes.ErrorCodes.Unknown),
      "error code `0x00` should be `WitnetTypes.ErrorCodes.Unknown`"
    );
    Assert.equal(
      uint(errorCode0x01),
      uint(WitnetTypes.ErrorCodes.SourceScriptNotCBOR),
      "error code `0x01` should be `WitnetTypes.ErrorCodes.SourceScriptNotCBOR`"
    );
    Assert.equal(
      uint(errorCode0x02),
      uint(WitnetTypes.ErrorCodes.SourceScriptNotArray),
      "error code `0x02` should be `WitnetTypes.ErrorCodes.SourceScriptNotArray`"
    );
    Assert.equal(
      uint(errorCode0x03),
      uint(WitnetTypes.ErrorCodes.SourceScriptNotRADON),
      "error code `0x03` should be `WitnetTypes.ErrorCodes.SourceScriptNotRADON`"
    );
    Assert.equal(
      uint(errorCode0x10),
      uint(WitnetTypes.ErrorCodes.RequestTooManySources),
      "error code `0x10` should be `WitnetTypes.ErrorCodes.RequestTooManySources`"
    );
    Assert.equal(
      uint(errorCode0x11),
      uint(WitnetTypes.ErrorCodes.ScriptTooManyCalls),
      "error code `0x11` should be `WitnetTypes.ErrorCodes.ScriptTooManyCalls`"
    );
    Assert.equal(
      uint(errorCode0x20),
      uint(WitnetTypes.ErrorCodes.UnsupportedOperator),
      "error code `0x20` should be `WitnetTypes.ErrorCodes.UnsupportedOperator`"
    );
    Assert.equal(
      uint(errorCode0x30),
      uint(WitnetTypes.ErrorCodes.HTTP),
      "error code `0x30` should be `WitnetTypes.ErrorCodes.HTTP`"
    );
    Assert.equal(
      uint(errorCode0x31),
      uint(WitnetTypes.ErrorCodes.RetrievalTimeout),
      "Error code 0x31 should be `WitnetTypes.ErrorCodes.RetrievalTimeout`"
    );
    Assert.equal(
      uint(errorCode0x40),
      uint(WitnetTypes.ErrorCodes.Underflow),
      "error code `0x40` should be `WitnetTypes.ErrorCodes.Underflow`"
    );
    Assert.equal(
      uint(errorCode0x41),
      uint(WitnetTypes.ErrorCodes.Overflow),
      "error code `0x41` should be `WitnetTypes.ErrorCodes.Overflow`"
    );
    Assert.equal(
      uint(errorCode0x42),
      uint(WitnetTypes.ErrorCodes.DivisionByZero),
      "Error code #0x42 should be `WitnetTypes.ErrorCodes.DivisionByZero`"
    );
  }

  function testErrorCodes2() external {
    WitnetTypes.ErrorCodes errorCode0x50 = Witnet.resultFromCborBytes(hex"D827811850").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x51 = Witnet.resultFromCborBytes(hex"D827811851").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x52 = Witnet.resultFromCborBytes(hex"D827811852").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x53 = Witnet.resultFromCborBytes(hex"D827811853").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x60 = Witnet.resultFromCborBytes(hex"D827811860").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x70 = Witnet.resultFromCborBytes(hex"D827811870").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0x71 = Witnet.resultFromCborBytes(hex"D827811871").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0xE0 = Witnet.resultFromCborBytes(hex"D8278118E0").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0xE1 = Witnet.resultFromCborBytes(hex"D8278118E1").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0xE2 = Witnet.resultFromCborBytes(hex"D8278118E2").asErrorCode();
    WitnetTypes.ErrorCodes errorCode0xFF = Witnet.resultFromCborBytes(hex"D8278118FF").asErrorCode();
    Assert.equal(
      uint(errorCode0x50),
      uint(WitnetTypes.ErrorCodes.NoReveals),
      "Error code #0x50 should be `WitnetTypes.ErrorCodes.NoReveals`"
    );
    Assert.equal(
      uint(errorCode0x51),
      uint(WitnetTypes.ErrorCodes.InsufficientConsensus),
      "Error code #0x51 should be `WitnetTypes.ErrorCodes.InsufficientConsensus`"
    );
    Assert.equal(
      uint(errorCode0x52),
      uint(WitnetTypes.ErrorCodes.InsufficientCommits),
      "Error code #0x52 should be `WitnetTypes.ErrorCodes.InsufficientCommits`"
    );
    Assert.equal(
      uint(errorCode0x53),
      uint(WitnetTypes.ErrorCodes.TallyExecution),
      "Error code #0x53 should be `WitnetTypes.ErrorCodes.TallyExecution`"
    );
    Assert.equal(
      uint(errorCode0x60),
      uint(WitnetTypes.ErrorCodes.MalformedReveal),
      "Error code #0x60 should be `WitnetTypes.ErrorCodes.MalformedReveal`"
    );
    Assert.equal(
      uint(errorCode0x70),
      uint(WitnetTypes.ErrorCodes.ArrayIndexOutOfBounds),
      "Error code #0x70 should be `WitnetTypes.ErrorCodes.ArrayIndexOutOfBounds`"
    );
    Assert.equal(
      uint(errorCode0x71),
      uint(WitnetTypes.ErrorCodes.MapKeyNotFound),
      "Error code #0x71 should be `WitnetTypes.ErrorCodes.MapKeyNotFound`"
    );
    Assert.equal(
      uint(errorCode0xE0),
      uint(WitnetTypes.ErrorCodes.BridgeMalformedRequest),
      "Error code #0xE0 should be `WitnetTypes.ErrorCodes.BridgeMalformedRequest`"
    );
    Assert.equal(
      uint(errorCode0xE1),
      uint(WitnetTypes.ErrorCodes.BridgePoorIncentives),
      "Error code #0xE1 should be `WitnetTypes.ErrorCodes.BridgePoorIncentives`"
    );
    Assert.equal(
      uint(errorCode0xE2),
      uint(WitnetTypes.ErrorCodes.BridgeOversizedResult),
      "Error code #0xE2 should be `WitnetTypes.ErrorCodes.BridgeOversizedResult`"
    );
    Assert.equal(
      uint(errorCode0xFF),
      uint(WitnetTypes.ErrorCodes.UnhandledIntercept),
      "Error code #0xFF should be `WitnetTypes.ErrorCodes.UnhandledIntercept`"
    );
  }

  // Test decoding of `RadonError` error messages
  function testErrorMessages() external {
    (, string memory errorMessageEmpty) = Witnet.resultFromCborBytes(hex"D82780").asErrorMessage();
    (, string memory errorMessage0x00) = Witnet.resultFromCborBytes(hex"D8278100").asErrorMessage();
    (, string memory errorMessage0x01) = Witnet.resultFromCborBytes(hex"D827820102").asErrorMessage();
    (, string memory errorMessage0x02) = Witnet.resultFromCborBytes(hex"D827820203").asErrorMessage();
    (, string memory errorMessage0x03) = Witnet.resultFromCborBytes(hex"D827820304").asErrorMessage();
    (, string memory errorMessage0x10) = Witnet.resultFromCborBytes(hex"D827821005").asErrorMessage();
    (, string memory errorMessage0x11) = Witnet.resultFromCborBytes(hex"D8278411000708").asErrorMessage();
    (, string memory errorMessage0x20) = Witnet.resultFromCborBytes(hex"D8278518200108090A").asErrorMessage();
    (, string memory errorMessage0x30) = Witnet.resultFromCborBytes(hex"D82783183008190141").asErrorMessage();
    (, string memory errorMessage0x31) = Witnet.resultFromCborBytes(hex"D82782183109").asErrorMessage();
    (, string memory errorMessage0x40) = Witnet.resultFromCborBytes(hex"D82785184002090A0B").asErrorMessage();
    (, string memory errorMessage0x41) = Witnet.resultFromCborBytes(hex"D827851841000A0B0C").asErrorMessage();
    (, string memory errorMessage0x42) = Witnet.resultFromCborBytes(hex"D827851842010B0C0D").asErrorMessage();
    (, string memory errorMessage0xFF) = Witnet.resultFromCborBytes(hex"D8278118FF").asErrorMessage();
    Assert.equal(
      errorMessageEmpty,
      "Unknown error (no error code)",
      "Empty error message `[]` should be properly formatted"
    );
    Assert.equal(
      errorMessage0x00,
      "Unknown error (0x00)",
      "Error message 0x00 should be properly formatted"
    );
    Assert.equal(
      errorMessage0x01,
      "Source script #2 was not a valid CBOR value",
      "Error message for error code `0x01` (`WitnetTypes.ErrorCodes.SourceScriptNotCBOR`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x02,
      "The CBOR value in script #3 was not an Array of calls",
      "Error message for error code `0x02` (`WitnetTypes.ErrorCodes.SourceScriptNotArray`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x03,
      "The CBOR value in script #4 was not a valid RADON script",
      "Error message for error code `0x03` (`WitnetTypes.ErrorCodes.SourceScriptNotRADON`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x10,
      "The request contained too many sources (5)",
      "Error message for error code `0x10` (`WitnetTypes.ErrorCodes.RequestTooManySources`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x11,
      "Script #7 from the retrieval stage contained too many calls (8)",
      "Error message for error code `0x11` (`WitnetTypes.ErrorCodes.ScriptTooManyCalls`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x20,
      "Operator code 0x0A found at call #9 in script #8 from aggregation stage is not supported",
      "Error message for error code `0x20` (`WitnetTypes.ErrorCodes.UnsupportedOperator`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x30,
      "Source #8 could not be retrieved. Failed with HTTP error code: 321",
      "Error message for error code `0x30` (`WitnetTypes.ErrorCodes.HTTP`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x31,
      "Source #9 could not be retrieved because of a timeout",
      "Error message for error code `0x31` (`WitnetTypes.ErrorCodes.HTTP`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x40,
      "Underflow at operator code 0x0B found at call #10 in script #9 from tally stage",
      "Error message for error code `0x40` (`WitnetTypes.ErrorCodes.Underflow`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x41,
      "Overflow at operator code 0x0C found at call #11 in script #10 from retrieval stage",
      "Error message for error code `0x41` (`WitnetTypes.ErrorCodes.Overflow`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0x42,
      "Division by zero at operator code 0x0D found at call #12 in script #11 from aggregation stage",
      "Error message for error code `0x42` (`WitnetTypes.ErrorCodes.DivisionByZero`) should be properly formatted"
    );
    Assert.equal(
      errorMessage0xFF,
      "Unknown error (0xFF)",
      "Error message for an unknown error should be properly formatted"
    );
  }

  function testBridgeErrorMessages() external { 
    (, string memory errorMessage0xE0) = Witnet.resultFromCborBytes(hex"D8278118E0").asErrorMessage();
    (, string memory errorMessage0xE1) = Witnet.resultFromCborBytes(hex"D8278118E1").asErrorMessage();
    (, string memory errorMessage0xE2) = Witnet.resultFromCborBytes(hex"D8278118E2").asErrorMessage();  

    Assert.equal(
      errorMessage0xE0,
      "The structure of the request is invalid and it cannot be parsed",
      "Error message failed (0xE0)"
    );
    Assert.equal(
      errorMessage0xE1,
      "The request has been rejected by the bridge node due to poor incentives",
      "Error message failed (0xE1)"
    );
    Assert.equal(
      errorMessage0xE2,
      "The request result length exceeds a bridge contract defined limit",
      "Error message failed (0xE2)"
    );
  }

}
