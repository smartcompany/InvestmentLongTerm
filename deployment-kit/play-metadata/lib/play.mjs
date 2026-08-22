import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const DEFAULT_PACKAGE =
  process.env.PLAY_PACKAGE_NAME?.trim() || 'com.smartcompany.longterminvestment';

export function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const text = fs.readFileSync(filePath, 'utf8');
  for (const line of text.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (process.env[key] == null || process.env[key] === '') {
      process.env[key] = value;
    }
  }
}

export function requirePlayEnv(scriptDir) {
  loadEnvFile(path.join(scriptDir, '.env'));
  const jsonPathRaw = process.env.PLAY_SERVICE_ACCOUNT_JSON?.trim();
  const packageName =
    process.env.PLAY_PACKAGE_NAME?.trim() || DEFAULT_PACKAGE;

  if (!jsonPathRaw) {
    throw new Error(
      'Set PLAY_SERVICE_ACCOUNT_JSON in .env (Play Console API service account JSON path)',
    );
  }

  const jsonPath = path.isAbsolute(jsonPathRaw)
    ? jsonPathRaw
    : path.resolve(scriptDir, jsonPathRaw);
  if (!fs.existsSync(jsonPath)) {
    throw new Error(`Service account JSON not found: ${jsonPath}`);
  }

  return { jsonPath, packageName };
}

export async function createAndroidPublisher(jsonPath) {
  const { google } = await import('googleapis');
  const auth = new google.auth.GoogleAuth({
    keyFile: jsonPath,
    scopes: ['https://www.googleapis.com/auth/androidpublisher'],
  });
  return google.androidpublisher({ version: 'v3', auth });
}

export async function loadListings(filePath) {
  const resolved = path.resolve(filePath);
  const mod = await import(pathToFileURL(resolved).href);
  const raw = mod.default ?? mod.listings;
  if (!raw || typeof raw !== 'object') {
    throw new Error(`Invalid listings: ${filePath}`);
  }
  return raw;
}

export const WHATS_NEW_ASC_TO_PLAY = {
  ko: 'ko-KR',
  'en-US': 'en-US',
  ja: 'ja-JP',
  'zh-Hans': 'zh-CN',
};

export function readWhatsNew(filePath) {
  if (!fs.existsSync(filePath)) return new Map();
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const map = new Map();
  for (const [locale, value] of Object.entries(raw)) {
    const playLocale = WHATS_NEW_ASC_TO_PLAY[locale] ?? locale;
    const text = String(value ?? '').trim();
    if (!text) continue;
    map.set(playLocale, text);
  }
  return map;
}

export function isPackageNotFoundError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('Package not found') ||
    msg.includes('applicationNotFound') ||
    msg.includes('The project was not found')
  );
}

export async function withEdit(androidpublisher, packageName, fn) {
  let edit;
  try {
    ({ data: edit } = await androidpublisher.edits.insert({
      packageName,
    }));
  } catch (err) {
    if (isPackageNotFoundError(err)) {
      const error = new Error(`Package not found: ${packageName}.`);
      error.code = 'PLAY_PACKAGE_NOT_FOUND';
      throw error;
    }
    throw err;
  }
  const editId = edit.id;
  if (!editId) throw new Error('edits.insert returned no edit id');
  try {
    return await fn(editId);
  } finally {
    try {
      await androidpublisher.edits.commit({ editId, packageName });
    } catch (err) {
      try {
        await androidpublisher.edits.delete({ editId, packageName });
      } catch {
        /* ignore */
      }
      throw err;
    }
  }
}
