# Include env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.DEFAULT_GOAL := all
network=hardhat

# https://github.com/crytic/slither?tab=readme-ov-file#detectors
# https://book.getfoundry.sh/getting-started/installation
# https://github.com/Cyfrin/aderyn?tab=readme-ov-file
.PHONY: bootstrap ## setup initial development environment
bootstrap: install
	@npx husky install
	@npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'

# https://jestjs.io/docs/cli#--coverageboolean
.PHONY: test ## run tests
test:
	@npx hardhat test --network $(network)

# https://jestjs.io/docs/cli#--coverageboolean
.PHONY: testfy ## run tests
testfy:
	@forge test --via-ir --gas-report -vv

.PHONY: testcov ## run tests coverage report
testcov:
	@npx hardhat coverage

.PHONY: compile ## compile contracts
compile:
	@npx hardhat compile

.PHONY: clean ## clean installation and dist files
clean:
	@rm -rf cache
	@rm -rf artifacts
	@rm -rf node_modules
	@rm -rf cache_forge

.PHONY: install ## install dependencies
install: 
	@npm ci

.PHONY: secreport ## generate a security analysis report using aderyn
secreport:
	@aderyn

.PHONY: sectest ## run secutiry tests using slither
sectest:
	@export PATH=$HOME/.local/bin:$PATH	
	@slither . 

.PHONY: solformat ## auto-format solidity source files
solformat:
	@npx solhint 'contracts/**/*.sol' --fix

.PHONY: solhint ## lint standard  solidity
solhint: 
	@npx solhint 'contracts/**/*.sol'

.PHONE: release ## generate a new release version
release:
	@npx semantic-release

.PHONY: syncenv ## pull environments to dotenv vault
syncenv: 
	@npx dotenv-vault@latest pull $(stage) -y

.PHONY: pushenv ## push environments to dotenv vault
pushenv: 
	@npx dotenv-vault@latest push $(stage) -y

.PHONY: loginenv ## get dotenv vault stage keys
loginenv: 
	@npx dotenv-vault@latest login $(me) -y

.PHONY: keysenv ## get dotenv vault stage keys
keysenv: 
	@npx dotenv-vault@latest keys

.PHONY: amoydeploy ## deploy contract to amoy network
amoydeploy: 
	@npx harhat deploy --network $(network)

rebuild: clean
all: test lint

.PHONY: help  ## display this message
help:
	@grep -E \
		'^.PHONY: .*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ".PHONY: |## "}; {printf "\033[36m%-19s\033[0m %s\n", $$2, $$3}'