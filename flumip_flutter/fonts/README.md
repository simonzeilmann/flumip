# Bundled fonts

Roboto Regular, Italic, Medium and Bold, copied unmodified from the Flutter SDK
(`bin/cache/artifacts/material_fonts/`). Roboto is by Christian Robertson for
Google and is licensed under the Apache License, Version 2.0.

**Why they are here:** a Flutter web build that does not bundle Roboto downloads
it from `fonts.gstatic.com` on every page load. That sends each visitor's IP
address to Google, which a public instance's cookie notice promises does not
happen — and which German courts have treated as a GDPR violation. Together with
`--no-web-resources-cdn` on every `flutter build web` and the font fallback
setting in `web/flutter_bootstrap.js`, this keeps the app from contacting any
third party. See `docs/public-instance.md`.
