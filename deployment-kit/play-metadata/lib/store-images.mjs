import fs from 'node:fs';

import { mimeTypeFor } from './image-utils.mjs';
import { withEdit } from './play.mjs';

export function isRetryableEditError(err) {
  const msg = String(err?.message ?? err);
  return (
    msg.includes('Edit has been deleted') ||
    msg.includes('editHasBeenDeleted') ||
    msg.includes('outside of this Edit') ||
    msg.includes('please create a new edit')
  );
}

async function uploadImageType({
  androidpublisher,
  editId,
  packageName,
  locale,
  imageType,
  filePath,
}) {
  await androidpublisher.edits.images.deleteall({
    editId,
    packageName,
    language: locale,
    imageType,
  });

  await androidpublisher.edits.images.upload({
    editId,
    packageName,
    language: locale,
    imageType,
    media: {
      mimeType: mimeTypeFor(filePath),
      body: fs.createReadStream(filePath),
    },
  });
}

async function uploadImageTypeFiles({
  androidpublisher,
  editId,
  packageName,
  locale,
  imageType,
  files,
}) {
  await androidpublisher.edits.images.deleteall({
    editId,
    packageName,
    language: locale,
    imageType,
  });

  for (const filePath of files) {
    await androidpublisher.edits.images.upload({
      editId,
      packageName,
      language: locale,
      imageType,
      media: {
        mimeType: mimeTypeFor(filePath),
        body: fs.createReadStream(filePath),
      },
    });
  }
}

export async function uploadWithRetry({
  androidpublisher,
  packageName,
  label,
  uploadFn,
  maxAttempts = 3,
}) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await withEdit(androidpublisher, packageName, async (editId) => {
        await uploadFn(editId);
      });
      return;
    } catch (err) {
      if (!isRetryableEditError(err) || attempt === maxAttempts) throw err;
      console.warn(`  ⚠ ${label}: edit expired, retry ${attempt}/${maxAttempts - 1}…`);
      await new Promise((r) => setTimeout(r, 2000 * attempt));
    }
  }
}

export async function uploadLocaleAsset({
  androidpublisher,
  packageName,
  locale,
  imageType,
  filePath,
  label,
}) {
  console.log(`Uploading ${label} ${locale}…`);
  await uploadWithRetry({
    androidpublisher,
    packageName,
    label,
    uploadFn: (editId) =>
      uploadImageType({
        androidpublisher,
        editId,
        packageName,
        locale,
        imageType,
        filePath,
      }),
  });
  console.log(`✓ ${locale} ${label} committed`);
}

export async function uploadLocaleScreenshots({
  androidpublisher,
  packageName,
  locale,
  files,
}) {
  console.log(`Uploading ${locale} phoneScreenshots (${files.length})…`);
  await uploadWithRetry({
    androidpublisher,
    packageName,
    label: `${locale} phoneScreenshots`,
    uploadFn: async (editId) => {
      await uploadImageTypeFiles({
        androidpublisher,
        editId,
        packageName,
        locale,
        imageType: 'phoneScreenshots',
        files,
      });
      for (const filePath of files) {
        console.log(`  ✓ ${filePath.split('/').pop()}`);
      }
    },
  });
  console.log(`✓ ${locale} phoneScreenshots committed`);
}
