# Content Kit Contract

This contract defines how the Content Kit integrates with the Organization Kit framework.

## Overview

Creates editorial content (articles, blog posts, essays).

## Inputs

### Required
- `constitution.md`
- `brand.md`
- `audience.md`
- `content-spec.md`
### Optional
- `seo-requirements.md`
- `editorial-calendar.md`

## Outputs

- `articles/` - Article files
- `metadata.json` - Article metadata
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke content
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

