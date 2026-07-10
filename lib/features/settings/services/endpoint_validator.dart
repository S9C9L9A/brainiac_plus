/// Outcome of validating a service endpoint typed by the user.
class EndpointValidation {
  /// Normalized URL to store, or null when the field was left empty
  /// (meaning: clear the setting).
  final String? normalized;

  /// Why the input was rejected; null when valid or empty.
  final String? error;

  const EndpointValidation.ok(this.normalized) : error = null;

  const EndpointValidation.cleared() : normalized = null, error = null;

  const EndpointValidation.invalid(this.error) : normalized = null;

  bool get isValid => error == null;
}

/// Normalizes and validates HTTP endpoints entered in settings (Ollama /
/// local LLM server), so a missing scheme or a stray trailing slash typed
/// in the text field cannot silently break every later API call.
class EndpointValidator {
  static final _hostPattern = RegExp(
    r'^[a-zA-Z0-9]([a-zA-Z0-9.\-]*[a-zA-Z0-9])?$',
  );

  EndpointValidation validate(String raw) {
    var input = raw.trim();
    if (input.isEmpty) return const EndpointValidation.cleared();

    // Bare host:port — default to http, the common case for local servers.
    if (!input.contains('://')) input = 'http://$input';

    final uri = Uri.tryParse(input);
    if (uri == null) {
      return const EndpointValidation.invalid('Not a valid URL');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return EndpointValidation.invalid(
        'Unsupported scheme "${uri.scheme}" — use http or https',
      );
    }
    if (uri.host.isEmpty || !_hostPattern.hasMatch(uri.host)) {
      return const EndpointValidation.invalid('Missing or invalid host');
    }

    var normalized = input;
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return EndpointValidation.ok(normalized);
  }
}
