#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
base_dir="$(cd "${script_dir}/.." && pwd)"
sys_dir="${base_dir}/wgpu/src/backend/webgpu/webgpu_sys"

missing=()
extra=()

check_present() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    if ! grep -q "${pattern}" "${file}"; then
        missing+=("${label}")
    fi
}

check_absent() {
    local file="$1"
    local pattern="$2"
    local label="$3"
    if grep -q "${pattern}" "${file}"; then
        extra+=("${label}")
    fi
}

check_present "${sys_dir}/gen_GpuSupportedLimits.rs" "pub fn max_immediate_size" "max_immediate_size getter in gen_GpuSupportedLimits.rs"
check_present "${sys_dir}/gen_GpuComputePassEncoder.rs" "pub fn set_immediates" "set_immediates method in gen_GpuComputePassEncoder.rs"
check_present "${sys_dir}/gen_GpuRenderPassEncoder.rs" "pub fn set_immediates" "set_immediates method in gen_GpuRenderPassEncoder.rs"
check_present "${sys_dir}/gen_GpuRenderBundleEncoder.rs" "pub fn set_immediates" "set_immediates method in gen_GpuRenderBundleEncoder.rs"
check_present "${sys_dir}/gen_GpuPipelineLayoutDescriptor.rs" "pub fn immediate_size" "immediate_size setter in gen_GpuPipelineLayoutDescriptor.rs"

check_absent "${sys_dir}/gen_GpuFeatureName.rs" "Immediates" "Immediates variant absent from gen_GpuFeatureName.rs"

if [ ${#missing[@]} -eq 0 ] && [ ${#extra[@]} -eq 0 ]; then
    echo "OK: webgpu_sys IMMEDIATES patch is applied correctly."
    exit 0
fi

echo "ERROR: webgpu_sys IMMEDIATES patch verification failed." >&2

if [ ${#missing[@]} -gt 0 ]; then
    echo "Missing symbols:" >&2
    for item in "${missing[@]}"; do
        echo "  - ${item}" >&2
    done
fi

if [ ${#extra[@]} -gt 0 ]; then
    echo "Unexpected symbols:" >&2
    for item in "${extra[@]}"; do
        echo "  - ${item}" >&2
    done
fi

exit 1
