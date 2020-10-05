# GNU Makefile as entry point for Ansible-based VarFish installer.

# Use bash as shell for more advanced parameters.
SHELL := bash
# The configuration files that should be created.
CONFIGS := \
	inventories/production/group_vars/all/jannovar.yml \
	inventories/production/group_vars/all/servers.yml \
	inventories/production/group_vars/all/varfish.yml

.PHONY: default
default: show-help

.PHONY:
show-help:
	@echo "USAGE: make <target>"
	@echo ""
	@echo "show-help   -- display this help text"
	@echo "check       -- perform sanity check"
	@echo "deps        -- install installer dependencies with ansible-galaxy"
	@echo "configs     -- copy configuration files if not exists yet"
	@echo ""
	@echo "postgres    -- install PostgreSQL"
	@echo "jannovar    -- install Jannovar REST API"
	@echo "varfish     -- install VarFish server and initialize database"

inventories/production/group_vars/all/%.yml: inventories/production/group_vars/all/%.yml.EXAMPLE
	@if [[ -e $@ ]]; then \
		echo "$@ already exists, not creating"; \
	else \
		echo "$< => $@"; \
		cp $< $@; \
	fi

configs: $(CONFIGS)

.PHONY: check
check:
	@if [[ ! -d .password-store ]]; then \
		echo -e "\nERROR: missing directory .password-store\n"; \
		echo -e "Make sure to properly initialize password store and all password."; \
		echo -e "Refer to the README.md file for details."; \
		exit 1; \
	fi
	@if [[ -n "$$PASSWORD_STORE_DIR" ]]; then \
		echo "\nERROR: env PASSWORD_STORE_DIR not set\n"; \
		exit 1; \
	fi

.PHONY: deps
deps:
	ansible-galaxy install -r requirements.yml

.PHONY: jannovar
jannovar: configs check
	ansible-playbook -i inventories/production plays/jannovar.yml

.PHONY: postgres
postgres: configs check
	ansible-playbook -i inventories/production plays/postgres.yml

.PHONY: varfish
varfish: configs check
	ansible-playbook -i inventories/production plays/varfish.yml
