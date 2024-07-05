# Include env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.DEFAULT_GOAL := all
stage=development
region=us-west-2
function=graphql

.PHONY: bootstrap ## setup initial development environment
bootstrap: install
	@npx husky install
	@npx husky add .husky/commit-msg 'npx --no-install commitlint --edit "$1"'

# https://jestjs.io/docs/cli#--coverageboolean
.PHONY: test ## run tests
test:
	@npx hardhat test

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

.PHONY: install ## install dependencies
install: 
	@npm ci

.PHONY: format ## auto-format js source files
format:
	@npx standard --fix

.PHONY: lint ## lint standard js
lint: 
	@npx standard

.PHONY: solformat ## auto-format solidity source files
solformat:
	@npx solhint 'contracts/**/*.sol' --fix

.PHONY: lints ## lint standard js
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
	@npx harhat deploy

rebuild: clean
all: test lint

.PHONY: help  ## display this message
help:
	@grep -E \
		'^.PHONY: .*?## .*$$' $(MAKEFILE_LIST) | \
		sort | \
		awk 'BEGIN {FS = ".PHONY: |## "}; {printf "\033[36m%-19s\033[0m %s\n", $$2, $$3}'