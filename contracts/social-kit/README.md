# Social Kit Contract

This contract defines how the Social Kit integrates with the Organization Kit framework.

## Overview

Manages social media presence.

## Inputs

### Required
- `constitution.md`
- `brand.md`
- `social-strategy.md`
### Optional
- `content-calendar.md`
- `analytics-export.md`

## Outputs

- `posts/` - Social media posts
- `calendar.md` - Content calendar
- `analytics.md` - Performance analytics
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke social
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

