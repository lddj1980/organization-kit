# Work Package: 0001-build-website

**Kit:** website-kit v2.0.0
**Status:** BLOCKED - 4 required input(s) missing
**Created:** 2026-06-29

## Objective

Builds or modifies websites from organization specifications.

## Required Inputs

| File | Status |
|------|--------|
| constitution.md | MISSING |
| brand.md | MISSING |
| audience.md | MISSING |
| website-spec.md | MISSING |

## Expected Outputs

| Output | Status |
|--------|--------|
| website/ | expected |
| documentation/ | expected |
| tests/ | expected |
| report.md | expected |

## Where to work

All deliverables go in the response/ folder. The directory is pre-scaffolded.

## Acceptance criteria

- all required pages implemented
- responsive layout
- SEO metadata present
- brand voice respected
- accessibility considered
- implementation report included
- strategic alignment checked

## How to return the delivery

1. Complete all outputs in the response/ folder.
2. Fill response/report.md with objective, decisions, and any deviations.
3. Run review:   .\scripts\review-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "<path>"
4. If approved:  .\scripts\accept-work-package.ps1 -WorkPackage "0001-build-website" -ProjectPath "<path>"
