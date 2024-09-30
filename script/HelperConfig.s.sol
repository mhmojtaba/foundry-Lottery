// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";

abstract contract CodeConstants {
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAINID = 31337;

    /*VRF MOCK Variables */
    uint96 public MOCK_baseFee = 0.2 ether;
    uint96 public MOCK_gasPrice = 1e9;
    int256 public MOCK_weiPerUnitLink = 4e15;

}

contract HelperConfig is CodeConstants, Script {

    error HelperConfig__InvalidChainId(uint256 chainid);

    // making a struct of the configuration needed
    struct networkConfig {
        uint256 _enteranceFee;
        uint256 _interval;
        bytes32 _gasLane;
        uint256 _subscriptionId;
        uint32 _callbackGasLimit;
        address _vrfCoordinator;
        address link;
    }

    networkConfig public localNetworkConfig;
    mapping(uint256 chainId => networkConfig) public networkConfigs;

    constructor() {
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfigByChainID(uint256 chainID) public returns (networkConfig memory) {
        if (networkConfigs[chainID]._vrfCoordinator != address(0)) {
            return networkConfigs[chainID];
        } else if (chainID == ANVIL_CHAINID) {
            return getorCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId(chainID);
        }
    }

    function getConfig() public returns (networkConfig memory) {
        return getConfigByChainID(block.chainid);
    }

    function getorCreateAnvilConfig() public returns (networkConfig memory) {
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        }

        // deploy VRFCoordinatorV2_5Mock
        vm.startBroadcast();
        VRFCoordinatorV2_5Mock vrfCoordinatorV2_5Mock =
            new VRFCoordinatorV2_5Mock(MOCK_baseFee, MOCK_gasPrice, MOCK_weiPerUnitLink);
        LinkToken linkToken = new LinkToken();
        vm.stopBroadcast();

        localNetworkConfig = networkConfig(
            0.01 ether, // enterancefee is 0.01 ether
            1 minutes, // interval is every 1 minutes
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane or keyhash
            0, // the subscriptionId
            100000, // the gasLimit
            address(vrfCoordinatorV2_5Mock), // vrf coordinator address
            address(linkToken)
        );
        return localNetworkConfig;
    }

    function getSepoliaConfig() public pure returns (networkConfig memory) {
        return networkConfig(
            0.01 ether, // enterancefee is 0.01 ether
            1 minutes, // interval is every 1 minutes
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane or keyhash
            18158373438440650950665589907136733397195481284246089286377304796610796020611, // the subscriptionId
            100000, // the gasLimit
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B, // vrf coordinator address
            0x779877A7B0D9E8603169DdbD7836e478b4624789
        );
    }
}
