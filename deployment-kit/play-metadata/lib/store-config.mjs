import fs from 'node:fs';
import path from 'node:path';

/**
 * Store URLs + Play Console contact fields from deployment-kit/app-config.json
 * (same source of truth as asc-metadata/store-urls.mjs).
 */
export function loadStoreConfig(scriptDir) {
  const configPath = path.join(scriptDir, '..', 'app-config.json');
  if (!fs.existsSync(configPath)) {
    throw new Error(`app-config.json not found: ${configPath}`);
  }

  const raw = JSON.parse(fs.readFileSync(configPath, 'utf8'));
  const serverBaseUrl = String(raw.serverBaseUrl ?? '')
    .trim()
    .replace(/\/$/, '');
  const privacyPath = String(raw.privacyPath ?? '/privacy').trim();
  const privacyUrl =
    process.env.PLAY_PRIVACY_URL?.trim() ||
    (serverBaseUrl
      ? `${serverBaseUrl}${privacyPath.startsWith('/') ? privacyPath : `/${privacyPath}`}`
      : null);

  return {
    privacyUrl,
    supportUrl:
      process.env.PLAY_SUPPORT_URL?.trim() ||
      raw.supportUrl?.trim() ||
      'https://smartcompany.github.io',
    contactEmail:
      process.env.PLAY_CONTACT_EMAIL?.trim() ||
      raw.supportEmail?.trim() ||
      raw.reviewContactEmail?.trim() ||
      null,
    contactPhone:
      process.env.PLAY_CONTACT_PHONE?.trim() ||
      raw.reviewContactPhone?.trim() ||
      null,
    defaultLanguage:
      process.env.PLAY_DEFAULT_LANGUAGE?.trim() || 'en-US',
  };
}

export function buildAppDetails(storeConfig) {
  const body = {
    defaultLanguage: storeConfig.defaultLanguage,
  };
  if (storeConfig.supportUrl) {
    body.contactWebsite = storeConfig.supportUrl;
  }
  if (storeConfig.contactEmail) {
    body.contactEmail = storeConfig.contactEmail;
  }
  if (storeConfig.contactPhone) {
    body.contactPhone = storeConfig.contactPhone;
  }
  return body;
}

export function printPrivacyPolicyReminder(privacyUrl) {
  if (!privacyUrl) return;
  console.log('\n--- Privacy policy (manual in Play Console) ---');
  console.log(
    'Google Play API cannot set the App content → Privacy policy URL.',
  );
  console.log('Set it once in Play Console → Policy → App content → Privacy policy:');
  console.log(`  ${privacyUrl}`);
}
