-include .env

.PHONY: all test deploy

build:; forge build

test:; forge test

install:; forge install cyfrin/foundry-devops@0.2.2 --no-commit && forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 --no-commit && forge install foundry-rs/forge-std@v1.8.2 --no-commit && forge install transmissions11/solmate@v6 --no-commit

format:; forge fmt

sepolia-fudsubscription-build:
	@forge script script/Interactions.s.sol:FudSubscription --rpc-url $SEPOLIA_RPC_URL --account myaccount --broadcast

sepolia-deploy:
	@forge script script/DeployLottery.s.sol:LotteryDeploy --rpc-url $(SEPOLIA_RPC_URL) --account myaccount --broadcast --verify --etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

test:; forge test

coverage:; forge coverage --report debug>coverage.txt