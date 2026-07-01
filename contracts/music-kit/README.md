# Music Kit Contract

This contract defines how the Music Kit integrates with the Organization Kit framework.

## Overview

Produces and manages music tracks, albums, audio content.

## Inputs

### Required
- `constitution.md`
- `brand.md`
- `music-spec.md`
### Optional
- `brief.md`
- `references.md`

## Outputs

- `tracks/` - Audio track files
- `metadata.json` - Track metadata
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke music
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

