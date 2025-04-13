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

# Create a new OgmaAccountPassKey using the factory
create-account:
	@echo "Creating new OgmaAccountPassKey account..."
	@cast send \
		--rpc-url $(SEPOLIA_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		$(FACTORY_ADDRESS) \
		"createAccount(address,bytes)(address)" \
		"0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789" \
		"0x70617373776f7264"

# Check owner of a deployed OgmaAccountPassKey account
check-owner:
	@echo "Checking owner of OgmaAccountPassKey account..."
	@cast call \
		--rpc-url $(SEPOLIA_RPC_URL) \
		"0x4251646071128F48BF24cB34a9AdE64c790C1F5a" \
		"owner()(address)"