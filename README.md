# browser_extension

## Building

First of all, run:
```bash
flutter pub get
```

This will also regenerate translations.

To build the extension, run the following command:

```bash
flutter build web --no-web-resources-cdn
```

- `--no-web-resources-cdn` is used to load libraries (specifically canvaskit) locally rather than through a CDN.


## Firefox setup

1. In search bar type `about:debugging`
2. Press `Load Temporary Add-on`
3. Go to select `<extendion_dir>/build/web/manifest.json`

## Chrome setup

1. In search bar type `chrome:extensions`
2. Enable *Developer mode*
3. Press `Load unpacked`
4. Select the web directory `<extension_dirt>/build/web`
