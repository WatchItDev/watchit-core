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

.PHONY: clean ## clean installation and dist files
clean:
	@rm -rf cache
	@rm -rf artifacts
	@rm -rf node_modules
	@rm -rf cache_forge
	@forge clean

.PHONY: forge-clean ## clean forge
forge-clean:
	rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

.PHONY: compile ## compile contracts
compile:
	@forge build

.PHONY: force-compile ## compile contracts
force-compile:
	@forge clean && forge build

# https://jestjs.io/docs/cli#--coverageboolean
.PHONY: test ## run tests
test:
	@forge test --via-ir --gas-report --show-progress -vvv --force

.PHONY: coverage ## run tests coverage report
coverage:
	mkdir -p coverage
	forge coverage --report lcov --no-match-path "test/foundry/invariants/*"
	lcov --remove lcov.info -o coverage/lcov.info 'test/*' 'script/*' --rc lcov_branch_coverage=1
	genhtml coverage/lcov.info -o coverage --rc lcov_branch_coverage=1



.PHONY: secreport ## generate a security analysis report using aderyn
secreport:
	@aderyn

.PHONY: sectest ## run secutiry tests using slither
sectest:
	@export PATH=$HOME/.local/bin:$PATH	
	@slither . 

.PHONY: format ## auto-format solidity source files
format:
	@npx prettier --write contracts

.PHONY: hint ## lint standard  solidity
lint: 
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