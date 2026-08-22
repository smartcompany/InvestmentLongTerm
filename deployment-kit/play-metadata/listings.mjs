/**
 * Google Play listing copy — sourced from App Store listings.mjs
 * Play locales: ko-KR, en-US, ja-JP, zh-CN
 */
import asc from '../asc-metadata/listings.mjs';

const ASC_BY_PLAY = {
  'ko-KR': 'ko',
  'en-US': 'en-US',
  'ja-JP': 'ja',
  'zh-CN': 'zh-Hans',
};

function stripMarkdown(text) {
  return String(text).replace(/\*\*/g, '').trim();
}

function clip(s, max) {
  const t = String(s ?? '').trim();
  if (t.length <= max) return t;
  return t.slice(0, max - 1) + '…';
}

const listings = {};

for (const [playLocale, ascKey] of Object.entries(ASC_BY_PLAY)) {
  const entry = asc[ascKey];
  if (!entry) continue;
  const promo = entry.promotionalText?.trim();
  listings[playLocale] = {
    title: clip(entry.name, 30),
    shortDescription: clip(promo || entry.subtitle, 80),
    fullDescription: clip(stripMarkdown(entry.description), 4000),
  };
}

export default listings;
export { ASC_BY_PLAY };
