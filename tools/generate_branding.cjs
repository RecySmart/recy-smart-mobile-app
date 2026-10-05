// Render platform icons from one editable SVG. No network access or installation.
// Usage: node tools/generate_branding.cjs [absolute-path-to-sharp-module]
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'assets/branding/recysmart-symbol.svg');
async function render(relative, size, opaque = false) {
  const target = path.join(root, relative);
  fs.mkdirSync(path.dirname(target), {recursive: true});
  let pipeline = sharp(source).resize(size, size);
  if (opaque) pipeline = pipeline.flatten({background: '#FFFFFF'});
  await pipeline.png().toFile(target);
  const metadata = await sharp(target).metadata();
  if (metadata.width !== size || metadata.height !== size) throw new Error(`Invalid size: ${relative}`);
  console.log(`${relative}: ${size}x${size}`);
}
async function main() {
  await render('assets/branding/recysmart-symbol.png', 1024);
  await render('assets/branding/recysmart-app-icon-1024.png', 1024, true);
  await render('web/favicon.png', 32, true);
  for (const size of [192,512]) await render(`web/icons/Icon-${size}.png`,size,true);
  for (const [density,size,foreground] of [['mdpi',48,108],['hdpi',72,162],['xhdpi',96,216],['xxhdpi',144,324],['xxxhdpi',192,432]]) {
    await render(`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,size,true);
    await render(`android/app/src/main/res/mipmap-${density}/ic_launcher_foreground.png`,foreground);
  }
}
main().catch(error => {console.error(error);process.exitCode=1;});
