-include .env

.PHONY: all deploy-sepolia

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy-sepolia - Deploy to Sepolia network"
	@echo "  make deploy-local - Deploy to Anvil local"

# Deploy to Sepolia
deploy-sepolia:
	@forge script script/OgmaAccountDeployment.s.sol:OgmaAccountScript \
	--rpc-url $(SEPOLIA_RPC_URL) \
	--private-key $(PRIVATE_KEY) \
	--broadcast \
	--verify \
	--etherscan-api-key $(ETHERSCAN_API_KEY) \
	-vvvv