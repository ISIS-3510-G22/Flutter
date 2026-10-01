final _tagPattern = RegExp(r'^[\p{L}\p{N}][\p{L}\p{N} -]*$', unicode: true);

String? validateTag(String tag) {
  if (tag.length > 20) return 'Tags can be 20 characters at most.';
  if (!_tagPattern.hasMatch(tag)) {
    return 'Use only letters, numbers, spaces and hyphens.';
  }
  return null;
}

double? parsePrice(String text) =>
    RegExp(r'^\d{1,9}$').hasMatch(text) ? double.parse(text) : null;
