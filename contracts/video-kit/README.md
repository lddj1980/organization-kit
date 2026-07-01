# Video Kit Contract

This contract defines how the Video Kit integrates with the Organization Kit framework.

## Overview

Produces video content.

## Inputs

### Required
- `constitution.md`
- `brand.md`
- `video-spec.md`
### Optional
- `storyboard.md`
- `script-draft.md`

## Outputs

- `videos/` - Video files
- `storyboard.md` - Storyboard
- `script.md` - Final script
- `report.md` - Implementation report

## Acceptance Criteria

See [protocol/contract-standard.md](../../protocol/contract-standard.md) for detailed criteria.

## Integration

To invoke this kit:

```bash
/org.invoke video
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

