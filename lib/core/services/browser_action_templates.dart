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
    requiredFields: [
      'Destinazione',
      'Date di partenza e ritorno',
      'Browser predefinito',
    ],
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
    requiredFields: ['URL da aprire'],
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
    requiredFields: ['Query di ricerca'],
  );

  /// Get all browser action templates
  static List<AutomationTemplate> get all => [
    searchFlights,
    openWebsite,
    googleSearch,
  ];
}
