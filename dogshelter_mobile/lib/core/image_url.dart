import '../environment.dart';

/// Backend image fields (e.g. Pas.SlikaNaslovna) are server-relative paths
/// like `/images/psi/<guid>.jpg` - never absolute URLs.
String? resolveImageUrl(String? relativePath) {
  if (relativePath == null || relativePath.isEmpty) return null;
  if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
    return relativePath;
  }
  final path = relativePath.startsWith('/') ? relativePath : '/$relativePath';
  return '${Environment.apiBaseUrl}$path';
}
