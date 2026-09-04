import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

import { readDimensions } from './image-utils.mjs';

export const APP_ICON_512_FILENAME = 'app_icon_512.png';

const SOURCE_CANDIDATES = [
  'app_icon.png',
  'app_icon.jpg',
  'app_icon.jpeg',
  'icon.png',
];

function findSourceIcon(screenshotsRoot) {
  for (const name of SOURCE_CANDIDATES) {
    const candidate = path.join(screenshotsRoot, name);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function generate512FromSource(sourcePath, outputPath) {
  execFileSync(
    'magick',
    [
      sourcePath,
      '-alpha',
      'on',
      '-thumbnail',
      '512x512^',
      '-gravity',
      'center',
      '-extent',
      '512x512',
      '-strip',
      'PNG32:' + outputPath,
    ],
    { stdio: 'pipe' },
  );
}

/**
 * Returns path to 512×512 PNG for Play Console hi-res icon.
 * Uses screenshots-pro/app_icon_512.png if valid; otherwise builds from app_icon.png.
 */
export function ensureAppIcon512(screenshotsRoot) {
  const outputPath = path.join(screenshotsRoot, APP_ICON_512_FILENAME);

  if (fs.existsSync(outputPath)) {
    const { width, height } = readDimensions(outputPath);
    if (width === 512 && height === 512) {
      return { path: outputPath, created: false };
    }
    console.log(`Regenerating ${APP_ICON_512_FILENAME} (was ${width}x${height})…`);
  }

  const sourcePath = findSourceIcon(screenshotsRoot);
  if (!sourcePath) {
    throw new Error(
      `No app icon source in ${screenshotsRoot}. Add app_icon.png (or icon.png).`,
    );
  }

  generate512FromSource(sourcePath, outputPath);
  const { width, height } = readDimensions(outputPath);
  if (width !== 512 || height !== 512) {
    throw new Error(`Failed to create 512x512 icon (got ${width}x${height})`);
  }

  console.log(`Created ${APP_ICON_512_FILENAME} from ${path.basename(sourcePath)}`);
  return { path: outputPath, created: true };
}
