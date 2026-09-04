import { loadListings } from './play.mjs';
import { listConfiguredLocales } from './screenshots.mjs';

export async function verifyPlayStoreState({
  androidpublisher,
  packageName,
  locales,
  listingsFile,
}) {
  const expected = await loadListings(listingsFile);
  const { data: edit } = await androidpublisher.edits.insert({ packageName });
  const editId = edit.id;
  if (!editId) throw new Error('edits.insert returned no edit id');

  try {
    console.log('\n--- Play Console state (live) ---');
    for (const locale of locales) {
      const { data: listing } = await androidpublisher.edits.listings.get({
        editId,
        packageName,
        language: locale,
      });

      const { data: images } = await androidpublisher.edits.images.list({
        editId,
        packageName,
        language: locale,
        imageType: 'phoneScreenshots',
      });

      const shotCount = images.images?.length ?? 0;
      const titleOk = listing.title === expected[locale]?.title;
      console.log(
        `${locale}: title=${listing.title ? `"${listing.title}"` : '(empty)'} | screenshots=${shotCount}${titleOk ? '' : ' (title differs from listings.mjs)'}`,
      );
    }
  } finally {
    try {
      await androidpublisher.edits.delete({ editId, packageName });
    } catch {
      /* ignore */
    }
  }
}

export function defaultVerifyLocales() {
  return listConfiguredLocales();
}
