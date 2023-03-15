import { readFileSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import nodeResolve from "rollup-plugin-node-resolve";
import babel from "rollup-plugin-babel";
import { terser } from "rollup-plugin-terser";
import replace from "rollup-plugin-replace";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const wasmBytes = Array.from(
  readFileSync(resolve(__dirname, "src/xxhash.wasm"))
);

const wasm3Bytes = Array.from(
  readFileSync(resolve(__dirname, "src/xxh3.wasm"))
);

const wasm3PerfBytes = Array.from(
  readFileSync(resolve(__dirname, "src/xxh3-perf.wasm"))
);

const replacements = {
  WASM_PRECOMPILED_BYTES: JSON.stringify(wasmBytes),
  WASM_3_PRECOMPILED_BYTES: JSON.stringify(wasm3Bytes),
  WASM_3_PERF_PRECOMPILED_BYTES: JSON.stringify(wasm3PerfBytes),
};

export default [{
  input: "src/index.js",
  output: [
    {
      file: "cjs/xxhash-wasm.cjs",
      format: "cjs",
      sourcemap: true,
      exports: "default",
    },
    { file: "esm/xxhash-wasm.js", format: "es", sourcemap: true },
    {
      file: "umd/xxhash-wasm.js",
      format: "umd",
      name: "xxhash",
      sourcemap: true,
    },
  ],
  plugins: [
    replace(replacements),
    babel({ exclude: "node_modules/**" }),
    nodeResolve(),
    terser({ toplevel: true }),
  ],
}, {
  input: "src/xxh3.js",
  output: [
    {
      file: "cjs/xxh3.cjs",
      format: "cjs",
      sourcemap: true,
      exports: "default",
    },
    { file: "esm/xxh3.js", format: "es", sourcemap: true },
    {
      file: "umd/xxh3.js",
      format: "umd",
      name: "xxh3",
      sourcemap: true,
    },
  ],
  plugins: [
    replace(replacements),
    babel({ exclude: "node_modules/**" }),
    nodeResolve(),
    terser({ toplevel: true }),
  ],
},  {
  input: "src/xxh3-perf.js",
  output: [
    {
      file: "cjs/xxh3-perf.cjs",
      format: "cjs",
      sourcemap: true,
      exports: "default",
    },
    { file: "esm/xxh3-perf.js", format: "es", sourcemap: true },
    {
      file: "umd/xxh3-perf.js",
      format: "umd",
      name: "xxh3-perf",
      sourcemap: true,
    },
  ],
  plugins: [
    replace(replacements),
    babel({ exclude: "node_modules/**" }),
    nodeResolve(),
    terser({ toplevel: true }),
  ],
}];
