# 🏗️ Data Layer - Repository Pattern

## Arquitetura Implementada

```
┌─────────────────────────────────────────────┐
│          Presentation Layer (UI)             │
│         pages/ widgets/ dialogs/             │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│        Application Layer (State)             │
│          AppState (Provider)                 │
│         usa: Repositories                    │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│          Domain Layer                        │
│     domain/repositories/ (interfaces)        │
│     models/ (entities)                       │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│          Data Layer                          │
│   data/repositories/ (implementations)       │
│   data/datasources/ (API calls)              │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│          External APIs                       │
│          Supabase REST API                   │
└──────────────────────────────────────────────┘
```

---

## 📁 Estrutura de Ficheiros

```
lib/
├── core/
│   └── di/
│       └── repository_provider.dart      # Dependency Injection
├── domain/
│   └── repositories/                     # Repository Interfaces
│       ├── egg_repository.dart
│       ├── expense_repository.dart
│       └── vet_repository.dart
├── data/
│   ├── datasources/
│   │   └── remote/                       # API Calls (Supabase)
│   │       ├── egg_remote_datasource.dart
│   │       ├── expense_remote_datasource.dart
│   │       └── vet_remote_datasource.dart
│   └── repositories/                     # Repository Implementations
│       ├── egg_repository_impl.dart
│       ├── expense_repository_impl.dart
│       └── vet_repository_impl.dart
└── models/                               # Domain Entities
    ├── daily_egg_record.dart
    ├── expense.dart
    └── vet_record.dart
```

---

## 🎯 Como Usar os Repositories

### 1. Inicializar no Bootstrap

```dart
// lib/app/app_bootstrap.dart
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Inicializar Repositories
  RepositoryProvider.instance.initialize();
}
```

### 2. Usar no AppState

```dart
// lib/state/app_state.dart
import '../core/di/repository_provider.dart';
import '../domain/repositories/egg_repository.dart';

class AppState extends ChangeNotifier {
  final EggRepository _eggRepository = RepositoryProvider.instance.eggRepository;
  final ExpenseRepository _expenseRepository = RepositoryProvider.instance.expenseRepository;
  final VetRepository _vetRepository = RepositoryProvider.instance.vetRepository;

  List<DailyEggRecord> _records = [];

  // Carregar registos do Supabase
  Future<void> loadRecords() async {
    _records = await _eggRepository.getAll();
    notifyListeners();
  }

  // Guardar registo no Supabase
  Future<void> saveRecord(DailyEggRecord record) async {
    final saved = await _eggRepository.save(record);
    _records.add(saved);
    notifyListeners();
  }
}
```

### 3. Usar em Widgets/Pages

```dart
// Usando Provider
final appState = Provider.of<AppState>(context);

// Carregar dados
await appState.loadRecords();

// Guardar dados
await appState.saveRecord(newRecord);
```

---

## 📦 Repository Pattern - Vantagens

### 1. **Abstração**
- UI não precisa saber de onde vêm os dados (API, cache, etc.)
- Interfaces definem contratos claros

### 2. **Testabilidade**
- Fácil criar mocks dos repositories para testes
- Testes unitários sem dependências externas

### 3. **Manutenibilidade**
- Trocar de Supabase para outro backend: só alterar implementations
- Lógica de negócio separada da lógica de dados

### 4. **Reutilização**
- Mesma interface pode ter múltiplas implementações
- Ex: `EggRepositoryImpl` (Supabase) + `EggRepositoryCache` (Hive)

---

## 🔄 Fluxo de Dados

### Exemplo: Guardar um registo de ovos

```
1. User toca em "Guardar" no Dialog
   ↓
2. Dialog chama: appState.saveRecord(record)
   ↓
3. AppState chama: _eggRepository.save(record)
   ↓
4. EggRepositoryImpl (implementation) chama: _remoteDatasource.create(record)
   ↓
5. EggRemoteDatasource faz POST para Supabase API
   ↓
6. Supabase valida RLS e guarda na base de dados
   ↓
7. Supabase retorna o record criado com ID
   ↓
8. Record sobe pela stack até AppState
   ↓
9. AppState actualiza _records e chama notifyListeners()
   ↓
10. UI actualiza automaticamente (Provider)
```

---

## 🧪 Como Testar

### Testar Datasources (integração)
```dart
test('EggRemoteDatasource cria registo', () async {
  final datasource = EggRemoteDatasource(supabaseClient);

  final record = DailyEggRecord(...);
  final result = await datasource.create(record);

  expect(result.id, isNotEmpty);
});
```

### Testar Repositories (unitário com mock)
```dart
test('EggRepository guarda registo', () async {
  final mockDatasource = MockEggRemoteDatasource();
  final repository = EggRepositoryImpl(mockDatasource);

  when(mockDatasource.create(any)).thenAnswer((_) async => mockRecord);

  final result = await repository.save(record);

  expect(result, equals(mockRecord));
  verify(mockDatasource.create(record)).called(1);
});
```

---

## 🚀 Próximos Passos

### 1. **Migrar AppState**
- Trocar mock data por chamadas aos repositories
- Adicionar loading states
- Tratar erros

### 2. **Adicionar Cache Local (Hive)**
- Criar `LocalDatasource` para cada entidade
- Implementar sync strategy (online/offline)
- Conflict resolution

### 3. **Migrar para BLoC** (opcional)
- Substituir Provider por BLoC/Cubit
- Estados mais claros (Loading, Success, Error)
- Melhor separação de responsabilidades

---

## 📚 Referências

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Repository Pattern](https://docs.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-design)
- [Supabase Dart Client](https://supabase.com/docs/reference/dart/introduction)
