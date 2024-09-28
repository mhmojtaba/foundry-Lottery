// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract LotteryDeploy is Script {
    Lottery public lottery;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        lottery = new Lottery(1);

        vm.stopBroadcast();
    }
    function deployLottery() public returns (lottery , HelperConfig){

    }
}
