# GNU Makefile as entry point for Ansible-based VarFish installer.

# Use bash as shell for more advanced parameters.
SHELL := bash
# The configuration files that should be created.
CONFIGS := \
	inventories/production/group_vars/all/jannovar.yml \
	inventories/production/group_vars/all/servers.yml \
	inventories/production/group_vars/all/varfish.yml \
	inventories/production/group_vars/all/postgres.yml \
	inventories/production/group_vars/all/ssl.yml

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
	@echo "secrets     -- create file with secret strings"
	@echo ""
	@echo "postgres    -- install PostgreSQL"
	@echo "jannovar    -- install Jannovar REST API"
	@echo "varfish     -- install VarFish server and initialize database"

inventories/production/group_vars/all/secrets.yml:
	@bash $@.sh > $@

secrets: inventories/production/group_vars/all/secrets.yml

inventories/production/group_vars/all/%.yml: inventories/production/group_vars/all/%.yml.EXAMPLE
	@if [[ -e $@ ]]; then \
		echo "$@ already exists, not creating"; \
	else \
		echo "$< => $@"; \
		cp $< $@; \
	fi

configs: $(CONFIGS)

.PHONY: deps
deps:
	ansible-galaxy install -r requirements.yml

.PHONY: jannovar
jannovar: configs
	ansible-playbook -i inventories/production plays/jannovar.yml

.PHONY: postgres
postgres: configs
	ansible-playbook -i inventories/production plays/postgres.yml

.PHONY: varfish
varfish: configs
	ansible-playbook -i inventories/production plays/varfish.yml
