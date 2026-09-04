import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';

import { readDimensions } from './image-utils.mjs';

export const FEATURE_GRAPHIC_FILENAME = 'feature_graphic_1024x500.png';

const SOURCE_CANDIDATES = [
  'feature_graphic.png',
  'marketing.png',
  'image_marketing.png',
  'marketing_image.png',
];

const TARGET_WIDTH = 1024;
const TARGET_HEIGHT = 500;

function findSourceMarketing(screenshotsRoot) {
  for (const name of SOURCE_CANDIDATES) {
    const candidate = path.join(screenshotsRoot, name);
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

function generateFeatureGraphicFromSource(sourcePath, outputPath) {
  execFileSync(
    'magick',
    [
      sourcePath,
      '-alpha',
      'on',
      '-thumbnail',
      `${TARGET_WIDTH}x${TARGET_HEIGHT}^`,
      '-gravity',
      'center',
      '-extent',
      `${TARGET_WIDTH}x${TARGET_HEIGHT}`,
      '-strip',
      'PNG24:' + outputPath,
    ],
    { stdio: 'pipe' },
  );
}

/**
 * Returns path to 1024×500 PNG for Play Console feature graphic.
 */
export function ensureFeatureGraphic(screenshotsRoot) {
  const outputPath = path.join(screenshotsRoot, FEATURE_GRAPHIC_FILENAME);

  if (fs.existsSync(outputPath)) {
    const { width, height } = readDimensions(outputPath);
    if (width === TARGET_WIDTH && height === TARGET_HEIGHT) {
      return { path: outputPath, created: false };
    }
    console.log(
      `Regenerating ${FEATURE_GRAPHIC_FILENAME} (was ${width}x${height})…`,
    );
  }

  const sourcePath = findSourceMarketing(screenshotsRoot);
  if (!sourcePath) {
    throw new Error(
      `No marketing image in ${screenshotsRoot}. Add marketing.png or feature_graphic.png.`,
    );
  }

  const sourceDims = readDimensions(sourcePath);
  if (
    sourceDims.width === TARGET_WIDTH &&
    sourceDims.height === TARGET_HEIGHT &&
    sourcePath.endsWith('.png')
  ) {
    fs.copyFileSync(sourcePath, outputPath);
    return { path: outputPath, created: true };
  }

  generateFeatureGraphicFromSource(sourcePath, outputPath);
  const { width, height } = readDimensions(outputPath);
  if (width !== TARGET_WIDTH || height !== TARGET_HEIGHT) {
    throw new Error(
      `Failed to create ${TARGET_WIDTH}x${TARGET_HEIGHT} feature graphic (got ${width}x${height})`,
    );
  }

  console.log(
    `Created ${FEATURE_GRAPHIC_FILENAME} from ${path.basename(sourcePath)}`,
  );
  return { path: outputPath, created: true };
}
