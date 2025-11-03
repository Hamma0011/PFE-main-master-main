/// Custom exception class to handle various Firebase-related errors.
class SupabaseException implements Exception {
  /// The error code associated with the exception.
  final String code;

  /// Constructor that takes an error code.
  SupabaseException(this.code);

  /// Get the corresponding error message based on the error code.
  String get message {
    switch (code) {
      case '23505':
        return 'Category already exists';

      default:
        return 'An unexpected Supabase error occurred. Please try again.';
    }
  }
}
