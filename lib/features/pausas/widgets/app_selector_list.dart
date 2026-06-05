// Data constants kept for backward-compat with rutina_card.dart.
// Selector widget replaced by AppPickerSheet.

class AppDef {
  const AppDef(this.name, this.package);
  final String name;
  final String package;
}

const kAppDefs = [
  AppDef('Instagram', 'com.instagram.android'),
  AppDef('TikTok', 'com.zhiliaoapp.musically'),
  AppDef('YouTube', 'com.google.android.youtube'),
  AppDef('Twitter', 'com.twitter.android'),
  AppDef('WhatsApp', 'com.whatsapp'),
  AppDef('Facebook', 'com.facebook.katana'),
  AppDef('Snapchat', 'com.snapchat.android'),
  AppDef('Twitch', 'tv.twitch.android.app'),
];
