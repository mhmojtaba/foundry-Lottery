// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

/// @title Lottory smart contract
/// @author Mojtaba Mohammadi
/// @notice a raffle smart contract to make a randome number as winner
/// @dev Implement chainlink VRF and automated smart contracts

contract Lottery is VRFConsumerBaseV2Plus {
    error Lottery__NotEnoughETH();
    error Lottery__intervalNotExceed();
    error Lottery__TransferFailed();
    error Lottery__NotOpen();
    error Lottery__UpkeepNotValid(uint256 balance, uint256 players, uint256 status);
    /*type declarations*/

    enum LotteryStatus {
        Open,
        calculating
    }

    /* state variables */
    uint256 private immutable I_ENTERANCEFEE;
    uint256 private immutable I_INTERVAL; // @dev duration of the lottery in seconds
    uint256 private s_lastTimeStamp;
    address payable[] private s_players;
    address payable private s_owner;
    address private s_winner;
    LotteryStatus private s_LotteryStatus;

    // variables to use in VRF chainlink functions
    uint16 private constant REQUEST_CONFIRMATION = 3;
    // request confirmation needed from the network
    uint32 private constant NUM_WORDS = 1; // number of random numbers we want
    bytes32 private immutable I_KEYHASH; // gas price
    uint32 private immutable I_CALLBACKGASLIMIT; // gas limit
    uint256 private immutable I_SUBSCRIPTIONID; // subscriptionId

    mapping(address => uint256) public s_playerValues;

    /* Events */
    event EnterLottery(address indexed _sender, uint256 _value, uint256 _enterTime);
    event winnerPicked(address indexed winner);

    constructor(
        uint256 _enteranceFee,
        uint256 _interval,
        bytes32 _gasLane,
        uint256 _subscriptionId,
        uint32 _callbackGasLimit,
        address _vrfCoordinator /*0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B */
    ) VRFConsumerBaseV2Plus(_vrfCoordinator) {
        I_ENTERANCEFEE = _enteranceFee;
        I_INTERVAL = _interval;
        s_lastTimeStamp = block.timestamp;
        s_owner = payable(msg.sender);
        s_LotteryStatus = LotteryStatus.Open;
        I_KEYHASH = _gasLane;
        I_SUBSCRIPTIONID = _subscriptionId;
        I_CALLBACKGASLIMIT = _callbackGasLimit;
    }

    function enter() external payable {
        // require to pay enterancefee
        // require(msg.value >= i_enteranceFee, NotEnoughETH());
        if (msg.value < I_ENTERANCEFEE) {
            revert Lottery__NotEnoughETH();
        }
        if (s_LotteryStatus != LotteryStatus.Open) {
            revert Lottery__NotOpen();
        }
        s_players.push(payable(msg.sender));
        s_playerValues[msg.sender] = msg.value;

        emit EnterLottery(msg.sender, msg.value, block.timestamp);
    }

    // check if it's time to run
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        returns (bool upkeepNeeded, bytes memory /* performeData */ )
    {
        // check if lottery is open
        // check if time has passed
        // check if the contract has ETH
        // check if the lottery has player
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) > I_INTERVAL;
        bool islotteryOpen = s_LotteryStatus == LotteryStatus.Open;
        bool hasETH = address(this).balance > 0;
        bool hasPlayer = s_players.length > 0;
        upkeepNeeded = timeHasPassed && islotteryOpen && hasETH && hasPlayer;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */ ) external {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotValid(address(this).balance, s_players.length, uint256(s_LotteryStatus));
        }
        pickWinner();
    }

    function pickWinner() internal {
        if (block.timestamp - s_lastTimeStamp <= I_INTERVAL) {
            revert Lottery__intervalNotExceed();
        }
        s_LotteryStatus = LotteryStatus.calculating;
        // getting random number from chainlink vrf
        // uint256 requestId =
        s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: I_KEYHASH,
                subId: I_SUBSCRIPTIONID,
                requestConfirmations: REQUEST_CONFIRMATION,
                callbackGasLimit: I_CALLBACKGASLIMIT,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: false}))
            })
        );
        // fulfillRandomWords(requestId, randomWords);
    }

    function fulfillRandomWords(uint256, /*requestId*/ uint256[] calldata randomWords) internal override {
        uint256 totalPlayers = s_players.length;
        uint256 indexOfwinner = randomWords[0] % totalPlayers; // getting the index of winner by dividing the random number to total players
        address payable _winner = s_players[indexOfwinner];
        s_winner = _winner;
        s_LotteryStatus = LotteryStatus.Open;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp;
        (bool success,) = payable(s_winner).call{value: address(this).balance}("");
        if (!success) {
            revert Lottery__TransferFailed();
        }
        emit winnerPicked(s_winner);
    }

    // getter functions
    function getEnteranceFee() external view returns (uint256) {
        return I_ENTERANCEFEE;
    }

    function getLotteryStatus() public view returns (LotteryStatus) {
        return s_LotteryStatus;
    }

    function getWinner() external view returns (address) {
        return s_winner;
    }

    function getOwner() external view returns (address) {
        return s_owner;
    }

    function getPlayer(uint256 index) public view returns (address) {
        return s_players[index];
    }
}
