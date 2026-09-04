import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __screenshotsLibDir = path.dirname(fileURLToPath(import.meta.url));

/** Play locale → folder name under screenshots root */
export const SCREENSHOT_FOLDER_BY_LOCALE = {
  'ko-KR': 'KR',
  'en-US': 'EN',
  'ja-JP': 'JP',
  'zh-CN': 'CH',
};

export const DEFAULT_SCREENSHOTS_ROOT = path.resolve(
  __screenshotsLibDir,
  '../../../../Screenshots/screenshots-pro',
);

function numericSort(a, b) {
  const na = Number.parseInt(path.basename(a), 10);
  const nb = Number.parseInt(path.basename(b), 10);
  if (!Number.isNaN(na) && !Number.isNaN(nb) && na !== nb) return na - nb;
  return a.localeCompare(b, undefined, { numeric: true });
}

export function resolveScreenshotFiles(locale, screenshotsRoot = DEFAULT_SCREENSHOTS_ROOT) {
  const folderName = SCREENSHOT_FOLDER_BY_LOCALE[locale];
  if (!folderName) {
    throw new Error(`No screenshot folder mapping for locale: ${locale}`);
  }

  const dir = path.join(screenshotsRoot, folderName);
  if (!fs.existsSync(dir)) {
    throw new Error(`Screenshot folder not found: ${dir}`);
  }

  const files = fs
    .readdirSync(dir)
    .filter((name) => /\.(png|jpe?g)$/i.test(name))
    .map((name) => path.join(dir, name))
    .sort(numericSort);

  if (files.length === 0) {
    throw new Error(`No PNG/JPEG screenshots in ${dir}`);
  }

  return files;
}

export function listConfiguredLocales() {
  return Object.keys(SCREENSHOT_FOLDER_BY_LOCALE).sort();
}
