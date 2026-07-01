# SEO Kit Contract

This contract defines how the SEO Kit integrates with the Organization Kit framework.

## Overview

Optimizes content for search engines.

## Inputs

### Required
- `constitution.md`
- `website-spec.md`
- `seo-requirements.md`
### Optional
- `keyword-list.md`
- `competitor-analysis.md`

## Outputs

- `seo-audit.md` - SEO audit report
- `keyword-research.md` - Keyword research
- `recommendations.md` - SEO recommendations
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke seo
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

