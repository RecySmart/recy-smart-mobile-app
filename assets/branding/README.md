# RecySmart branding

The canonical editable symbol is `recysmart-symbol.svg`: a white PET bottle surrounded by two green recycling arrows. It is an approximate vector reconstruction of the approved concept, not the alternative R monogram.

`tools/generate_branding.cjs` rasterizes this SVG into the Flutter asset, opaque Android legacy launcher icons, transparent adaptive foregrounds and opaque web/PWA icons. It requires Node.js and Sharp supplied by the caller; it neither installs packages nor changes Flutter dependencies.

```sh
node tools/generate_branding.cjs /absolute/path/to/sharp
```

The Flutter splash, login and registration screens use `recysmart-symbol.png` with a Spanish semantic label. Action icons remain unchanged. Android 26+ uses an adaptive icon with a white background; older versions use density-specific PNGs. Web favicon, touch icon and manifest URLs remain stable.

The complete raster wordmark is preserved separately in the documentation vault, not bundled because the current screens already render their own text. No endpoint or deployment configuration is changed by this branding update.

Platform builds do not verify installed launcher appearance or existing browser/PWA caches. Check those on a device after reinstalling or updating the app.
