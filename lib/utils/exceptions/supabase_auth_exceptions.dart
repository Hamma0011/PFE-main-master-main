/// Custom exception class to handle Supabase Auth errors.
class SupabaseAuthException implements Exception {
  /// The error message from Supabase.
  final String message;

  /// Optional HTTP status code.
  final int? statusCode;

  /// Constructor
  SupabaseAuthException(this.message, {this.statusCode});

  /// Get a user-friendly error message.
  String get friendlyMessage {
    final normalized = message.toLowerCase();

    if (normalized.contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (normalized.contains('user already registered')) {
      return 'This email is already registered. Please use a different email or log in.';
    }
    if (normalized.contains('password')) {
      return 'Password must meet the required strength.';
    }
    if (normalized.contains('refresh_token_not_found')) {
      return 'Your session has expired. Please log in again.';
    }
    if (normalized.contains('over request limit')) {
      return 'Too many requests. Please wait and try again later.';
    }
    if (statusCode == 500) {
      return 'An internal server error occurred. Please try again later.';
    }

    return message; // Fallback to original Supabase message
  }

  @override
  String toString() => friendlyMessage;
}
