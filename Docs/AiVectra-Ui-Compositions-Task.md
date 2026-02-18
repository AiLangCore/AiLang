# Task: Move High-Level UI Composition To AiVectra

## Goal

Implement high-level UI composition features in `src/AiVectra` using minimal VM UI primitives, instead of adding new VM syscalls.

## Context

VM syscall surface was reduced to primitive/window operations only.
The following high-level operations were intentionally removed from `sys.*`:

- `sys.ui_drawTextPath`
- `sys.ui_drawRectPaint`
- `sys.ui_drawEllipsePaint`
- `sys.ui_drawPolylinePaint`
- `sys.ui_drawPolygonPaint`
- `sys.ui_drawPathPaint`
- `sys.ui_drawTextPaint`
- `sys.ui_filterBlur`
- `sys.ui_groupPush`
- `sys.ui_groupPop`
- `sys.ui_translate`
- `sys.ui_scale`
- `sys.ui_rotate`

These should now exist as AiVectra-level composition helpers.

## Scope

Implement AiVectra helpers that compile down to existing VM primitives:

- Primitive draw targets:
  - `drawRect`, `drawText`, `drawLine`, `drawEllipse`, `drawPath`, `drawPolyline`, `drawPolygon`
- Window lifecycle:
  - `createWindow`, `beginFrame`, `endFrame`, `pollEvent`, `present`, `closeWindow`, `getWindowSize`

## Required AiVectra APIs

- `drawTextPath(path, text, style)`
- `drawRectPaint(rect, paint)`
- `drawEllipsePaint(ellipse, paint)`
- `drawPolylinePaint(points, paint)`
- `drawPolygonPaint(points, paint)`
- `drawPathPaint(path, paint)`
- `drawTextPaint(pos, text, paint)`
- `filterBlur(pathOrShape, amount, paint)`
- `withTransform(transform, drawFn)` (group/translate/scale/rotate composition wrapper)

## Constraints

- Keep VM deterministic and side-effect model unchanged.
- Do not add new VM syscalls for these features.
- No external libraries/NuGet packages.
- Preserve deterministic output ordering.

## Acceptance Criteria

- AiVectra exposes all APIs listed above.
- AiVectra implementations only emit existing primitive/window VM syscalls.
- Add tests proving equivalent visual command sequences for:
  - text-on-path
  - paint/opacity composition
  - blur-style composition
  - grouped transforms
- `./scripts/test.sh` passes.
