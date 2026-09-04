#!/usr/bin/env node
/**
 * Upload Google Play store listing graphics:
 * - hi-res icon (512×512) from app_icon.png → app_icon_512.png
 * - feature graphic (1024×500) from marketing.png → feature_graphic_1024x500.png
 * - phone screenshots per locale from {KR,EN,CH,JP}/
 *
 * Source root (default): ../../Screenshots/screenshots-pro
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { ensureAppIcon512 } from './lib/app-icon.mjs';
import { ensureFeatureGraphic } from './lib/feature-graphic.mjs';
import {
  DEFAULT_SCREENSHOTS_ROOT,
  listConfiguredLocales,
  resolveScreenshotFiles,
} from './lib/screenshots.mjs';
import {
  uploadLocaleAsset,
  uploadLocaleScreenshots,
} from './lib/store-images.mjs';
import { createAndroidPublisher, requirePlayEnv } from './lib/play.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = {
    dryRun: false,
    screenshotsRoot: DEFAULT_SCREENSHOTS_ROOT,
    onlyLocales: null,
    skipIcon: false,
    skipFeature: false,
    skipScreenshots: false,
    help: false,
  };

  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--screenshots-root') {
      args.screenshotsRoot = path.resolve(argv[++i]);
    } else if (a === '--locale') {
      args.onlyLocales ??= new Set();
      args.onlyLocales.add(argv[++i]);
    } else if (a === '--skip-icon') args.skipIcon = true;
    else if (a === '--skip-feature') args.skipFeature = true;
    else if (a === '--skip-screenshots') args.skipScreenshots = true;
    else if (a === '--help' || a === '-h') args.help = true;
  }

  return args;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(`Usage: node upload-screenshots.mjs [options]

Uploads Play store listing graphics from Screenshots/screenshots-pro:

  app_icon.png              → app_icon_512.png (512×512 hi-res icon)
  marketing.png             → feature_graphic_1024x500.png (1024×500)
  {KR,EN,CH,JP}/1..5.png    → phoneScreenshots (per locale)

Options:
  --dry-run
  --screenshots-root DIR
  --locale ko-KR            Repeat for specific locales
  --skip-icon
  --skip-feature
  --skip-screenshots
`);
    process.exit(0);
  }

  const locales = (args.onlyLocales
    ? [...args.onlyLocales]
    : listConfiguredLocales()
  ).sort();

  console.log(`Store assets root: ${args.screenshotsRoot}`);

  let iconPath = null;
  let featurePath = null;

  if (!args.skipIcon) {
    if (args.dryRun) {
      iconPath = path.join(args.screenshotsRoot, 'app_icon_512.png');
      console.log(`App icon: ${iconPath} (from app_icon.png if missing)`);
    } else {
      iconPath = ensureAppIcon512(args.screenshotsRoot).path;
      console.log(`App icon: ${iconPath}`);
    }
  }

  if (!args.skipFeature) {
    if (args.dryRun) {
      featurePath = path.join(args.screenshotsRoot, 'feature_graphic_1024x500.png');
      console.log(`Feature graphic: ${featurePath} (from marketing.png if missing)`);
    } else {
      featurePath = ensureFeatureGraphic(args.screenshotsRoot).path;
      console.log(`Feature graphic: ${featurePath}`);
    }
  }

  const screenshotPlan = new Map();
  if (!args.skipScreenshots) {
    for (const locale of locales) {
      screenshotPlan.set(locale, resolveScreenshotFiles(locale, args.screenshotsRoot));
    }
    console.log(`Screenshot locales: ${locales.join(', ')}`);
    for (const [locale, files] of screenshotPlan) {
      console.log(`  ${locale}: ${files.length} file(s)`);
    }
  }
  console.log('');

  if (args.dryRun) {
    if (iconPath) console.log(`[dry-run] icon → all locales`);
    if (featurePath) console.log(`[dry-run] featureGraphic → all locales`);
    for (const [locale, files] of screenshotPlan) {
      console.log(`=== ${locale} phoneScreenshots ===`);
      for (const filePath of files) {
        console.log(`  ${path.basename(filePath)}`);
      }
    }
    return;
  }

  const { jsonPath, packageName } = requirePlayEnv(__dirname);
  console.log(`Package: ${packageName}`);
  console.log(`Service account: ${jsonPath}\n`);

  const androidpublisher = await createAndroidPublisher(jsonPath);

  for (const locale of locales) {
    if (iconPath) {
      await uploadLocaleAsset({
        androidpublisher,
        packageName,
        locale,
        imageType: 'icon',
        filePath: iconPath,
        label: 'icon',
      });
    }
  }

  for (const locale of locales) {
    if (featurePath) {
      await uploadLocaleAsset({
        androidpublisher,
        packageName,
        locale,
        imageType: 'featureGraphic',
        filePath: featurePath,
        label: 'featureGraphic',
      });
    }
  }

  for (const [locale, files] of screenshotPlan) {
    await uploadLocaleScreenshots({
      androidpublisher,
      packageName,
      locale,
      files,
    });
  }

  console.log('\nDone — store listing graphics committed.');
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
