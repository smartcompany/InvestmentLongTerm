#!/usr/bin/env node
/**
 * Set release notes (What's new) on a draft release for a track.
 * Requires an existing draft on that track with the given versionCode.
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  createAndroidPublisher,
  readWhatsNew,
  requirePlayEnv,
  withEdit,
} from './lib/play.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {
    dryRun: false,
    track: 'production',
    versionCode: null,
    whatsNewFile: path.join(__dirname, '../asc-metadata/whats-new.json'),
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--track') args.track = argv[++i];
    else if (a === '--version-code') args.versionCode = Number(argv[++i]);
    else if (a === '--whats-new') args.whatsNewFile = path.resolve(argv[++i]);
    else if (a === '--help' || a === '-h') args.help = true;
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(`Usage: node update-whats-new.mjs --version-code 42 [options]

Options:
  --version-code N       Required — must match a draft release on the track
  --track production     internal | alpha | beta | production
  --whats-new FILE       Default: ../asc-metadata/whats-new.json
  --dry-run
`);
    process.exit(0);
  }

  if (!args.versionCode || Number.isNaN(args.versionCode)) {
    throw new Error('--version-code is required (integer build number from Play / pubspec)');
  }

  const notesByLocale = readWhatsNew(args.whatsNewFile);
  if (notesByLocale.size === 0) {
    throw new Error(`No release notes in ${args.whatsNewFile}`);
  }

  const releaseNotes = [...notesByLocale.entries()].map(([language, text]) => ({
    language,
    text,
  }));

  console.log(`Track: ${args.track}, versionCode: ${args.versionCode}`);
  console.log(`Notes locales: ${[...notesByLocale.keys()].join(', ')}`);

  if (args.dryRun) {
    for (const n of releaseNotes) {
      const preview =
        n.text.length > 80 ? `${n.text.slice(0, 80).replace(/\n/g, ' ')}…` : n.text;
      console.log(`  ${n.language}: ${preview}`);
    }
    return;
  }

  const { jsonPath, packageName } = requirePlayEnv(__dirname);
  console.log(`Package: ${packageName}`);

  const androidpublisher = await createAndroidPublisher(jsonPath);

  await withEdit(androidpublisher, packageName, async (editId) => {
    const { data: track } = await androidpublisher.edits.tracks.get({
      editId,
      packageName,
      track: args.track,
    });

    const releases = track.releases ?? [];
    let target = releases.find(
      (r) =>
        r.status === 'draft' &&
        (r.versionCodes ?? []).some((c) => Number(c) === args.versionCode),
    );

    if (!target) {
      target = releases.find((r) => r.status === 'draft');
    }

    if (!target) {
      throw new Error(
        `No draft release on track "${args.track}". Upload an AAB as draft first, then run this with matching --version-code.`,
      );
    }

    const versionCodes = target.versionCodes ?? [];
    if (!versionCodes.some((c) => Number(c) === args.versionCode)) {
      console.warn(
        `Warning: draft release has versionCodes [${versionCodes.join(', ')}], not ${args.versionCode}. Updating that draft anyway.`,
      );
    }

    target.releaseNotes = releaseNotes;

    await androidpublisher.edits.tracks.update({
      editId,
      packageName,
      track: args.track,
      requestBody: {
        track: args.track,
        releases,
      },
    });
    console.log('✓ release notes patched on draft release');
  });

  console.log('\nDone — track changes committed.');
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
