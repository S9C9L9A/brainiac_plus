import 'package:url_launcher/url_launcher.dart';
import '../../features/automation/models/automation.dart';

/// Service for browser-based automation actions
class BrowserActionsService {
  /// Execute a browser action based on automation configuration
  Future<Map<String, dynamic>> executeAction(Automation automation) async {
    final actionType = automation.config['actionType'] as String?;
    
    switch (actionType) {
      case 'searchFlights':
        return await _searchFlights(automation.config);
      case 'openUrl':
        return await _openUrl(automation.config);
      case 'googleSearch':
        return await _googleSearch(automation.config);
      default:
        throw UnimplementedError('Action type $actionType not implemented');
    }
  }

  /// Search for flights with parameters from config
  Future<Map<String, dynamic>> _searchFlights(Map<String, dynamic> config) async {
    final destination = config['destination'] as String? ?? 'Milano';
    final dateFrom = config['dateFrom'] as String? ?? '2026-02-23';
    final dateTo = config['dateTo'] as String? ?? '2026-02-26';
    final origin = config['origin'] as String? ?? 'Roma';
    final passengers = config['passengers'] as int? ?? 1;
    final cabinClass = config['cabinClass'] as String? ?? 'economy';
    
    // Multiple flight search engines support
    final searchEngine = config['searchEngine'] as String? ?? 'google';
    
    final String url;
    switch (searchEngine) {
      case 'google':
        // Google Flights URL format
        url = _buildGoogleFlightsUrl(
          origin: origin,
          destination: destination,
          dateFrom: dateFrom,
          dateTo: dateTo,
          passengers: passengers,
          cabinClass: cabinClass,
        );
        break;
      
      case 'skyscanner':
        // Skyscanner URL format
        url = _buildSkyscannerUrl(
          origin: origin,
          destination: destination,
          dateFrom: dateFrom,
          dateTo: dateTo,
          passengers: passengers,
          cabinClass: cabinClass,
        );
        break;
      
      case 'kayak':
        // Kayak URL format
        url = _buildKayakUrl(
          origin: origin,
          destination: destination,
          dateFrom: dateFrom,
          dateTo: dateTo,
          passengers: passengers,
          cabinClass: cabinClass,
        );
        break;
      
      default:
        url = _buildGoogleFlightsUrl(
          origin: origin,
          destination: destination,
          dateFrom: dateFrom,
          dateTo: dateTo,
          passengers: passengers,
          cabinClass: cabinClass,
        );
    }
    
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    
    if (!launched) {
      throw Exception('Failed to launch browser with URL: $url');
    }
    
    return {
      'success': true,
      'url': url,
      'searchEngine': searchEngine,
      'params': {
        'origin': origin,
        'destination': destination,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'passengers': passengers,
        'cabinClass': cabinClass,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Build Google Flights URL
  String _buildGoogleFlightsUrl({
    required String origin,
    required String destination,
    required String dateFrom,
    required String dateTo,
    required int passengers,
    required String cabinClass,
  }) {
    // Google Flights format: https://www.google.com/travel/flights
    // Example: https://www.google.com/travel/flights?q=Flights%20to%20Milan%20from%20Rome%20on%202026-02-23%20through%202026-02-26
    
    final query = Uri.encodeComponent(
      'Flights to $destination from $origin on $dateFrom through $dateTo for $passengers passenger(s)'
    );
    
    return 'https://www.google.com/travel/flights?q=$query';
  }

  /// Build Skyscanner URL
  String _buildSkyscannerUrl({
    required String origin,
    required String destination,
    required String dateFrom,
    required String dateTo,
    required int passengers,
    required String cabinClass,
  }) {
    // Skyscanner format
    // Convert dates from YYYY-MM-DD to YYMMDD
    final departDate = dateFrom.replaceAll('-', '').substring(2);
    final returnDate = dateTo.replaceAll('-', '').substring(2);
    
    // Get airport codes (simplified - in production use API to convert city to IATA)
    final originCode = _getCityCode(origin);
    final destCode = _getCityCode(destination);
    
    return 'https://www.skyscanner.it/transport/flights/$originCode/$destCode/$departDate/$returnDate/?adults=$passengers&cabinclass=${cabinClass.toLowerCase()}';
  }

  /// Build Kayak URL
  String _buildKayakUrl({
    required String origin,
    required String destination,
    required String dateFrom,
    required String dateTo,
    required int passengers,
    required String cabinClass,
  }) {
    // Kayak format
    final originCode = _getCityCode(origin);
    final destCode = _getCityCode(destination);
    
    return 'https://www.kayak.it/flights/$originCode-$destCode/$dateFrom/$dateTo/$passengers'+'adults?sort=bestflight_a&fs=cabinclass=${_getKayakCabinClass(cabinClass)}';
  }

  /// Open a generic URL
  Future<Map<String, dynamic>> _openUrl(Map<String, dynamic> config) async {
    final url = config['url'] as String?;
    
    if (url == null || url.isEmpty) {
      throw ArgumentError('URL is required for openUrl action');
    }
    
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    
    if (!launched) {
      throw Exception('Failed to launch URL: $url');
    }
    
    return {
      'success': true,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Perform a Google search
  Future<Map<String, dynamic>> _googleSearch(Map<String, dynamic> config) async {
    final query = config['query'] as String?;
    
    if (query == null || query.isEmpty) {
      throw ArgumentError('Query is required for googleSearch action');
    }
    
    final encodedQuery = Uri.encodeComponent(query);
    final url = 'https://www.google.com/search?q=$encodedQuery';
    
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    
    if (!launched) {
      throw Exception('Failed to launch Google search');
    }
    
    return {
      'success': true,
      'query': query,
      'url': url,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get simplified city/airport code mapping
  /// TODO: In production, use a proper IATA code API or database
  String _getCityCode(String city) {
    final codes = {
      'milano': 'MXP',
      'milan': 'MXP',
      'roma': 'FCO',
      'rome': 'FCO',
      'venezia': 'VCE',
      'venice': 'VCE',
      'firenze': 'FLR',
      'florence': 'FLR',
      'napoli': 'NAP',
      'naples': 'NAP',
      'bologna': 'BLQ',
      'torino': 'TRN',
      'turin': 'TRN',
      'palermo': 'PMO',
      'catania': 'CTA',
      'bari': 'BRI',
      'london': 'LON',
      'londra': 'LON',
      'paris': 'PAR',
      'parigi': 'PAR',
      'new york': 'NYC',
      'barcelona': 'BCN',
      'madrid': 'MAD',
      'berlin': 'BER',
      'berlino': 'BER',
    };
    
    return codes[city.toLowerCase()] ?? city.toUpperCase().substring(0, 3);
  }

  /// Convert cabin class to Kayak format
  String _getKayakCabinClass(String cabinClass) {
    switch (cabinClass.toLowerCase()) {
      case 'economy':
        return 'e';
      case 'premium':
      case 'premium economy':
        return 'p';
      case 'business':
        return 'b';
      case 'first':
      case 'first class':
        return 'f';
      default:
        return 'e';
    }
  }
}
