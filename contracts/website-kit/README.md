# Website Kit Contract

This contract defines how the Website Kit integrates with the Organization Kit framework.

## Overview

The Website Kit builds and modifies websites based on organizational specifications.

## Inputs

### Required
- `constitution.md` — Organization constitution
- `brand.md` — Brand guidelines
- `audience.md` — Audience profile
- `website-spec.md` — Website specification

### Optional
- `seo-requirements.md` — SEO requirements
- `content-map.md` — Content structure
- `design-system.md` — Design system tokens

## Outputs

- `website/` — Source code and assets
- `documentation/` — Documentation files
- `tests/` — Test files and results
- `report.md` — Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke website-kit
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