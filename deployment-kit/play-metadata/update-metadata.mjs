#!/usr/bin/env node
/**
 * Upload Google Play store listing + app contact details via Android Publisher API.
 *
 * Listings: title, shortDescription, fullDescription (per locale)
 * Details:  defaultLanguage, contactWebsite, contactEmail, contactPhone
 *
 * Privacy policy URL is NOT available via this API — set manually in Play Console
 * (App content → Privacy policy). URL is printed from app-config.json as a reminder.
 */

import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildAppDetails,
  loadStoreConfig,
  printPrivacyPolicyReminder,
} from './lib/store-config.mjs';
import {
  createAndroidPublisher,
  loadListings,
  requirePlayEnv,
  withEdit,
} from './lib/play.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const LISTING_FIELDS = ['title', 'shortDescription', 'fullDescription'];
const ALL_FIELDS = [...LISTING_FIELDS, 'details'];

function parseArgs(argv) {
  const args = {
    dryRun: false,
    listingsFile: path.join(__dirname, 'listings.mjs'),
    only: new Set(ALL_FIELDS),
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--listings') args.listingsFile = path.resolve(argv[++i]);
    else if (a === '--only') {
      args.only = new Set(
        argv[++i]
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
      );
    } else if (a === '--help' || a === '-h') args.help = true;
  }
  return args;
}

function pickListing(entry, only) {
  const out = {};
  for (const key of LISTING_FIELDS) {
    if (!only.has(key)) continue;
    const v = entry[key];
    if (v != null && String(v).trim() !== '') {
      out[key] = String(v).trim();
    }
  }
  return out;
}

function wantsListings(only) {
  return LISTING_FIELDS.some((f) => only.has(f));
}

function wantsDetails(only) {
  return only.has('details');
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(`Usage: node update-metadata.mjs [options]

Options:
  --dry-run              Preview only
  --listings FILE        Default: ./listings.mjs
  --only title,shortDescription,fullDescription,details

Fields:
  title, shortDescription, fullDescription  Per-locale store listing (API)
  details                                   contactWebsite/email/phone + defaultLanguage (API)
  privacyPolicyUrl                          NOT via API — printed for manual Play Console setup
`);
    process.exit(0);
  }

  for (const f of args.only) {
    if (!ALL_FIELDS.includes(f)) {
      throw new Error(`Unknown field: ${f}. Valid: ${ALL_FIELDS.join(', ')}`);
    }
  }

  const storeConfig = loadStoreConfig(__dirname);
  const appDetails = buildAppDetails(storeConfig);
  const listings = await loadListings(args.listingsFile);
  const locales = Object.keys(listings).sort();

  if (args.dryRun) {
    console.log(`Package: ${process.env.PLAY_PACKAGE_NAME || 'com.smartcompany.useByDate'}`);
    console.log(`Locales: ${locales.join(', ')}`);
    console.log(`Listing fields: ${LISTING_FIELDS.filter((f) => args.only.has(f)).join(', ') || '(none)'}`);
    console.log(`Details: ${wantsDetails(args.only) ? 'yes' : 'no'}\n`);

    if (wantsListings(args.only)) {
      for (const locale of locales) {
        const body = pickListing(listings[locale], args.only);
        console.log(`=== listing ${locale} ===`);
        for (const [k, v] of Object.entries(body)) {
          const preview = v.length > 100 ? `${v.slice(0, 100)}…` : v;
          console.log(`  ${k}: ${preview}`);
        }
      }
    }

    if (wantsDetails(args.only)) {
      console.log('\n=== app details (edits.details) ===');
      for (const [k, v] of Object.entries(appDetails)) {
        console.log(`  ${k}: ${v}`);
      }
    }

    printPrivacyPolicyReminder(storeConfig.privacyUrl);
    return;
  }

  const { jsonPath, packageName } = requirePlayEnv(__dirname);

  console.log(`Package: ${packageName}`);
  console.log(`Service account: ${jsonPath}`);
  console.log(`Locales: ${locales.join(', ')}`);
  console.log(
    `Fields: ${[...args.only].filter((f) => f !== 'details').join(', ')}${wantsDetails(args.only) ? ', details' : ''}\n`,
  );

  const androidpublisher = await createAndroidPublisher(jsonPath);

  await withEdit(androidpublisher, packageName, async (editId) => {
    if (wantsListings(args.only)) {
      for (const locale of locales) {
        const requestBody = pickListing(listings[locale], args.only);
        if (Object.keys(requestBody).length === 0) continue;
        console.log(`Updating listing ${locale}…`);
        await androidpublisher.edits.listings.update({
          editId,
          packageName,
          language: locale,
          requestBody,
        });
        console.log(`✓ listing ${locale}`);
      }
    }

    if (wantsDetails(args.only)) {
      console.log('Updating app details (contact / default language)…');
      await androidpublisher.edits.details.update({
        editId,
        packageName,
        requestBody: appDetails,
      });
      console.log('✓ app details');
    }
  });

  console.log('\nDone — changes committed.');
  printPrivacyPolicyReminder(storeConfig.privacyUrl);
}

main().catch((err) => {
  console.error(err.message || err);
  if (err.code === 'PLAY_PACKAGE_NOT_FOUND') {
    console.error(
      '\nCreate the app in Google Play Console first, upload the first AAB, then rerun metadata upload.',
    );
    process.exit(2);
  }
  process.exit(1);
});
