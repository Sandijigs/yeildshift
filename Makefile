# YieldShift Makefile
# Common commands for development

.PHONY: all build test clean install deploy frontend

# Default target
all: install build test

# Install dependencies
install:
	@echo "Installing Foundry dependencies..."
	forge install
	@echo "Installing frontend dependencies..."
	cd frontend && npm install

# Build contracts
build:
	@echo "Building contracts..."
	forge build

# Run tests
test:
	@echo "Running tests..."
	forge test -vvv

# Run tests with gas report
test-gas:
	@echo "Running tests with gas report..."
	forge test --gas-report

# Run coverage
coverage:
	@echo "Running coverage..."
	forge coverage

# Clean build artifacts
clean:
	@echo "Cleaning..."
	forge clean
	rm -rf out cache

# Format code
fmt:
	@echo "Formatting..."
	forge fmt

# Lint code
lint:
	@echo "Linting..."
	forge fmt --check

# Deploy to local anvil
deploy-local:
	@echo "Deploying to local Anvil..."
	forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# Deploy to Base Sepolia
deploy-base-sepolia:
	@echo "Deploying to Base Sepolia..."
	forge script script/DeployBase.s.sol:DeployBase \
		--rpc-url $${BASE_SEPOLIA_RPC_URL} \
		--broadcast \
		--verify \
		-vvvv

# Setup pool on Base Sepolia
setup-pool:
	@echo "Setting up pool..."
	forge script script/SetupPool.s.sol:SetupPool \
		--rpc-url $${BASE_SEPOLIA_RPC_URL} \
		--broadcast

# Start local node
anvil:
	@echo "Starting Anvil..."
	anvil

# Frontend development
frontend:
	@echo "Starting frontend..."
	cd frontend && npm start

# Frontend build
frontend-build:
	@echo "Building frontend..."
	cd frontend && npm run build

# Generate documentation
docs:
	@echo "Generating docs..."
	forge doc

# Snapshot gas usage
snapshot:
	@echo "Creating gas snapshot..."
	forge snapshot

# Help
help:
	@echo "YieldShift Makefile Commands:"
	@echo "  make install       - Install all dependencies"
	@echo "  make build         - Build contracts"
	@echo "  make test          - Run tests"
	@echo "  make test-gas      - Run tests with gas report"
	@echo "  make coverage      - Run coverage"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make fmt           - Format code"
	@echo "  make deploy-local  - Deploy to local Anvil"
	@echo "  make deploy-base-sepolia - Deploy to Base Sepolia"
	@echo "  make frontend      - Start frontend dev server"
	@echo "  make frontend-build - Build frontend for production"
	@echo "  make anvil         - Start local Anvil node"
	@echo "  make help          - Show this help"
