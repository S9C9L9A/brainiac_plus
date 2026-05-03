# 🧪 Testing Agent

**Dominio**: `test/`

---

## 🎯 Responsabilità

- Unit tests per business logic
- Widget tests per UI components
- Integration tests per flows
- E2E tests per scenari completi
- Test coverage reporting

---

## 📁 Files Owned

```
test/
├── README.md                         # Test documentation
├── interactive_service_setup_screen_test.dart
├── template_prefill_test.dart
├── core/
│   └── services/                     # Core service tests
├── e2e/
│   └── automation_flow_test.dart     # End-to-end tests
├── features/
│   ├── ai_assistant/                 # AI tests
│   ├── automation/                   # Automation tests
│   ├── dashboard/                    # Dashboard tests
│   └── terminal/                     # Terminal tests
├── integration/
│   └── backend_integration_test.dart # Backend integration
└── unit/
    ├── models/                       # Model tests
    └── providers/                    # Provider tests
```

---

## 🔧 Capabilities

- ✅ Scrivere nuovi test
- ✅ Aggiornare test esistenti
- ✅ Mock services e providers
- ✅ Test fixtures e helpers
- ✅ CI/CD test configuration

---

## 📋 Test Categories

| Category | Path | Command |
|----------|------|---------|
| Unit | `test/unit/` | `flutter test test/unit/` |
| Widget | `test/features/` | `flutter test test/features/` |
| Integration | `test/integration/` | `flutter test test/integration/` |
| E2E | `test/e2e/` | `flutter test integration_test/` |
| All | `test/` | `flutter test` |

---

## 🔗 Dipendenze

- Tutti gli altri agenti (test coverage)
- `core.agent.md` → Mock platform services

---

## 📖 Esempio Test

```dart
// Unit test
void main() {
  group('AutomationTask', () {
    test('should serialize to JSON', () {
      final task = AutomationTask(
        id: '1',
        name: 'Test Task',
        type: TaskType.shellCommand,
      );
      
      expect(task.toJson(), isA<Map<String, dynamic>>());
      expect(task.toJson()['name'], equals('Test Task'));
    });
  });
}

// Widget test
testWidgets('Dashboard shows metrics', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        systemMetricsProvider.overrideWith(
          (ref) => FakeMetricsNotifier(),
        ),
      ],
      child: MaterialApp(home: DashboardScreen()),
    ),
  );
  
  expect(find.text('CPU'), findsOneWidget);
  expect(find.text('RAM'), findsOneWidget);
});
```

---

## 🚀 Comandi

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/unit/models/automation_task_test.dart

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

---

## 📊 Coverage Goals

| Module | Target | Current |
|--------|--------|---------|
| Core | 80% | TBD |
| Features | 70% | TBD |
| Models | 90% | TBD |
| Providers | 75% | TBD |
