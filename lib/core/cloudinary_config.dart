/// Cloudinary configuration for PakSale image storage.
///
/// Only PUBLIC values live here. The API key and API secret are never used by
/// the app and must never be added to this file or committed to the repo.
/// The app uploads through an "unsigned" upload preset, so no secret is needed.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Cloudinary cloud name (public).
  static const String cloudName = 'ivzsoyga';

  /// Name of the unsigned upload preset created in the Cloudinary dashboard.
  static const String uploadPreset = 'paksale_unsigned';

  /// Media Library folder where uploaded assets are placed.
  static const String folder = 'paksale/products';

  /// Unsigned image upload endpoint.
  static String get uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Maximum time to wait for an upload before failing.
  static const Duration timeout = Duration(seconds: 60);
}
