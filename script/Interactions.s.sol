// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function createSubscriptionUsingconfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinator ,account);

        return (subId, vrfCoordinator);
    }

    function createSubscription(address vrfCoordinator , address account) public returns (uint256, address) {
        console.log("creating subId");

        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("subId is : ", subId);
        console.log("update the helperconfig.s.sol!!!");

        return (subId, vrfCoordinator);
    }

    function run() public {
        createSubscriptionUsingconfig();
    }
}

contract FundSubscription is Script, CodeConstants {
    uint256 public constant AMOUNT = 5 ether;

    function fundSubscriptionConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        uint256 subscriptionId = helperConfig.getConfig()._subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        fundSubscription(vrfCoordinator, subscriptionId, linkToken, account);
    }

    function fundSubscription
    (
        address vrfCoordinator, 
        uint256 subscriptionId, 
        address linkToken, 
        address account
    ) public {
        console.log("funding subscriptionId ", subscriptionId);
        console.log("with vrfCoordinator", vrfCoordinator);
        console.log("on chain :", block.chainid);

        if (block.chainid == ANVIL_CHAINID) {
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(
                subscriptionId, AMOUNT * 1000 /* for Mock testing */
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinator, AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        fundSubscriptionConfig();
    }
}

contract AddConsumer is Script {
    function addConsumerConfig(address contractDeployed) public {
        HelperConfig helperConfig = new HelperConfig();
        uint256 subscriptionId = helperConfig.getConfig()._subscriptionId;
        address vrfCoordinator = helperConfig.getConfig()._vrfCoordinator;
        address account = helperConfig.getConfig().account;
        addConsumer(contractDeployed, vrfCoordinator, subscriptionId, account);
    }

    function addConsumer
    (
        address contractToVrf, 
        address vrfCoordinator, 
        uint256 subscriptionId,
        address account
    ) public {
        console.log("adding consumer  ", contractToVrf);
        console.log("to vrfCoordinator", vrfCoordinator);
        console.log("with subscriptionId", subscriptionId);
        console.log("on chain :", block.chainid);

        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subscriptionId, contractToVrf);
        vm.stopBroadcast();       

    }

    function run() external {
        address lotteryDeployed = DevOpsTools.get_most_recent_deployment("Lottery", block.chainid);
        addConsumerConfig(lotteryDeployed);
    }
}
