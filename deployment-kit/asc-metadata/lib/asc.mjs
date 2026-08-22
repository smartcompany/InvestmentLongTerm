import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

export const API = 'https://api.appstoreconnect.apple.com/v1';

export const EDITABLE_STATES = new Set([
  'PREPARE_FOR_SUBMISSION',
  'DEVELOPER_REJECTED',
  'REJECTED',
  'METADATA_REJECTED',
  'INVALID_BINARY',
]);

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

function b64url(input) {
  const buf = Buffer.isBuffer(input) ? input : Buffer.from(input);
  return buf.toString('base64url');
}

export function createAscToken({ issuerId, keyId, privateKeyPem }) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'ES256', kid: keyId, typ: 'JWT' };
  const payload = {
    iss: issuerId,
    iat: now,
    exp: now + 15 * 60,
    aud: 'appstoreconnect-v1',
  };
  const encodedHeader = b64url(JSON.stringify(header));
  const encodedPayload = b64url(JSON.stringify(payload));
  const data = `${encodedHeader}.${encodedPayload}`;
  const key = crypto.createPrivateKey(privateKeyPem);
  const signature = crypto.sign('SHA256', Buffer.from(data), {
    key,
    dsaEncoding: 'ieee-p1363',
  });
  return `${data}.${b64url(signature)}`;
}

export async function ascFetch(token, urlPath, { method = 'GET', body } = {}) {
  const res = await fetch(`${API}${urlPath}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      Accept: 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let json;
  try {
    json = text ? JSON.parse(text) : null;
  } catch {
    json = { raw: text };
  }
  if (!res.ok) {
    const detail = JSON.stringify(json?.errors ?? json, null, 2);
    throw new Error(`${method} ${urlPath} → ${res.status}\n${detail}`);
  }
  return json;
}

export async function resolveAppId(token, { appId, bundleId }) {
  if (appId) return String(appId);
  if (!bundleId) {
    throw new Error('Set ASC_APP_ID or ASC_BUNDLE_ID in .env');
  }
  const q = new URLSearchParams({ 'filter[bundleId]': bundleId });
  const json = await ascFetch(token, `/apps?${q}`);
  const app = json.data?.[0];
  if (!app) throw new Error(`App not found for bundleId=${bundleId}`);
  return app.id;
}

export async function resolveIosVersion(token, appId, versionName) {
  const q = new URLSearchParams({
    'filter[platform]': 'IOS',
    limit: '50',
  });
  const json = await ascFetch(token, `/apps/${appId}/appStoreVersions?${q}`);
  const versions = json.data ?? [];
  if (versions.length === 0) {
    throw new Error('No iOS App Store versions found');
  }

  let candidates = versions;
  if (versionName) {
    candidates = versions.filter((v) => v.attributes?.versionString === versionName);
    if (candidates.length === 0) {
      throw new Error(`No iOS version matching ${versionName}`);
    }
  }

  const editable = candidates.find((v) =>
    EDITABLE_STATES.has(v.attributes?.appStoreState),
  );
  if (editable) return editable;

  const sorted = [...candidates].sort((a, b) =>
    String(b.attributes?.versionString ?? '').localeCompare(
      String(a.attributes?.versionString ?? ''),
      undefined,
      { numeric: true },
    ),
  );
  return sorted[0];
}

export async function resolveAppInfo(token, appId) {
  const json = await ascFetch(token, `/apps/${appId}/appInfos`);
  const infos = json.data ?? [];
  if (infos.length === 0) throw new Error('No appInfos found');

  const editable = infos.find((info) =>
    EDITABLE_STATES.has(info.attributes?.appStoreState),
  );
  if (editable) return editable;

  console.warn(
    `Warning: no editable appInfo (states: ${infos
      .map((i) => i.attributes?.appStoreState ?? '?')
      .join(', ')}). name/subtitle updates may fail.`,
  );
  return infos[0];
}

export function readWhatsNew(filePath) {
  if (!fs.existsSync(filePath)) return new Map();
  const raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  const map = new Map();
  for (const [locale, value] of Object.entries(raw)) {
    const text = String(value ?? '').trim();
    if (!text) continue;
    map.set(locale, text);
  }
  return map;
}

const LISTING_KEYS = [
  'name',
  'subtitle',
  'promotionalText',
  'description',
  'keywords',
];

export async function loadListings(filePath) {
  if (!fs.existsSync(filePath)) {
    throw new Error(`Listings file not found: ${filePath}`);
  }

  let raw;
  if (/\.m?js$/i.test(filePath)) {
    const mod = await import(pathToFileURL(filePath).href);
    raw = mod.default ?? mod.listings;
  } else {
    raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  }
  if (!raw || typeof raw !== 'object') {
    throw new Error(`Invalid listings export in ${filePath}`);
  }

  const map = new Map();
  for (const [locale, entry] of Object.entries(raw)) {
    if (!entry || typeof entry !== 'object') continue;
    const fields = {};
    for (const key of LISTING_KEYS) {
      const value = entry[key];
      fields[key] =
        value == null || String(value).trim() === ''
          ? null
          : String(value).trim();
    }
    map.set(locale, fields);
  }
  if (map.size === 0) {
    throw new Error(`No locales found in ${filePath}`);
  }
  return map;
}

export function requireAscEnv(scriptDir) {
  loadEnvFile(path.join(scriptDir, '.env'));
  const issuerId = process.env.ASC_ISSUER_ID?.trim();
  const keyId = process.env.ASC_KEY_ID?.trim();
  const keyPathRaw = process.env.ASC_PRIVATE_KEY_PATH?.trim();
  const appId = process.env.ASC_APP_ID?.trim();
  const bundleId =
    process.env.ASC_BUNDLE_ID?.trim() || 'com.smartcompany.longterminvestment';

  if (!issuerId || !keyId || !keyPathRaw) {
    throw new Error(
      'Missing ASC_ISSUER_ID, ASC_KEY_ID, or ASC_PRIVATE_KEY_PATH (.env)',
    );
  }

  const keyPath = path.isAbsolute(keyPathRaw)
    ? keyPathRaw
    : path.resolve(scriptDir, keyPathRaw);
  if (!fs.existsSync(keyPath)) {
    throw new Error(`Private key not found: ${keyPath}`);
  }

  const privateKeyPem = fs.readFileSync(keyPath, 'utf8');
  const token = createAscToken({ issuerId, keyId, privateKeyPem });
  return { token, appId, bundleId, keyId, keyPath };
}
