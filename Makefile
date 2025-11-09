-include .env

deploy-anvil:
	forge script script/DeployGovernance.s.sol:DeployGovernance \
		--rpc-url $(ANVIL_RPC_URL) \
		--broadcast \
		--private-key $(ANVIL_PRIVATE_KEY) \
		-vvvv

test-specific:
	forge test --mt $(TEST) -vvvv

deploy-sepolia:
	forge script script/DeployGovernance.s.sol:DeployGovernanceSepolia \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--broadcast 