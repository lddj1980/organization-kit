# Visual Kit Contract

This contract defines how the Visual Kit integrates with the Organization Kit framework.

## Overview

Creates visual assets (design, identity, graphics).

## Inputs

### Required
- `constitution.md`
- `brand.md`
- `visual-spec.md`
### Optional
- `moodboard.md`
- `references.md`

## Outputs

- `assets/` - Visual asset files
- `style-guide.md` - Style guide documentation
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke visual
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

