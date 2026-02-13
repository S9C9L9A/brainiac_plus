import 'package:flutter/material.dart';
import '../../../features/automation/models/automation.dart';
import '../../../features/automation/models/automation_enums.dart';
import '../../../features/automation/models/automation_templates.dart';

/// Pre-built automation templates for browser actions
class BrowserActionTemplates {
  /// Flight search automation template
  static AutomationTemplate get searchFlights => AutomationTemplate(
    id: 'browser_search_flights',
    name: 'Cerca Voli',
    description: 'Apri il browser e cerca voli per le date e destinazioni specificate',
    category: AutomationCategory.productivity,
    service: ServiceProvider.custom,
    isPremium: false,
    tags: ['viaggi', 'voli', 'browser', 'ricerca'],
    requiredConfigurations: [
      'Destinazione',
      'Date di partenza e ritorno',
      'Browser predefinito',
    ],
    exampleSteps: [
      'Prepara i parametri di ricerca (destinazione, date, passeggeri)',
      'Costruisci URL per il motore di ricerca (Google Flights, Skyscanner, Kayak)',
      'Apri il browser predefinito del sistema',
      'Carica la pagina con i risultati della ricerca',
    ],
    configSchema: {
      'destination': {
        'type': 'string',
        'label': 'Destinazione',
        'placeholder': 'Milano',
        'required': true,
      },
      'origin': {
        'type': 'string',
        'label': 'Partenza',
        'placeholder': 'Roma',
        'required': false,
        'default': 'Auto-detect',
      },
      'dateFrom': {
        'type': 'date',
        'label': 'Data partenza',
        'required': true,
      },
      'dateTo': {
        'type': 'date',
        'label': 'Data ritorno',
        'required': false,
      },
      'passengers': {
        'type': 'number',
        'label': 'Passeggeri',
        'default': 1,
        'min': 1,
        'max': 9,
      },
      'cabinClass': {
        'type': 'select',
        'label': 'Classe',
        'options': ['economy', 'premium', 'business', 'first'],
        'default': 'economy',
      },
      'searchEngine': {
        'type': 'select',
        'label': 'Motore di ricerca',
        'options': ['google', 'skyscanner', 'kayak'],
        'default': 'google',
      },
    },
    toAutomation: ({
      String? destination,
      String? origin,
      String? dateFrom,
      String? dateTo,
      int passengers = 1,
      String cabinClass = 'economy',
      String searchEngine = 'google',
      TriggerType triggerType = TriggerType.manual,
      String? cronSchedule,
    }) {
      return Automation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Cerca Voli - $destination',
        description: 'Ricerca voli per $destination dal $dateFrom al $dateTo',
        category: AutomationCategory.productivity,
        service: ServiceProvider.custom,
        preferredMode: AutomationMode.browser,
        triggerType: triggerType,
        status: AutomationStatus.idle,
        config: {
          'actionType': 'searchFlights',
          'destination': destination ?? 'Milano',
          'origin': origin,
          'dateFrom': dateFrom ?? DateTime.now().add(Duration(days: 7)).toIso8601String().split('T')[0],
          'dateTo': dateTo,
          'passengers': passengers,
          'cabinClass': cabinClass,
          'searchEngine': searchEngine,
        },
        cronSchedule: cronSchedule,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        tags: ['viaggi', 'voli', destination ?? 'Milano'],
      );
    },
  );

  /// Generic URL opener template
  static AutomationTemplate get openWebsite => AutomationTemplate(
    id: 'browser_open_url',
    name: 'Apri Sito Web',
    description: 'Apri un URL specifico nel browser predefinito',
    category: AutomationCategory.productivity,
    service: ServiceProvider.custom,
    isPremium: false,
    tags: ['browser', 'url', 'web'],
    requiredConfigurations: ['URL da aprire'],
    exampleSteps: [
      'Valida URL',
      'Apri browser predefinito',
      'Carica la pagina',
    ],
    configSchema: {
      'url': {
        'type': 'string',
        'label': 'URL',
        'placeholder': 'https://example.com',
        'required': true,
      },
    },
    toAutomation: ({
      required String url,
      TriggerType triggerType = TriggerType.manual,
      String? cronSchedule,
    }) {
      return Automation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Apri $url',
        description: 'Apre $url nel browser predefinito',
        category: AutomationCategory.productivity,
        service: ServiceProvider.custom,
        preferredMode: AutomationMode.browser,
        triggerType: triggerType,
        config: {
          'actionType': 'openUrl',
          'url': url,
        },
        cronSchedule: cronSchedule,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        tags: ['web'],
      );
    },
  );

  /// Google search template
  static AutomationTemplate get googleSearch => AutomationTemplate(
    id: 'browser_google_search',
    name: 'Ricerca Google',
    description: 'Esegui una ricerca su Google con parametri specifici',
    category: AutomationCategory.productivity,
    service: ServiceProvider.google,
    isPremium: false,
    tags: ['google', 'ricerca', 'search', 'browser'],
    requiredConfigurations: ['Query di ricerca'],
    exampleSteps: [
      'Prepara query di ricerca',
      'Codifica parametri URL',
      'Apri Google Search',
      'Mostra risultati',
    ],
    configSchema: {
      'query': {
        'type': 'string',
        'label': 'Query di ricerca',
        'placeholder': 'migliori ristoranti Milano',
        'required': true,
      },
    },
    toAutomation: ({
      required String query,
      TriggerType triggerType = TriggerType.manual,
      String? cronSchedule,
    }) {
      return Automation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Cerca: $query',
        description: 'Ricerca Google per: $query',
        category: AutomationCategory.productivity,
        service: ServiceProvider.google,
        preferredMode: AutomationMode.browser,
        triggerType: triggerType,
        config: {
          'actionType': 'googleSearch',
          'query': query,
        },
        cronSchedule: cronSchedule,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        tags: ['google', 'ricerca'],
      );
    },
  );

  /// Get all browser action templates
  static List<AutomationTemplate> get all => [
    searchFlights,
    openWebsite,
    googleSearch,
  ];
}
