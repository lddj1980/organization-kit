# Release Kit Contract

This contract defines how the Release Kit integrates with the Organization Kit framework.

## Overview

Manages releases and launches.

## Inputs

### Required
- `constitution.md`
- `release-plan.md`
### Optional
- `checklist.md`
- `stakeholders.md`

## Outputs

- `release-notes.md` - Release notes
- `changelog.md` - Changelog
- `assets/` - Release assets
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke release
```

The framework will:
1. Locate this contract
2. Gather required inputs
3. Create a work package
4. Invoke the kit
5. Review the response
6. Accept or reject the artifact

## Version

Contract version: 1.0.0
Last updated: 2026-06-29

