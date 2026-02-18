import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/automation.dart';

/// Simulatore di automazioni Facebook
/// Testa il sistema senza richiedere pages_manage_posts
class FacebookAutomationSimulator {
  final String backendUrl;
  final String facebookToken;

  FacebookAutomationSimulator({
    this.backendUrl = 'http://localhost:8080',
    required this.facebookToken,
  });

  /// Simula l'esecuzione di un'automazione
  Future<AutomationSimulationResult> simulateAutomation(Automation automation) async {
    final startTime = DateTime.now();
    final steps = <SimulationStep>[];

    try {
      // Step 1: Verifica token
      steps.add(const SimulationStep(
        name: 'Token Validation',
        status: SimulationStatus.running,
        message: 'Validating Facebook token...',
      ));

      final isValid = await _validateToken();
      steps.last = steps.last.copyWith(
        status: isValid ? SimulationStatus.success : SimulationStatus.failed,
        message: isValid ? 'Token valid ✓' : 'Token invalid ✗',
      );

      if (!isValid) {
        return AutomationSimulationResult(
          success: false,
          steps: steps,
          duration: DateTime.now().difference(startTime),
          error: 'Invalid Facebook token',
        );
      }

      // Step 2: Recupera pagine
      steps.add(const SimulationStep(
        name: 'Fetch Pages',
        status: SimulationStatus.running,
        message: 'Fetching Facebook pages...',
      ));

      final pages = await _fetchPages();
      steps.last = steps.last.copyWith(
        status: SimulationStatus.success,
        message: 'Found ${pages.length} page(s) ✓',
        data: {'pages': pages},
      );

      // Step 3: Simula generazione contenuto
      steps.add(const SimulationStep(
        name: 'Content Generation',
        status: SimulationStatus.running,
        message: 'Generating post content...',
      ));

      final content = _generateContent(automation);
      steps.last = steps.last.copyWith(
        status: SimulationStatus.success,
        message: 'Content ready (${content.length} chars) ✓',
        data: {'content': content},
      );

      // Step 4: SIMULA pubblicazione
      steps.add(const SimulationStep(
        name: 'Publish Simulation',
        status: SimulationStatus.running,
        message: 'Simulating post publication...',
      ));

      await Future.delayed(const Duration(milliseconds: 500));

      steps.last = steps.last.copyWith(
        status: SimulationStatus.success,
        message: '⚠️ SIMULATED: Post would be published ✓',
        data: {
          'simulated': true,
          'would_publish': content,
          'reason': 'pages_manage_posts permission not available',
        },
      );

      return AutomationSimulationResult(
        success: true,
        steps: steps,
        duration: DateTime.now().difference(startTime),
        simulatedPostContent: content,
      );

    } catch (e) {
      steps.add(SimulationStep(
        name: 'Error',
        status: SimulationStatus.failed,
        message: 'Error: $e',
      ));

      return AutomationSimulationResult(
        success: false,
        steps: steps,
        duration: DateTime.now().difference(startTime),
        error: e.toString(),
      );
    }
  }

  Future<bool> _validateToken() async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me?access_token=$facebookToken'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPages() async {
    try {
      final response = await http.get(
        Uri.parse('https://graph.facebook.com/v18.0/me/accounts?access_token=$facebookToken'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['data'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  String _generateContent(Automation automation) {
    final template = automation.config['message_template'] as String? ?? 
        '🧠 BrainiacPlus Automated Post';
    
    String content = template
        .replaceAll('{date}', DateTime.now().toString().split(' ')[0])
        .replaceAll('{time}', TimeOfDay.fromDateTime(DateTime.now()).format(TimeOfDayFormat.H_colon_mm as BuildContext))
        .replaceAll('{automation_name}', automation.name);

    return content;
  }
}

class AutomationSimulationResult {
  final bool success;
  final List<SimulationStep> steps;
  final Duration duration;
  final String? error;
  final String? simulatedPostContent;

  AutomationSimulationResult({
    required this.success,
    required this.steps,
    required this.duration,
    this.error,
    this.simulatedPostContent,
  });
}

class SimulationStep {
  final String name;
  final SimulationStatus status;
  final String message;
  final Map<String, dynamic>? data;

  const SimulationStep({
    required this.name,
    required this.status,
    required this.message,
    this.data,
  });

  SimulationStep copyWith({
    String? name,
    SimulationStatus? status,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return SimulationStep(
      name: name ?? this.name,
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

enum SimulationStatus {
  pending,
  running,
  success,
  failed,
  skipped,
}
