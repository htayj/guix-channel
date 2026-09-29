# Third-party notices

This channel is licensed under GPL-3.0-or-later; see `LICENSE`.  Upstream
materials retain their own licenses and notices.  The SentinelOne notice
below applies to copied and adapted Guix packaging code only; it grants no
rights in the proprietary agent, which this channel neither includes nor
fetches.

## sentinelone-guix

`guix/tay/packages/sentinelone.scm` is adapted from Morgan Helton's
[`htayj/sentinelone-guix`](https://github.com/htayj/sentinelone-guix) upstream
package definition at commit `2ed11dd6f935e0498c2bf91d355990c062147c2c`.
The upstream repository supplies the following MIT notice:

```text
MIT License

Copyright (c) 2025 Morgan Helton

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Fontra and locked frontend dependencies

`guix/tay/packages/fontra.scm` packages
[`fontra/fontra`](https://github.com/fontra/fontra) tag `2026.9.0`, commit
`cc0a3b40bcd9860d8b6382df1faf6122ec306a5b`, under GPL-3.0.  Its upstream
`LICENSE.txt` is installed as `share/doc/fontra/LICENSE`.

The frontend's individual npm distribution archives are pinned in
`guix/tay/packages/fontra-npm-sources.scm`.  They retain upstream licenses;
the channel's license does not relicense them.  In particular, `harfbuzzjs`
includes MIT-licensed precompiled shaping WASM, `build-shaper-font` includes
Apache-2.0-licensed precompiled WASM, and `source-map` includes BSD-3-Clause
precompiled build-time WASM.  These artifacts are not rebuilt from source by
this channel.  Dependency `LICENSE`, `LICENCE`, `COPYING`, and `NOTICE` files
are preserved under `share/doc/fontra/npm/node_modules/` with their dependency
paths, including notices for the shipped WASM.  Consult those installed files
for the complete upstream grants and attribution requirements.

## Slang shader compiler

`guix/tay/packages/shader-slang.scm` builds
[`shader-slang/slang`](https://github.com/shader-slang/slang) 2026.14.1 from
source: commit `7c58a326b1f3812411a204b19cb01e323d8f6010` (annotated tag
`v2026.14.1`), fetched with its Git submodules as one fixed-output source.
Slang itself is Apache-2.0 WITH LLVM-exception.  The source snippet deletes
submodules this build does not use or takes from Guix, including the non-free
OptiX SDK headers and the prebuilt Windows binaries in mimalloc, imgui and
tinyobjloader; miniz and unordered_dense are Guix inputs.  The build uses
the remaining bundled submodules from that source tree: glslang
(BSD-3-Clause, MIT, Apache-2.0), SPIRV-Tools, SPIRV-Headers and
Vulkan-Headers (Apache-2.0, MIT), lz4's library (BSD-2-Clause), cmark
(BSD-2-Clause), fast_float (Apache-2.0, MIT or BSL-1.0) and Lua (MIT); any of
these that are compiled are compiled from source.  The build disables
every option that downloads prebuilt components (slang-llvm, DXC, slang-rhi),
so no upstream binaries are packaged.  Upstream `LICENSE` and the `LICENSES/`
texts are installed under `share/doc/shader-slang-2026.14.1/`.
