// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";


abstract contract CodeConstants{
    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ANVIL_CHAINID = 31337;

}

contract HelperConfig is Script , CodeConstants{

    error HelperConfig__InvalidChainId(uint256 chainid);

    // making a struct of the configuration needed
    struct networkConfig{
        uint256 _enteranceFee;
        uint256 _interval;
        bytes32 _gasLane;
        uint256 _subscriptionId;
        uint32 _callbackGasLimit;
        address _vrfCoordinator;
    }

    networkConfig public localNetworkConfig;
    mapping (uint256 chainId => networkConfig) public networkConfigs;

    constructor(){
        networkConfigs[SEPOLIA_CHAIN_ID] = getSepoliaConfig();
    }

    function getConfigByChainID(uint256 chainID)public returns(networkConfig memory){
        if (networkConfigs[chainID]._vrfCoordinator != address(0)) {
            return networkConfigs[chainID];
        } else if(chainID == ANVIL_CHAINID) {
            //getorCreateAnvilConfig();
        } else {
            revert HelperConfig__InvalidChainId(chainID);
        }
    }

    function getorCreateAnvilConfig()public pure returns(networkConfig memory) {
        if (localNetworkConfig._vrfCoordinator != address(0)) {
            return localNetworkConfig;
        } else {

        }
        // return networkConfig(
        //     0.01 ether,// enterancefee is 0.01 ether
        //     1 minutes,// interval is every 1 minutes
        //     0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane or keyhash
        //     0, // the subscriptionId
        //     100000 , // the gasLimit
        //     0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B // vrf coordinator address
        // );
    }


    function getSepoliaConfig() public pure returns(networkConfig memory) {
        return networkConfig(
            0.01 ether,// enterancefee is 0.01 ether
            1 minutes,// interval is every 1 minutes
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane or keyhash
            0, // the subscriptionId
            100000 , // the gasLimit
            0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B // vrf coordinator address
        );
    }
}