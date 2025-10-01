# Makefile for dotfiles management

.PHONY: help install check lint test clean

# Default target
.DEFAULT_GOAL := help

# Variables
PLAYBOOK := site.yml
INVENTORY := inventory
TAGS ?=

help: ## Show this help message
	@echo "Dotfiles Management Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make install              # Full installation"
	@echo "  make install TAGS=zsh     # Install only zsh"
	@echo "  make check                # Dry-run installation"
	@echo "  make lint                 # Lint Ansible files"

install: ## Install dotfiles using Ansible
	@echo "Installing dotfiles..."
	@if [ -z "$(TAGS)" ]; then \
		ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --ask-become-pass; \
	else \
		ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --ask-become-pass --tags $(TAGS); \
	fi

check: ## Run Ansible in check mode (dry-run)
	@echo "Running in check mode (dry-run)..."
	@ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --check --diff

lint: ## Lint Ansible playbooks and roles
	@echo "Linting Ansible files..."
	@if command -v ansible-lint >/dev/null 2>&1; then \
		ansible-lint $(PLAYBOOK); \
	else \
		echo "ansible-lint not installed. Install with: pip install ansible-lint"; \
		exit 1; \
	fi

syntax: ## Check Ansible syntax
	@echo "Checking Ansible syntax..."
	@ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --syntax-check

test: syntax ## Run tests
	@echo "Running tests..."
	@ansible-playbook $(PLAYBOOK) -i $(INVENTORY) --check

bootstrap: ## Run bootstrap installation script
	@echo "Running bootstrap script..."
	@chmod +x scripts/install.sh
	@./scripts/install.sh

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@find . -type f -name "*.retry" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@rm -f ansible.log

deps: ## Install Ansible dependencies
	@echo "Installing Ansible dependencies..."
	@pip3 install --user ansible ansible-lint

base: ## Install only base packages
	@$(MAKE) install TAGS=base

zsh: ## Install only zsh
	@$(MAKE) install TAGS=zsh

tmux: ## Install only tmux
	@$(MAKE) install TAGS=tmux

nvim: ## Install only neovim
	@$(MAKE) install TAGS=neovim

shell: ## Install shell tools (zsh + tmux)
	@$(MAKE) install TAGS=zsh,tmux

version: ## Show Ansible version
	@ansible --version
