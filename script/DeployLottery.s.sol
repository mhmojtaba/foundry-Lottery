// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription} from "script/Interactions.s.sol";

contract LotteryDeploy is Script {
    function run() public {}

    function deployLottery() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();

        if (config._subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config._subscriptionId, config._vrfCoordinator) =
                createSubscription.createSubscription(config._vrfCoordinator);
        }

        vm.startBroadcast();

        Lottery lottery = new Lottery(
            config._enteranceFee,
            config._interval,
            config._gasLane,
            config._subscriptionId,
            config._callbackGasLimit,
            config._vrfCoordinator
        );

        vm.stopBroadcast();

        return (lottery, helperConfig);
    }
}
