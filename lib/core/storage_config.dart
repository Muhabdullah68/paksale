/// Selects which backing store image uploads go to.
///
/// The Firebase Storage code path is intentionally kept in
/// `lib/services/storage_service.dart` so that when the Firebase **Blaze**
/// plan is re-enabled you can switch back by changing the value below to
/// [StorageBackend.firebase] — a one-line change, no other code changes needed.
enum StorageBackend { cloudinary, firebase }

/// Active storage backend for the whole app (mobile + web share this).
const StorageBackend activeStorageBackend = StorageBackend.cloudinary;
