import 'package:flutter/material.dart';

/// Modello per rappresentare un passo del wizard di setup
class SetupStep {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool required;
  bool completed;

  SetupStep({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.required = false,
    this.completed = false,
  });
}

/// Modello per lo stato di configurazione di un servizio
class ServiceConnectionStatus {
  final String serviceName;
  final bool isConnected;
  final Map<String, dynamic>? credentials;
  final DateTime? lastSync;

  ServiceConnectionStatus({
    required this.serviceName,
    this.isConnected = false,
    this.credentials,
    this.lastSync,
  });

  ServiceConnectionStatus copyWith({
    String? serviceName,
    bool? isConnected,
    Map<String, dynamic>? credentials,
    DateTime? lastSync,
  }) {
    return ServiceConnectionStatus(
      serviceName: serviceName ?? this.serviceName,
      isConnected: isConnected ?? this.isConnected,
      credentials: credentials ?? this.credentials,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}
