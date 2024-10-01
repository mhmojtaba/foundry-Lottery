-include .env

build:; forge build

format:; forge fmt

sepoliabuild:; forge script script/Interactions.s.sol:FundSubscription --rpc-url $SEPOLIA_RPC_URL --account myaccount --broadcast

test:; forge test