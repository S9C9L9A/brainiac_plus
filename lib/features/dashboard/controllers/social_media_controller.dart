import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/social_media_service.dart';
import '../../settings/models/extended_settings.dart';
import '../../settings/providers/extended_settings_provider.dart';

/// Provider per i servizi social media
final socialMediaServicesProvider =
    StateNotifierProvider<SocialMediaServicesController, SocialMediaServicesState>((ref) {
  return SocialMediaServicesController(ref);
});

/// State per i servizi social
class SocialMediaServicesState {
  final List<SocialMediaService> services;
  final bool isLoading;
  final String? error;

  const SocialMediaServicesState({
    this.services = const [],
    this.isLoading = false,
    this.error,
  });

  SocialMediaServicesState copyWith({
    List<SocialMediaService>? services,
    bool? isLoading,
    String? error,
  }) {
    return SocialMediaServicesState(
      services: services ?? this.services,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Ottieni solo i servizi configurati
  List<SocialMediaService> get configuredServices =>
      services.where((s) => s.isConfigured).toList();

  /// Ottieni solo i servizi attivi
  List<SocialMediaService> get activeServices =>
      services.where((s) => s.isActive).toList();
}

/// Controller per gestire i servizi social
class SocialMediaServicesController extends StateNotifier<SocialMediaServicesState> {
  SocialMediaServicesController(this._ref) : super(const SocialMediaServicesState()) {
    _syncFromSettings(_ref.read(extendedSettingsProvider));
    _ref.listen<ExtendedAppSettings>(
      extendedSettingsProvider,
      (previous, next) => _syncFromSettings(next),
    );
  }

  final Ref _ref;
  final String backendUrl = 'http://localhost:8080';

  /// Allinea i servizi alla configurazione salvata nelle settings
  void _syncFromSettings(ExtendedAppSettings settings) {
    final services = <SocialMediaService>[];

    if (settings.hasFacebookAuth) {
      services.add(
        SocialMediaService(
          id: 'fb_1',
          platform: SocialPlatform.facebook,
          name: settings.facebookUserId ?? 'Facebook',
          pageId: settings.facebookUserId,
          accessToken: settings.facebookAccessToken,
          isConfigured: true,
          isActive: true,
          lastSync: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      );
    }

    if (settings.hasInstagramAuth) {
      services.add(
        SocialMediaService(
          id: 'ig_1',
          platform: SocialPlatform.instagram,
          name: settings.instagramUsername ?? 'Instagram',
          accessToken: settings.instagramAccessToken,
          isConfigured: true,
          isActive: true,
          lastSync: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      );
    }

    state = state.copyWith(services: services, isLoading: false, error: null);
  }

  /// Carica tutti i servizi configurati
  Future<void> loadServices() async {
    state = state.copyWith(isLoading: true, error: null);
    _syncFromSettings(_ref.read(extendedSettingsProvider));
  }

  /// Sincronizza le metriche di un servizio
  Future<void> syncService(String serviceId) async {
    final serviceIndex = state.services.indexWhere((s) => s.id == serviceId);
    if (serviceIndex == -1) return;

    final service = state.services[serviceIndex];
    
    try {
      SocialMediaMetrics? metrics;

      switch (service.platform) {
        case SocialPlatform.facebook:
          metrics = await _syncFacebookMetrics(service);
          break;
        case SocialPlatform.instagram:
          metrics = await _syncInstagramMetrics(service);
          break;
        case SocialPlatform.youtube:
          metrics = await _syncYouTubeMetrics(service);
          break;
        default:
          break;
      }

      if (metrics != null) {
        final updatedService = service.copyWith(
          metrics: metrics,
          lastSync: DateTime.now(),
        );

        final updatedServices = List<SocialMediaService>.from(state.services);
        updatedServices[serviceIndex] = updatedService;

        state = state.copyWith(services: updatedServices);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to sync: $e');
    }
  }

  /// Sincronizza metriche Facebook
  Future<SocialMediaMetrics?> _syncFacebookMetrics(SocialMediaService service) async {
    if (service.pageId == null || service.accessToken == null) return null;

    try {
      final response = await http.get(
        Uri.parse(
          'https://graph.facebook.com/v18.0/${service.pageId}?'
          'fields=id,name,followers_count,fan_count&'
          'access_token=${service.accessToken}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Recupera anche gli album per contare le foto
        final albumsResponse = await http.get(
          Uri.parse(
            'https://graph.facebook.com/v18.0/${service.pageId}/albums?'
            'fields=count&'
            'access_token=${service.accessToken}',
          ),
        );

        int photoCount = 0;
        if (albumsResponse.statusCode == 200) {
          final albumsData = json.decode(albumsResponse.body);
          for (var album in (albumsData['data'] as List? ?? [])) {
            photoCount += (album['count'] as int? ?? 0);
          }
        }

        return SocialMediaMetrics(
          followers: data['followers_count'] as int? ?? 0,
          posts: photoCount,
          engagement: 0, // Richiederebbe permessi aggiuntivi
          likes: 0,
          comments: 0,
          shares: 0,
          engagementRate: 0.0,
          extra: {
            'fan_count': data['fan_count'],
          },
        );
      }
    } catch (e) {
      print('Error syncing Facebook metrics: $e');
    }

    return null;
  }

  /// Sincronizza metriche Instagram (placeholder)
  Future<SocialMediaMetrics?> _syncInstagramMetrics(SocialMediaService service) async {
    // TODO: Implementare sync Instagram quando configurato
    return null;
  }

  /// Sincronizza metriche YouTube (placeholder)
  Future<SocialMediaMetrics?> _syncYouTubeMetrics(SocialMediaService service) async {
    // TODO: Implementare sync YouTube quando configurato
    return null;
  }

  /// Aggiungi un nuovo servizio
  Future<void> addService(SocialMediaService service) async {
    final services = [...state.services, service];
    state = state.copyWith(services: services);
    
    // TODO: Salvare nel database
  }

  /// Rimuovi un servizio
  Future<void> removeService(String serviceId) async {
    final services = state.services.where((s) => s.id != serviceId).toList();
    state = state.copyWith(services: services);
    
    // TODO: Rimuovere dal database
  }

  /// Attiva/disattiva un servizio
  Future<void> toggleService(String serviceId, bool active) async {
    final serviceIndex = state.services.indexWhere((s) => s.id == serviceId);
    if (serviceIndex == -1) return;

    final updatedService = state.services[serviceIndex].copyWith(isActive: active);
    final updatedServices = List<SocialMediaService>.from(state.services);
    updatedServices[serviceIndex] = updatedService;

    state = state.copyWith(services: updatedServices);
    
    // TODO: Aggiornare nel database
  }

  /// Sincronizza tutti i servizi attivi
  Future<void> syncAllServices() async {
    for (var service in state.activeServices) {
      await syncService(service.id);
    }
  }
}