// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

error Lottery__NotEnoughETH();
error Lottery__intervalNotExceed();

/// @title Lottory smart contract
/// @author Mojtaba Mohammadi
/// @notice a raffle smart contract to make a randome number as winner
/// @dev Implement chainlink VRF and automated smart contracts

contract Lottery is VRFConsumerBaseV2Plus {
    uint256 private immutable i_enteranceFee;
    uint256 private immutable i_interval; // @dev duration of the lottery in seconds
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address payable private s_owner;
    address private s_winner;

    // variables to use in VRF chainlink functions
    uint16 private constant REQUEST_CONFIRMATION = 3;
    // request confirmation needed from the network
    uint32 private constant NUM_WORDS = 1; // number of random numbers we want
    bytes32 private immutable i_keyHash; // gas price
    uint32 private immutable i_callbackGasLimit; // gas limit
    uint256 private immutable i_subscriptionId; // subscriptionId

    mapping(address => uint256) s_playerValues;

    /* Events */
    event EnterLottery(address _sender, uint256 _value, uint256 _enterTime);

    constructor(
        uint256 _enteranceFee,
        uint256 _interval,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        i_enteranceFee = _enteranceFee;
        i_interval = _interval;
        s_lastTimeStamp = block.timestamp;
        s_owner = payable(msg.sender);
        i_keyHash = _gasLane;
        i_subscriptionId = _subscriptionId;
        i_callbackGasLimit = _callbackGasLimit;
    }

    function enter() external payable {
        // require to pay enterancefee
        // require(msg.value >= i_enteranceFee, NotEnoughETH());
        if (msg.value < i_enteranceFee) {
            revert Lottery__NotEnoughETH();
        }
        s_players.push(payable(msg.sender));
        s_playerValues[msg.sender] = msg.value;

        emit EnterLottery(msg.sender, msg.value, block.timestamp);
    }

    function winner() external {
        if (block.timestamp - s_lastTimeStamp <= i_interval) {
            revert Lottery__intervalNotExceed();
        }
        // getting random number from chainlink vrf
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {}

    // getter functions
    function getEnteranceFee() external view returns (uint256) {
        return i_enteranceFee;
    }
}
