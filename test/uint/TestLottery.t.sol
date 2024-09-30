// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {LotteryDeploy} from "script/DeployLottery.s.sol";

contract LotteryTest is Test {
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

    function testEnterLotteryByPlayerWhileLotteryIsNotOpen() public {
        // arrange
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();

        vm.warp(block.timestamp + _interval + 10); // cheating => changing the time stamp to the time we needed
        vm.roll(block.number + 1);

        lottery.performUpkeep("");

        vm.expectRevert(Lottery.Lottery__NotOpen.selector);
        vm.prank(player);
        lottery.enter{value: _enteranceFee}();
    }
}
