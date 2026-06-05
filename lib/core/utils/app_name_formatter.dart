const _knownPackages = <String, String>{
  'com.instagram.android': 'Instagram',
  'com.zhiliaoapp.musically': 'TikTok',
  'com.google.android.youtube': 'YouTube',
  'com.twitter.android': 'Twitter',
  'com.facebook.katana': 'Facebook',
  'com.snapchat.android': 'Snapchat',
  'com.whatsapp': 'WhatsApp',
  'com.pausa.pausa_app': 'PAUSA',
  'pausa_app': 'PAUSA',
  'tv.twitch.android.app': 'Twitch',
  'com.netflix.mediaclient': 'Netflix',
  'com.spotify.music': 'Spotify',
};

String formatAppName(String packageOrName) {
  final known = _knownPackages[packageOrName];
  if (known != null) return known;

  if (!packageOrName.contains('.')) {
    return _capitalize(packageOrName.replaceAll('_', ' '));
  }

  final segment = packageOrName.split('.').last;
  return _capitalize(segment.replaceAll('_', ' '));
}

String appInitial(String formattedName) {
  if (formattedName.isEmpty) return '?';
  return formattedName[0].toUpperCase();
}

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}
