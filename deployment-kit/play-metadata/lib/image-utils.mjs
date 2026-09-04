import { execFileSync } from 'node:child_process';

export function readDimensions(filePath) {
  const out = execFileSync('sips', ['-g', 'pixelWidth', '-g', 'pixelHeight', filePath], {
    encoding: 'utf8',
  });
  const width = Number(out.match(/pixelWidth:\s*(\d+)/)?.[1] ?? 0);
  const height = Number(out.match(/pixelHeight:\s*(\d+)/)?.[1] ?? 0);
  return { width, height };
}

export function mimeTypeFor(filePath) {
  const ext = filePath.toLowerCase().slice(filePath.lastIndexOf('.'));
  if (ext === '.png') return 'image/png';
  if (ext === '.jpg' || ext === '.jpeg') return 'image/jpeg';
  return 'application/octet-stream';
}
