# SVLBH Remotion

Remotion sub-project for generating videos used by SVLBH Panel. This package
is intentionally isolated from the SwiftUI iOS app — it has its own
`package.json`, its own `node_modules`, and its own build pipeline.

## Requirements

- Node.js 18+ (Remotion 4.x supports Node 16+, but 18+ is recommended)
- A C/C++ toolchain for the headless Chrome download (handled automatically
  on first install)
- See the [Remotion system requirements](https://www.remotion.dev/docs/system-requirements)
  for platform-specific notes (macOS 13+, glibc 2.35+ on Linux, etc.)

## Getting started

```bash
cd remotion
npm install
npm run dev
```

`npm run dev` opens the Remotion Studio at http://localhost:3000 where you
can preview and tweak compositions.

## Rendering a video

```bash
npm run render -- HelloWorld out/hello.mp4
```

The first positional argument is the `id` of the composition declared in
`src/Root.tsx`; the second is the output path.

## Project layout

```
remotion/
├── package.json          # Node deps + scripts
├── tsconfig.json         # TypeScript config
├── remotion.config.ts    # Remotion CLI config
└── src/
    ├── index.ts          # registerRoot entry
    ├── Root.tsx          # <Composition> registry
    └── HelloWorld.tsx    # Sample composition
```

## Adding a new composition

1. Create a new component under `src/` (e.g. `src/MyVideo.tsx`).
2. Register it in `src/Root.tsx` with a unique `id`, `durationInFrames`,
   `fps`, `width`, `height`, and any `defaultProps`.
3. Use `useCurrentFrame()` + `interpolate()` / `spring()` to drive
   animations — never CSS transitions.

## Licensing

Remotion is free for individuals and small teams but requires a company
license above a certain headcount. Review
<https://www.remotion.dev/docs/license> before shipping anything that
involves SVLBH commercially.
