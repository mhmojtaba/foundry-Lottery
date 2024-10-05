// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Lottery} from "src/Lottery.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "script/Interactions.s.sol";

contract LotteryDeploy is Script {
    function run() public {
        deployLottery();
    }

    function deployLottery() public returns (Lottery, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.networkConfig memory config = helperConfig.getConfig();

        if (config._subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config._subscriptionId, config._vrfCoordinator) =
                createSubscription.createSubscription(config._vrfCoordinator, config.account);
            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config._vrfCoordinator, config._subscriptionId, config.link, config.account);
        }

        vm.startBroadcast(config.account);

        Lottery lottery = new Lottery(
            config._enteranceFee,
            config._interval,
            config._gasLane,
            config._subscriptionId,
            config._callbackGasLimit,
            config._vrfCoordinator
        );

        vm.stopBroadcast();
        AddConsumer addConsumer = new AddConsumer();
        addConsumer.addConsumer(address(lottery), config._vrfCoordinator, config._subscriptionId, config.account);

        return (lottery, helperConfig);
    }
}
