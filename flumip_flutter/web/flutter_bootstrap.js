{{flutter_js}}
{{flutter_build_config}}

// ⚠️ Nothing may be fetched from a third party — a public instance's cookie
// notice says so. Two settings make that true, together with bundling Roboto
// (pubspec.yaml) and `--no-web-resources-cdn` on every build, which serves
// CanvasKit from this server instead of www.gstatic.com:
//
// fontFallbackBaseUrl: the engine downloads Noto fonts from fonts.gstatic.com
// for any glyph Roboto lacks. Pointed at this server instead, where nothing is
// served, such a glyph is drawn as a box rather than reported to Google. The
// app's own text is all in Roboto's range.
_flutter.loader.load({
  config: {
    fontFallbackBaseUrl: 'assets/fonts/fallback/',
  },
});
