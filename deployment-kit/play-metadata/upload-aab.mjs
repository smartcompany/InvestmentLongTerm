#!/usr/bin/env node
/**
 * Upload an Android App Bundle (.aab) to Google Play and assign it to a track.
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  createAndroidPublisher,
  requirePlayEnv,
  withEdit,
} from './lib/play.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DEFAULT_AAB = path.join(
  __dirname,
  '../../build/app/outputs/bundle/release/app-release.aab',
);

function parseArgs(argv) {
  const args = {
    dryRun: false,
    track: 'production',
    status: 'draft',
    aabPath: DEFAULT_AAB,
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--track') args.track = argv[++i];
    else if (a === '--status') args.status = argv[++i];
    else if (a === '--aab') args.aabPath = path.resolve(argv[++i]);
    else if (a === '--help' || a === '-h') args.help = true;
  }
  return args;
}

function formatBytes(n) {
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(`Usage: node upload-aab.mjs [options]

Options:
  --aab PATH             Default: client/build/app/outputs/bundle/release/app-release.aab
  --track production     internal | alpha | beta | production
  --status draft         draft | completed (default: draft — review in Play Console)
  --dry-run
`);
    process.exit(0);
  }

  if (!['draft', 'completed'].includes(args.status)) {
    throw new Error('--status must be draft or completed');
  }

  const aabPath = path.resolve(args.aabPath);
  if (!fs.existsSync(aabPath)) {
    throw new Error(`AAB not found: ${aabPath}`);
  }

  const stat = fs.statSync(aabPath);
  console.log(`AAB: ${aabPath} (${formatBytes(stat.size)})`);
  console.log(`Track: ${args.track}, status: ${args.status}`);

  if (args.dryRun) {
    console.log('Dry run — no upload.');
    return;
  }

  const { jsonPath, packageName } = requirePlayEnv(__dirname);
  console.log(`Package: ${packageName}`);

  const androidpublisher = await createAndroidPublisher(jsonPath);

  await withEdit(androidpublisher, packageName, async (editId) => {
    console.log('Uploading bundle…');
    const { data: bundle } = await androidpublisher.edits.bundles.upload(
      {
        packageName,
        editId,
        media: {
          mimeType: 'application/octet-stream',
          body: fs.createReadStream(aabPath),
        },
      },
      { timeout: 10 * 60 * 1000 },
    );

    const versionCode = bundle.versionCode;
    if (versionCode == null) {
      throw new Error('Upload succeeded but no versionCode in response');
    }
    console.log(`✓ uploaded versionCode ${versionCode}`);

    const { data: track } = await androidpublisher.edits.tracks.get({
      editId,
      packageName,
      track: args.track,
    });

    const kept = (track.releases ?? []).filter((r) => r.status !== 'draft');
    kept.push({
      status: args.status,
      versionCodes: [String(versionCode)],
    });

    await androidpublisher.edits.tracks.update({
      editId,
      packageName,
      track: args.track,
      requestBody: {
        track: args.track,
        releases: kept,
      },
    });
    console.log(`✓ assigned to track "${args.track}" as ${args.status}`);
  });

  console.log('\nDone — AAB uploaded and track changes committed.');
}

main().catch((err) => {
  if (err.code === 'PLAY_PACKAGE_NOT_FOUND') {
    console.error(err.message);
    process.exit(2);
  }
  console.error(err.message || err);
  process.exit(1);
});
