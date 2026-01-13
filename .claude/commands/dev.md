# Development Workflow

Run the Ansible playbook in check mode (dry-run) to preview changes without applying them.

## Steps

1. Run the main playbook in check mode:
```bash
ansible-playbook -i localhost.yml setup.yml --check --diff
```

2. If there are issues, run ansible-lint to validate:
```bash
ansible-lint setup.yml
```

3. To apply changes after review:
```bash
ansible-playbook -i localhost.yml setup.yml
```

## For Single Tool Development

When working on a specific tool, test it in isolation:
```bash
ansible-playbook -i localhost.yml tools/<tool>/install_<tool>.yml --check --diff
```
