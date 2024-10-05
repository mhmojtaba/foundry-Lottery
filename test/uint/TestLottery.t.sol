// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {LotteryDeploy} from "script/DeployLottery.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract LotteryTest is CodeConstants, Test {
    Lottery public lottery;
    HelperConfig public helperConfig;

    /* events*/
    event EnterLottery(address indexed _sender, uint256 _value, uint256 _enterTime);
    event winnerPicked(address indexed winner);

    /* CONFIG VALUES */
    uint256 _enteranceFee;
    uint256 _interval;
    bytes32 _gasLane;
    uint256 _subscriptionId;
    uint32 _callbackGasLimit;
    address _vrfCoordinator;

    // make user
    address public player = makeAddr("user");

    // give user balance
    uint256 public constant PLAYER_BALANCE = 100 ether;

    function setUp() public {
        LotteryDeploy deployer = new LotteryDeploy();
        (lottery, helperConfig) = deployer.deployLottery();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();
        _enteranceFee = config._enteranceFee;
        _interval = config._interval;
        _gasLane = config._gasLane;
        _subscriptionId = config._subscriptionId;
        _callbackGasLimit = config._callbackGasLimit;
        _vrfCoordinator = config._vrfCoordinator;

        vm.deal(player, PLAYER_BALANCE);
    }

    function testLotteryIsOpenState() external view {
        assert(lottery.getLotteryStatus() == Lottery.LotteryStatus.Open);
    }

    /*
            Modifires
    */

    modifier lotteryEntered() {
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();
        vm.warp(block.timestamp + _interval + 10); // cheating => changing the time stamp to the time we needed
        vm.roll(block.number + 1);
        _;
    }

        modifier notLocal(){
        if(block.chainid != ANVIL_CHAINID){
            return;
        }
        _;
    }

    /*///////////////////////////////////////////////////////////
                        test enter
    ////////////////////////////////////////////////////////////*/

    function testEnterLotteryRevertWithNotEnoughAsset() public {
        // arrange
        vm.prank(player);
        // act and assert
        vm.expectRevert(Lottery.Lottery__NotEnoughETH.selector); // custom error with selector
        lottery.enter{value: 0}();
    }

    function testEnterLotteryByPlayer() public {
        // arrange
        // hoax(player, PLAYER_BALANCE);
        vm.prank(player);
        // act
        lottery.enter{value: _enteranceFee}();
        // assert
        assert(lottery.getPlayer(0) == player);
    }

    // test events
    // emit must be done after expectemit
    // in expectemit we can have 4 parameter and that one which is indexed must be true
    // the other parameter is the address of contract  and the emitter which can be void
    function testEnterLotteryEmit() public {
        // arrange
        vm.prank(player);
        // act
        vm.expectEmit(true, false, false, false, address(lottery));
        emit EnterLottery(player, _enteranceFee, block.timestamp);
        // assert
        lottery.enter{value: _enteranceFee}();
    }

    function testEnterLotteryByPlayerWhileLotteryIsNotOpen() public lotteryEntered {
        // arrange
        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__NotOpen.selector);
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();
    }

    /*///////////////////////////////////////////////////////////
                        test checkUpkeep
    ////////////////////////////////////////////////////////////*/

    function testCheckupkeepFalsedIfHasNoBalance() public {
        // arrange
        vm.warp(block.timestamp + _interval + 10);
        vm.roll(block.number + 1);

        // act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckupkeepFalsedIfLotteryIsnotOpen() public lotteryEntered {
        // arrange
        lottery.performUpkeep("");

        // act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckupkeepFalsedIfEnoughTimeHasnotPass() public {
        // arrange
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();

        // act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        // assert
        assert(!upkeepNeeded);
    }

    function testCheckupkeepPassWhenEverythingIsOk() public lotteryEntered {
        // act
        (bool upkeepNeeded,) = lottery.checkUpkeep("");

        // assert
        assert(upkeepNeeded);
    }

    /*///////////////////////////////////////////////////////////
                        perform Upkeep
    ////////////////////////////////////////////////////////////*/

    function testPerformeUpkeepRevertIfCheckUpkeepIsFalse() public {
        // arrange
        uint256 balance = 0;
        uint256 players = 0;
        Lottery.LotteryStatus lStatus = lottery.getLotteryStatus();
        uint256 status = uint256(lStatus);
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();
        balance = _enteranceFee;
        players = 1;
        // act
        // assert
        vm.expectRevert(abi.encodeWithSelector(Lottery.Lottery__UpkeepNotValid.selector, balance, players, status));
        lottery.performUpkeep("");
    }

    function testPerformeUpkeepRunsWell() public lotteryEntered {
        lottery.performUpkeep("");
    }

    function testPerformeUpkeepEventRequestId() public lotteryEntered {
        // act
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requestid = logs[1].topics[1];

        // assert
        Lottery.LotteryStatus lStatus = lottery.getLotteryStatus();
        assert(uint256(requestid) > 0);
        assert(uint256(lStatus) == 1);
    }

    /*///////////////////////////////////////////////////////////
                        fulfillRandomWords
    ////////////////////////////////////////////////////////////*/

    function testFulfillRandomWordsOnlyCallAfterPerformUpkeep(uint256 reqId) public lotteryEntered notLocal{
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(reqId, address(lottery));
    }

    function testFulfillRandomWords() public lotteryEntered notLocal{
        // arrange
        uint256 extraPlayers = 3;
        uint256 startingIndex = 1;
        address expectedWinner = address(1);
        for (uint256 i = startingIndex; i < extraPlayers + startingIndex; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            lottery.enter{value: _enteranceFee}();
        }

        uint256 startingTimestamp = lottery.getLastTimestamp();
        uint256 winnerStatingBallance = expectedWinner.balance;

        // act
        vm.recordLogs();
        lottery.performUpkeep("");
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 requId = logs[1].topics[1];

        VRFCoordinatorV2_5Mock(_vrfCoordinator).fulfillRandomWords(uint256(requId), address(lottery));

        // assert
        address winner = lottery.getWinner();
        uint256 winnerBalance = winner.balance;
        Lottery.LotteryStatus lStatus = lottery.getLotteryStatus();
        uint256 endingTimestamp = lottery.getLastTimestamp();
        uint256 prize = _enteranceFee * (extraPlayers + 1);

        assert(winner == expectedWinner);
        assert(uint256(lStatus) == 0);
        assert(winnerBalance == prize + winnerStatingBallance);
        assert(endingTimestamp > startingTimestamp);
    }
}
