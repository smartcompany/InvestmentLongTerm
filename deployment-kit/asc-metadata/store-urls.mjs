/** Shared public URLs for store metadata. */
const serverBaseUrl = 'https://investment-long-term-server.vercel.app';
const companySiteUrl = 'https://smartcompany.github.io';

const storeUrls = {
  baseUrl: serverBaseUrl,
  privacyUrl: `${serverBaseUrl}/privacy`,
  supportUrl: companySiteUrl,
  marketingUrl: companySiteUrl,
  copyright: '2026 Yong Geon Kim. All rights reserved.',
};

export default storeUrls;
export const { privacyUrl, supportUrl, marketingUrl, copyright } = storeUrls;
