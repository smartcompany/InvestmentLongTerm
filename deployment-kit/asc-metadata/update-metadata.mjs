#!/usr/bin/env node
/**
 * Upload App Store metadata from:
 *   listings.mjs      → name, subtitle, description, keywords, promotionalText
 *   store-urls.mjs    → supportUrl, marketingUrl, privacyPolicyUrl, copyright
 *   whats-new.json    → whatsNew
 *   review-notes.txt  → App Review Information notes
 */

import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { fileURLToPath } from 'node:url';

import {
  EDITABLE_STATES,
  ascFetch,
  loadListings,
  readWhatsNew,
  requireAscEnv,
  resolveAppId,
  resolveAppInfo,
  resolveIosVersion,
} from './lib/asc.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

const ALL_FIELDS = [
  'name',
  'subtitle',
  'description',
  'keywords',
  'promotionalText',
  'supportUrl',
  'marketingUrl',
  'privacyPolicyUrl',
  'copyright',
  'whatsNew',
  'reviewNotes',
];

const APP_INFO_FIELDS = new Set(['name', 'subtitle', 'privacyPolicyUrl']);
const VERSION_FIELDS = new Set([
  'description',
  'keywords',
  'promotionalText',
  'supportUrl',
  'marketingUrl',
  'whatsNew',
]);

async function loadStoreUrls(scriptDir) {
  const filePath = path.join(scriptDir, 'store-urls.mjs');
  const fromEnv = {
    supportUrl: process.env.ASC_SUPPORT_URL?.trim() || null,
    marketingUrl: process.env.ASC_MARKETING_URL?.trim() || null,
    privacyUrl: process.env.ASC_PRIVACY_URL?.trim() || null,
    copyright: process.env.ASC_COPYRIGHT?.trim() || null,
  };
  let fromFile = {};
  try {
    const mod = await import(pathToFileURL(filePath).href);
    const raw = mod.default ?? mod.storeUrls ?? {};
    fromFile = {
      supportUrl: raw.supportUrl?.trim() || null,
      marketingUrl: raw.marketingUrl?.trim() || null,
      privacyUrl: raw.privacyUrl?.trim() || null,
      copyright: raw.copyright?.trim() || null,
    };
  } catch {
    /* optional file */
  }
  return {
    supportUrl: fromEnv.supportUrl ?? fromFile.supportUrl,
    marketingUrl: fromEnv.marketingUrl ?? fromFile.marketingUrl,
    privacyUrl: fromEnv.privacyUrl ?? fromFile.privacyUrl,
    copyright: fromEnv.copyright ?? fromFile.copyright,
  };
}

function parseArgs(argv) {
  const args = {
    dryRun: false,
    version: null,
    listingsFile: path.join(__dirname, 'listings.mjs'),
    whatsNewFile: path.join(__dirname, 'whats-new.json'),
    reviewNotesFile: path.join(__dirname, 'review-notes.mjs'),
    only: new Set(ALL_FIELDS),
    help: false,
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--dry-run') args.dryRun = true;
    else if (a === '--version') args.version = argv[++i];
    else if (a === '--listings') args.listingsFile = path.resolve(argv[++i]);
    else if (a === '--whats-new') args.whatsNewFile = path.resolve(argv[++i]);
    else if (a === '--review-notes') {
      args.reviewNotesFile = path.resolve(argv[++i]);
    } else if (a === '--only') {
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

function pickAttributes(source, keys) {
  const out = {};
  for (const key of keys) {
    const value = source[key];
    if (value != null && String(value).trim() !== '') {
      out[key] = String(value).trim();
    }
  }
  return out;
}

function diffAttributes(desired, currentAttrs = {}) {
  const out = {};
  for (const [key, value] of Object.entries(desired)) {
    const current = currentAttrs[key];
    if (current == null || String(current).trim() !== value) {
      out[key] = value;
    }
  }
  return out;
}

function isInvalidStateError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('INVALID_STATE') ||
    msg.includes('can not be modified in the current state')
  );
}

function isAppNameConflictError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('DUPLICATE.DIFFERENT_ACCOUNT') ||
    (msg.includes('/data/attributes/name') && msg.includes('409'))
  );
}

async function patchAppInfoLocalization(token, locId, attributes) {
  try {
    await ascFetch(token, `/appInfoLocalizations/${locId}`, {
      method: 'PATCH',
      body: {
        data: {
          type: 'appInfoLocalizations',
          id: locId,
          attributes,
        },
      },
    });
    return { skippedName: false };
  } catch (err) {
    if (attributes.name == null || !isAppNameConflictError(err)) {
      throw err;
    }
    const { name: _n, ...rest } = attributes;
    if (Object.keys(rest).length === 0) {
      console.warn(
        '⚠ app name already in use on App Store — set manually in App Store Connect (skipped)',
      );
      return { skippedName: true };
    }
    console.warn(
      '⚠ app name rejected (duplicate) — updating subtitle/other app info only',
    );
    await ascFetch(token, `/appInfoLocalizations/${locId}`, {
      method: 'PATCH',
      body: {
        data: {
          type: 'appInfoLocalizations',
          id: locId,
          attributes: rest,
        },
      },
    });
    return { skippedName: true };
  }
}

async function createAppInfoLocalization(token, appInfoId, locale, attributes = {}) {
  const created = await ascFetch(token, '/appInfoLocalizations', {
    method: 'POST',
    body: {
      data: {
        type: 'appInfoLocalizations',
        attributes: { locale, ...attributes },
        relationships: {
          appInfo: {
            data: { type: 'appInfos', id: appInfoId },
          },
        },
      },
    },
  });
  return created.data;
}

function isWhatsNewLockedError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes("Attribute 'whatsNew' cannot be edited") ||
    (msg.includes('whatsNew') && msg.includes('409'))
  );
}

function isDuplicateLocaleError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('ATTRIBUTE.INVALID.DUPLICATE') &&
    msg.includes('locale')
  );
}

async function patchVersionLocalization(token, locId, attributes) {
  try {
    await ascFetch(token, `/appStoreVersionLocalizations/${locId}`, {
      method: 'PATCH',
      body: {
        data: {
          type: 'appStoreVersionLocalizations',
          id: locId,
          attributes,
        },
      },
    });
    return { skippedWhatsNew: false };
  } catch (err) {
    if (attributes.whatsNew == null || !isWhatsNewLockedError(err)) {
      throw err;
    }
    const { whatsNew: _wn, ...rest } = attributes;
    if (Object.keys(rest).length === 0) {
      console.warn('⚠ whatsNew cannot be edited at this time (skipped)');
      return { skippedWhatsNew: true };
    }
    console.warn(
      '⚠ whatsNew cannot be edited at this time — updating other fields only',
    );
    await ascFetch(token, `/appStoreVersionLocalizations/${locId}`, {
      method: 'PATCH',
      body: {
        data: {
          type: 'appStoreVersionLocalizations',
          id: locId,
          attributes: rest,
        },
      },
    });
    return { skippedWhatsNew: true };
  }
}

async function createVersionLocalization(
  token,
  versionId,
  locale,
  attributes = {},
) {
  try {
    const created = await ascFetch(token, '/appStoreVersionLocalizations', {
      method: 'POST',
      body: {
        data: {
          type: 'appStoreVersionLocalizations',
          attributes: { locale, ...attributes },
          relationships: {
            appStoreVersion: {
              data: { type: 'appStoreVersions', id: versionId },
            },
          },
        },
      },
    });
    return created.data;
  } catch (err) {
    if (!isDuplicateLocaleError(err)) throw err;
    const locs = await ascFetch(
      token,
      `/appStoreVersions/${versionId}/appStoreVersionLocalizations`,
    );
    return (locs.data ?? []).find((loc) => loc.attributes?.locale === locale) ?? null;
  }
}

async function readReviewNotes(filePath) {
  if (!fs.existsSync(filePath)) return null;
  if (filePath.endsWith('.mjs')) {
    const mod = await import(pathToFileURL(filePath).href);
    const notes = String(mod.default ?? mod.reviewNotes ?? '').trim();
    return notes || null;
  }
  const notes = fs.readFileSync(filePath, 'utf8').trim();
  return notes || null;
}

function loadReviewContact() {
  const contact = {
    contactFirstName: process.env.ASC_REVIEW_CONTACT_FIRST_NAME?.trim() || null,
    contactLastName: process.env.ASC_REVIEW_CONTACT_LAST_NAME?.trim() || null,
    contactEmail: process.env.ASC_REVIEW_CONTACT_EMAIL?.trim() || null,
    contactPhone: process.env.ASC_REVIEW_CONTACT_PHONE?.trim() || null,
  };
  return contact;
}

function isValidReviewPhone(value) {
  return /^\+\d[\d\s-]{6,}$/.test(String(value ?? '').trim());
}

function mergeReviewContact(existing = {}, preferred = {}) {
  return {
    contactFirstName:
      preferred.contactFirstName ?? existing.contactFirstName ?? null,
    contactLastName:
      preferred.contactLastName ?? existing.contactLastName ?? null,
    contactEmail: preferred.contactEmail ?? existing.contactEmail ?? null,
    contactPhone: preferred.contactPhone ?? existing.contactPhone ?? null,
  };
}

function missingReviewContactFields(contact) {
  const missing = [];
  if (!contact.contactFirstName) missing.push('contactFirstName');
  if (!contact.contactLastName) missing.push('contactLastName');
  if (!contact.contactEmail) missing.push('contactEmail');
  if (!contact.contactPhone) missing.push('contactPhone');
  else if (!isValidReviewPhone(contact.contactPhone)) {
    missing.push('contactPhone(valid +countrycode format)');
  }
  return missing;
}

async function getOrCreateReviewDetail(token, versionId) {
  const linked = await ascFetch(
    token,
    `/appStoreVersions/${versionId}/appStoreReviewDetail`,
  );
  if (linked.data?.id) {
    const detail = await ascFetch(token, `/appStoreReviewDetails/${linked.data.id}`);
    return detail.data;
  }

  const created = await ascFetch(token, '/appStoreReviewDetails', {
    method: 'POST',
    body: {
      data: {
        type: 'appStoreReviewDetails',
        attributes: {
          demoAccountRequired: false,
        },
        relationships: {
          appStoreVersion: {
            data: { type: 'appStoreVersions', id: versionId },
          },
        },
      },
    },
  });
  return created.data;
}

async function uploadReviewNotes(token, versionId, notes, { dryRun }) {
  const bytes = Buffer.byteLength(notes, 'utf8');
  if (bytes > 4000) {
    console.warn(
      `Warning: review notes are ${bytes} bytes (ASC limit ~4000).`,
    );
  }
  console.log(`\n=== App Review notes (${bytes} bytes) ===`);
  if (dryRun) {
    console.log(notes.slice(0, 400) + (notes.length > 400 ? '…' : ''));
    return;
  }
  const detail = await getOrCreateReviewDetail(token, versionId);
  const preferredContact = loadReviewContact();
  const contact = mergeReviewContact(detail.attributes, preferredContact);
  const missing = missingReviewContactFields(contact);
  if (missing.length > 0) {
    console.warn(
      `⚠ skipping review notes update: missing App Review contact fields (${missing.join(', ')})`,
    );
    console.warn(
      '  Set ASC_REVIEW_CONTACT_FIRST_NAME, ASC_REVIEW_CONTACT_LAST_NAME, ASC_REVIEW_CONTACT_EMAIL, ASC_REVIEW_CONTACT_PHONE in .env when you want to upload review notes.',
    );
    return { skipped: true };
  }
  await ascFetch(token, `/appStoreReviewDetails/${detail.id}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'appStoreReviewDetails',
        id: detail.id,
        attributes: {
          notes,
          demoAccountRequired: false,
          ...contact,
        },
      },
    },
  });
  console.log(`✓ review notes updated (detail=${detail.id})`);
  return { skipped: false };
}

async function uploadCopyright(token, version, copyright, { dryRun }) {
  const current = version.attributes?.copyright?.trim() ?? '';
  if (current === copyright) {
    console.log('\n=== Copyright ===');
    console.log('(version) unchanged');
    return { skipped: false, changed: false };
  }

  console.log(`\n=== Copyright ===`);
  if (dryRun) {
    console.log(`  copyright: ${copyright}`);
    return { skipped: false, changed: true };
  }

  await ascFetch(token, `/appStoreVersions/${version.id}`, {
    method: 'PATCH',
    body: {
      data: {
        type: 'appStoreVersions',
        id: version.id,
        attributes: { copyright },
      },
    },
  });
  console.log(`✓ copyright updated`);
  return { skipped: false, changed: true };
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log(`Usage: node update-metadata.mjs [options]

Options:
  --dry-run                 Preview only
  --version 1.0.3           Target marketing version
  --only a,b,c              Subset of: ${ALL_FIELDS.join(',')}
  --listings FILE           Default: ./listings.mjs
  --whats-new FILE          Default: ./whats-new.json
  --review-notes FILE       Default: ./review-notes.txt
`);
    process.exit(0);
  }

  for (const field of args.only) {
    if (!ALL_FIELDS.includes(field)) {
      throw new Error(`Unknown field in --only: ${field}`);
    }
  }

  const { token, appId: appIdEnv, bundleId } = requireAscEnv(__dirname);
  const wantReviewNotes = args.only.has('reviewNotes');
  const wantCopyright = args.only.has('copyright');
  const wantAppInfo = [...args.only].some((f) => APP_INFO_FIELDS.has(f));
  const wantVersionLoc = [...args.only].some((f) => VERSION_FIELDS.has(f));
  const needListings = wantAppInfo || wantVersionLoc;

  const listings = needListings
    ? await loadListings(args.listingsFile)
    : new Map();
  const storeUrls =
    wantVersionLoc || wantCopyright || wantAppInfo
      ? await loadStoreUrls(__dirname)
      : {};
  const whatsNewByLocale = wantVersionLoc
    ? readWhatsNew(args.whatsNewFile)
    : new Map();
  const reviewNotes = wantReviewNotes
    ? await readReviewNotes(args.reviewNotesFile)
    : null;

  if (wantReviewNotes && !reviewNotes) {
    throw new Error(`Review notes file missing or empty: ${args.reviewNotesFile}`);
  }
  if (wantCopyright && !storeUrls.copyright) {
    throw new Error('Missing copyright in store-urls.mjs or ASC_COPYRIGHT');
  }

  const locales = new Set([...listings.keys(), ...whatsNewByLocale.keys()]);
  const appId = await resolveAppId(token, { appId: appIdEnv, bundleId });

  let appInfo = null;
  let appInfoLocByLocale = new Map();
  if (wantAppInfo) {
    appInfo = await resolveAppInfo(token, appId);
    const locs = await ascFetch(
      token,
      `/appInfos/${appInfo.id}/appInfoLocalizations`,
    );
    appInfoLocByLocale = new Map(
      (locs.data ?? []).map((loc) => [loc.attributes?.locale, loc]),
    );
    console.log(
      `App Info: ${appInfo.id} (${appInfo.attributes?.appStoreState ?? '?'})`,
    );
  }

  let version = null;
  let versionLocByLocale = new Map();
  if (wantVersionLoc || wantReviewNotes || wantCopyright) {
    version = await resolveIosVersion(token, appId, args.version);
    const state = version.attributes?.appStoreState;
    console.log(
      `Version: ${version.attributes?.versionString} (${state}) id=${version.id}`,
    );
    if (!EDITABLE_STATES.has(state)) {
      console.warn(
        `Warning: version state is ${state}. Some fields may reject updates.`,
      );
    }
    if (wantVersionLoc) {
      const locs = await ascFetch(
        token,
        `/appStoreVersions/${version.id}/appStoreVersionLocalizations`,
      );
      versionLocByLocale = new Map(
        (locs.data ?? []).map((loc) => [loc.attributes?.locale, loc]),
      );
    }
  }

  let updated = 0;
  let skipped = 0;

  for (const locale of [...locales].sort()) {
    const listing = listings.get(locale) ?? {};
    const merged = {
      ...listing,
      whatsNew: whatsNewByLocale.get(locale) ?? null,
      supportUrl: listing.supportUrl ?? storeUrls.supportUrl ?? null,
      marketingUrl: listing.marketingUrl ?? storeUrls.marketingUrl ?? null,
      privacyPolicyUrl:
        listing.privacyPolicyUrl ?? storeUrls.privacyUrl ?? null,
    };

    console.log(`\n=== ${locale} ===`);

    if (wantAppInfo) {
      let loc = appInfoLocByLocale.get(locale);
      const desired = pickAttributes(merged, [
        ...args.only,
      ].filter((f) => APP_INFO_FIELDS.has(f)));
      if (!loc && appInfo && !args.dryRun) {
        console.log(`(app info) creating locale ${locale}`);
        const createAttrs = {
          ...desired,
          ...(listing.name && !desired.name ? { name: listing.name } : {}),
        };
        loc = await createAppInfoLocalization(
          token,
          appInfo.id,
          locale,
          createAttrs,
        );
        appInfoLocByLocale.set(locale, loc);
      }
      if (!loc) {
        console.warn(`⚠ No appInfoLocalization for ${locale}`);
        skipped++;
      } else {
        const attributes = diffAttributes(desired, loc.attributes);
        if (Object.keys(attributes).length === 0) {
          console.log('(app info) unchanged');
        } else {
          console.log('(app info)', Object.keys(attributes).join(', '));
          if (args.dryRun) {
            for (const [k, v] of Object.entries(attributes)) {
              const preview = v.length > 80 ? `${v.slice(0, 80)}…` : v;
              console.log(`  ${k}: ${preview}`);
            }
          } else {
            try {
              const { skippedName } = await patchAppInfoLocalization(
                token,
                loc.id,
                attributes,
              );
              if (skippedName) {
                skipped++;
              }
              console.log('✓ app info updated');
              updated++;
            } catch (err) {
              if (isInvalidStateError(err)) {
                console.warn(
                  `⚠ skipped name/subtitle (${locale}): locked in current App Info state`,
                );
                skipped++;
              } else {
                throw err;
              }
            }
          }
        }
      }
    }

    if (wantVersionLoc) {
      let loc = versionLocByLocale.get(locale);
      const desired = pickAttributes(merged, [
        ...args.only,
      ].filter((f) => VERSION_FIELDS.has(f)));
      if (!loc && version && !args.dryRun) {
        console.log(`(version) creating locale ${locale}`);
        loc = await createVersionLocalization(token, version.id, locale, desired);
        versionLocByLocale.set(locale, loc);
      }
      if (!loc) {
        console.warn(`⚠ No appStoreVersionLocalization for ${locale}`);
        skipped++;
      } else {
        const attributes = pickAttributes(merged, [
          ...args.only,
        ].filter((f) => VERSION_FIELDS.has(f)));
        if (Object.keys(attributes).length === 0) {
          console.log('(version) nothing to update');
        } else {
          console.log('(version)', Object.keys(attributes).join(', '));
          if (args.dryRun) {
            for (const [k, v] of Object.entries(attributes)) {
              const preview = v.length > 80 ? `${v.slice(0, 80)}…` : v;
              console.log(`  ${k}: ${preview}`);
            }
          } else {
            const { skippedWhatsNew } = await patchVersionLocalization(
              token,
              loc.id,
              attributes,
            );
            if (skippedWhatsNew) {
              skipped++;
            }
            console.log('✓ version localization updated');
            updated++;
          }
        }
      }
    }
  }

  if (wantCopyright && version) {
    const result = await uploadCopyright(token, version, storeUrls.copyright, {
      dryRun: args.dryRun,
    });
    if (!args.dryRun && result.changed) updated++;
  }

  if (wantReviewNotes && version) {
    const result = await uploadReviewNotes(token, version.id, reviewNotes, {
      dryRun: args.dryRun,
    });
    if (!args.dryRun) {
      if (result?.skipped) skipped++;
      else updated++;
    }
  }

  console.log(
    `\nDone. updated=${updated} skipped=${skipped} dryRun=${args.dryRun}`,
  );
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
