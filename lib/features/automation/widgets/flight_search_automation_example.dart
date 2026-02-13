import 'package:flutter/material.dart';
import '../../../core/services/browser_action_templates.dart';
import '../../../core/services/automation_engine.dart';
import '../models/automation_enums.dart';

/// Example widget showing how to create and execute a flight search automation
class FlightSearchAutomationExample extends StatefulWidget {
  const FlightSearchAutomationExample({super.key});

  @override
  State<FlightSearchAutomationExample> createState() => _FlightSearchAutomationExampleState();
}

class _FlightSearchAutomationExampleState extends State<FlightSearchAutomationExample> {
  final _formKey = GlobalKey<FormState>();
  
  // Form fields
  String _destination = 'Milano';
  String? _origin;
  DateTime _dateFrom = DateTime.now().add(const Duration(days: 7));
  DateTime? _dateTo;
  int _passengers = 1;
  String _cabinClass = 'economy';
  String _searchEngine = 'google';
  TriggerType _triggerType = TriggerType.manual;
  String? _cronSchedule;
  
  final _engine = AutomationEngine();
  bool _isExecuting = false;
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✈️ Cerca Voli - Automazione'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              // Destination
              _buildTextField(
                label: 'Destinazione',
                icon: Icons.flight_land,
                initialValue: _destination,
                onChanged: (value) => _destination = value,
              ),
              const SizedBox(height: 16),
              
              // Origin (optional)
              _buildTextField(
                label: 'Partenza (opzionale)',
                icon: Icons.flight_takeoff,
                initialValue: _origin,
                onChanged: (value) => _origin = value.isEmpty ? null : value,
                required: false,
              ),
              const SizedBox(height: 16),
              
              // Date From
              _buildDateField(
                label: 'Data partenza',
                date: _dateFrom,
                onChanged: (date) => setState(() => _dateFrom = date),
              ),
              const SizedBox(height: 16),
              
              // Date To (optional)
              _buildDateField(
                label: 'Data ritorno (opzionale)',
                date: _dateTo,
                onChanged: (date) => setState(() => _dateTo = date),
                required: false,
              ),
              const SizedBox(height: 16),
              
              // Passengers
              _buildNumberField(
                label: 'Passeggeri',
                icon: Icons.person,
                value: _passengers,
                onChanged: (value) => setState(() => _passengers = value),
              ),
              const SizedBox(height: 16),
              
              // Cabin Class
              _buildDropdown(
                label: 'Classe',
                icon: Icons.airline_seat_recline_extra,
                value: _cabinClass,
                items: const ['economy', 'premium', 'business', 'first'],
                onChanged: (value) => setState(() => _cabinClass = value!),
              ),
              const SizedBox(height: 16),
              
              // Search Engine
              _buildDropdown(
                label: 'Motore di ricerca',
                icon: Icons.search,
                value: _searchEngine,
                items: const ['google', 'skyscanner', 'kayak'],
                onChanged: (value) => setState(() => _searchEngine = value!),
              ),
              const SizedBox(height: 24),
              
              // Trigger Type
              _buildTriggerTypeSelector(),
              const SizedBox(height: 24),
              
              // Execute button
              ElevatedButton.icon(
                onPressed: _isExecuting ? null : _executeAutomation,
                icon: _isExecuting 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(_isExecuting ? 'Esecuzione...' : 'Cerca Voli Ora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              
              // Result
              if (_result != null) ...[
                const SizedBox(height: 24),
                _buildResultCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Come funziona',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Questa automazione aprirà il browser predefinito del sistema e cercherà voli con i parametri specificati. Supporta Google Flights, Skyscanner e Kayak.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? initialValue,
    required Function(String) onChanged,
    bool required = true,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: required
          ? (value) => value?.isEmpty ?? true ? 'Campo obbligatorio' : null
          : null,
    );
  }

  Widget _buildDateField({
    required String label,
    DateTime? date,
    required Function(DateTime) onChanged,
    bool required = true,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Seleziona data',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required IconData icon,
    required int value,
    required Function(int) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
              border: const OutlineInputBorder(),
            ),
            child: Text('$value'),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onChanged(value + 1),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTriggerTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quando eseguire',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        RadioListTile<TriggerType>(
          title: const Text('Manuale (click)'),
          value: TriggerType.manual,
          groupValue: _triggerType,
          onChanged: (value) => setState(() {
            _triggerType = value!;
            _cronSchedule = null;
          }),
        ),
        RadioListTile<TriggerType>(
          title: const Text('Programmato'),
          subtitle: const Text('Esempio: ogni giorno alle 9:00'),
          value: TriggerType.scheduled,
          groupValue: _triggerType,
          onChanged: (value) => setState(() {
            _triggerType = value!;
            _cronSchedule = '0 9 * * *'; // 9 AM every day
          }),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Esecuzione completata!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_result!),
          ],
        ),
      ),
    );
  }

  Future<void> _executeAutomation() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isExecuting = true;
      _result = null;
    });

    try {
      // Create automation from template
      final automation = BrowserActionTemplates.searchFlights.toAutomation(
        destination: _destination,
        origin: _origin,
        dateFrom: '${_dateFrom.year}-${_dateFrom.month.toString().padLeft(2, '0')}-${_dateFrom.day.toString().padLeft(2, '0')}',
        dateTo: _dateTo != null 
            ? '${_dateTo!.year}-${_dateTo!.month.toString().padLeft(2, '0')}-${_dateTo!.day.toString().padLeft(2, '0')}'
            : null,
        passengers: _passengers,
        cabinClass: _cabinClass,
        searchEngine: _searchEngine,
        triggerType: _triggerType,
        cronSchedule: _cronSchedule,
      );

      // Execute automation
      final log = await _engine.execute(automation);

      setState(() {
        if (log.isSuccess) {
          final url = log.result?['url'] ?? 'N/A';
          _result = 'Browser aperto con successo!\nURL: $url\nMotore: $_searchEngine';
        } else {
          _result = 'Errore: ${log.errorMessage}';
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Errore: $e';
      });
    } finally {
      setState(() {
        _isExecuting = false;
      });
    }
  }
}
