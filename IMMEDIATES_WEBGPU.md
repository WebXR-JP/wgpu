# IMMEDIATES WebGPU bindings patch

This patch adds experimental WebGPU `IMMEDIATES` support to the vendored `webgpu_sys` bindings used by wgpu's WebGPU backend.

## Why a manual patch is required

The vendored `webgpu_sys` bindings are generated from Web IDL using `cargo xtask vendor-web-sys`. The WebGPU `IMMEDIATES` proposal is still experimental, so it is not yet present in the upstream `web-sys` WebGPU bindings that wgpu vendors. Until upstream `wasm-bindgen/web-sys` adds these bindings, we maintain a small local patch so wgpu's WebGPU backend can call the new JS methods and read the new limit.

Because these files are generated, any re-vendor will overwrite them. The patch keeps the additions isolated and easy to re-apply or update.

## What is patched

`patches/wgpu/webgpu_sys-immediates.patch` modifies 5 generated files under `wgpu/src/backend/webgpu/webgpu_sys/`:

- `gen_GpuSupportedLimits.rs` — adds `max_immediate_size()` getter (`maxImmediateSize` limit).
- `gen_GpuComputePassEncoder.rs` — adds `set_immediates()` method.
- `gen_GpuRenderPassEncoder.rs` — adds `set_immediates()` method.
- `gen_GpuRenderBundleEncoder.rs` — adds `set_immediates()` method.
- `gen_GpuPipelineLayoutDescriptor.rs` — adds `immediate_size()` setter (`immediateSize` dictionary member).

`gen_GpuFeatureName.rs` is intentionally not modified; `IMMEDIATES` is a core JS API feature and has no `GPUFeatureName` entry.

## Re-applying after re-vendoring

Whenever the bindings are regenerated with `cargo xtask vendor-web-sys`, the generated files above will be overwritten. To restore IMMEDIATES support:

```bash
cargo xtask vendor-web-sys
cd patches/wgpu
git apply webgpu_sys-immediates.patch
```

Check that the patch still applies cleanly:

```bash
git -C patches/wgpu apply --check webgpu_sys-immediates.patch
```

If it fails, inspect the regenerated files and update the patch hunks accordingly, keeping the `// MANUAL PATCH: IMMEDIATES support` markers on every added binding.

## Upstream tracking

- Chromium bug for `IMMEDIATES` implementation: https://crbug.com/366291600
- WebGPU proposal discussion: https://github.com/gpuweb/gpuweb/issues/4198
- Dawn tracking bug: https://bugs.chromium.org/p/dawn/issues/detail?id=2276

When upstream `web-sys` ships these bindings, this patch should be removed.

## Detecting IMMEDIATES support

`IMMEDIATES` is not exposed as a `GPUFeatureName`. Detect it in one of these ways:

- Check the `maxImmediateSize` adapter limit:

  ```js
  const adapter = await navigator.gpu.requestAdapter();
  if (adapter.limits.maxImmediateSize > 0) {
    // IMMEDIATES is supported
  }
  ```

- Check the WGSL language feature `immediate_address_space`:

  ```js
  if (navigator.gpu.wgslLanguageFeatures.has('immediate_address_space')) {
    // IMMEDIATES is supported
  }
  ```

The `maxImmediateSize` limit is the preferred signal, because it is available as soon as the adapter is available.

## Verification

Run the patch integrity checker:

```bash
patches/wgpu/scripts/check-webgpu-sys-immediates-patch.sh
```

It exits `0` when all expected symbols are present and `Immediates` is absent from `gen_GpuFeatureName.rs`. It exits non-zero and lists any missing or unexpected symbols.
