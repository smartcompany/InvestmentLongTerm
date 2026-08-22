#!/usr/bin/env node
/** @deprecated Prefer update-metadata.mjs — kept as a thin alias. */
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const dir = path.dirname(fileURLToPath(import.meta.url));
const result = spawnSync(
  process.execPath,
  [path.join(dir, 'update-metadata.mjs'), '--only', 'whatsNew', ...process.argv.slice(2)],
  { stdio: 'inherit' },
);
process.exit(result.status ?? 1);
