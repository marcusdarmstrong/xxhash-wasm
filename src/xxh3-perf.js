// The .wasm is filled in by the build process, so the user doesn't need to load
// xxhash.wasm by themselves because it's part of the bundle. Otherwise it
// couldn't be distributed easily as the user would need to host xxhash.wasm
// and then fetch it, to be able to use it.
// eslint-disable-next-line no-undef
const wasmBytes = new Uint8Array(WASM_3_PERF_PRECOMPILED_BYTES);

const u64_BYTES = 8;
const XXH3_SECRET_BYTES = 192;
const XXH3_WORKING_BYTES = u64_BYTES * 8
const SAFE_STARTING_ADDRESS = 256 /* XXH3_SECRET_BYTES */;

async function xxhash() {
  const {
    instance: {
      exports: {
        mem,
        xxh3,
      },
    },
  } = await WebAssembly.instantiate(wasmBytes, { console });

  let memory = new Uint8Array(mem.buffer, SAFE_STARTING_ADDRESS);
  // Grow the wasm linear memory to accommodate length + offset bytes
  function growMemory(length, offset) {
    if (mem.buffer.byteLength < length + offset) {
      const extraPages = Math.ceil(
        // Wasm pages are spec'd to 64K
        (length + offset - mem.buffer.byteLength) / (64 * 1024)
      );
      mem.grow(extraPages);
      // After growing, the original memory's ArrayBuffer is detached, so we'll
      // need to replace our view over it with a new one over the new backing
      // ArrayBuffer.
      memory = new Uint8Array(mem.buffer, SAFE_STARTING_ADDRESS);
    }
  }

  // BigInts are arbitrary precision and signed, so to get the "correct" u64
  // value from the return, we'll need to force that interpretation.
  const u64Max = 2n ** 64n - 1n;
  function forceUnsigned64(i) {
    return i & u64Max;
  }

  const encoder = new TextEncoder();
  const defaultBigSeed = 0n;

  function h3(str, seed = defaultBigSeed) {
    // https://developer.mozilla.org/en-US/docs/Web/API/TextEncoder/encodeInto#buffer_sizing
    // By sizing the buffer to 3 * string-length we guarantee that the buffer
    // will be appropriately sized for the utf-8 encoding of the string.
    growMemory(str.length * 3, SAFE_STARTING_ADDRESS);
    return forceUnsigned64(
      xxh3(SAFE_STARTING_ADDRESS, encoder.encodeInto(str, memory).written, seed)
    );
  }

  return {
    h3,
    h3ToString(str, seed = defaultBigSeed) {
      return h3(str, seed).toString(16).padStart(16, "0");
    },
    h3Raw(inputBuffer, seed = defaultBigSeed) {
      growMemory(inputBuffer.byteLength, SAFE_STARTING_ADDRESS);
      memory.set(inputBuffer);
      return forceUnsigned64(xxh3(SAFE_STARTING_ADDRESS, inputBuffer.byteLength, seed));
    },
  };
}

export default xxhash;
