# Workflow — package-work (Contract-Driven)

## Prerequisites
- Active organization with constitution.md
- A specification identifying a capability kit
- The contract.yaml exists in contracts/<kit-name>/

## Steps

1. **Identify kit from spec** — Read the spec's "Capability Kit" field
2. **Load contract** — Read contracts/<kit-name>/contract.yaml
3. **Extract request structure** — From contract.request_structure, determine what goes in request/
4. **Extract response structure** — From contract.response_structure, determine the response/ layout
5. **Create work-package** — Create directories matching contract structure
6. **Write manifest** — Include contract version and contract-derived acceptance criteria
7. **Package request files** — Gather spec files into request/spec/
8. **Confirm** — Show contract-derived summary
