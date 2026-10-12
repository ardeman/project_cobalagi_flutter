# YouTube uploads

Every promo video comes with its YouTube text: rendering a video (`tool/marketing/short_video.sh`, `promo_video.sh`; see README → Store listing → Promo videos) also writes `build/marketing/<video>.youtube.txt`, with the title, the description and every upload setting, ready to paste. Never edit those files: change `tool/marketing/youtube.json` and render again, or run `dart run tool/marketing/youtube_text.dart <video> build/marketing/<video>.youtube.txt` for the text alone.

- **Titles carry the app's version** at the time the video is made (`{version}`, the version name in `pubspec.yaml`), so an upload always says which app it shows. A title without `{version}` is refused.
- **The store line** (`{store}` in descriptions) says "Coming soon to Google Play" until the app is public; then render with `STORE=live`, which also gives the short its store end card and puts the Play link in the descriptions.
- **Claims stay true** for the released app, as in the store listing, and both languages say the same.
- `test/store/youtube_text_test.dart` checks YouTube's limits (title 100, description 5,000 characters, no angle brackets) for every video.

YouTube can't replace a video's file: to update a video, delete it and upload the new one. Then update the links where it is shown: the website's promo video (its video ids and title cards in `website/video/`) and, for the landscape promo, the Play listing's Video field.
