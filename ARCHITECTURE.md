# 🏗️ HCKEgg Lite - Arquitetura & Setup Guide

## ✅ O que foi implementado

Implementamos uma **Clean Architecture completa com Repository Pattern** integrada com **Supabase** como backend.

### 📦 Estrutura Criada

```
lib/
├── core/di/                              # Dependency Injection
│   └── repository_provider.dart          # Singleton para repositories
├── domain/repositories/                  # Interfaces (contratos)
│   ├── egg_repository.dart
│   ├── expense_repository.dart
│   └── vet_repository.dart
├── data/
│   ├── datasources/remote/               # API calls (Supabase)
│   │   ├── egg_remote_datasource.dart
│   │   ├── expense_remote_datasource.dart
│   │   └── vet_remote_datasource.dart
│   ├── repositories/                     # Implementações
│   │   ├── egg_repository_impl.dart
│   │   ├── expense_repository_impl.dart
│   │   └── vet_repository_impl.dart
│   └── README.md                         # Documentação da arquitetura
└── supabase/
    ├── schema.sql                        # Schema SQL completo
    └── README.md                         # Instruções de setup
```

---

## 🚀 Próximos Passos (IMPORTANTE!)

### 1️⃣ Executar o Schema SQL no Supabase

**OBRIGATÓRIO** antes de usar a app:

1. Aceda ao [Supabase Dashboard](https://supabase.com)
2. Selecione o projeto HCKEgg Lite
3. Vá a **SQL Editor** → **New Query**
4. Copie **TODO** o conteúdo de `supabase/schema.sql`
5. Cole e clique em **Run**
6. Verifique em **Table Editor** se as 3 tabelas foram criadas:
   - ✅ `daily_egg_records`
   - ✅ `expenses`
   - ✅ `vet_records`

📖 **Instruções detalhadas:** `supabase/README.md`

---

### 2️⃣ Inicializar Repositories no Bootstrap

Adicione ao `lib/app/app_bootstrap.dart`:

```dart
import '../core/di/repository_provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ... código existente (Supabase.initialize) ...

  // ✨ NOVO: Inicializar Repositories
  RepositoryProvider.instance.initialize();
}
```

---

### 3️⃣ Migrar AppState para usar Repositories

**Actualmente:** AppState usa mock data (gerada localmente)
**Objectivo:** AppState deve usar repositories para buscar/guardar dados no Supabase

#### Exemplo de migração:

**ANTES (mock data):**
```dart
class AppState extends ChangeNotifier {
  final List<DailyEggRecord> _records = _generateMockData();

  List<DailyEggRecord> get records => List.unmodifiable(_records);
}
```

**DEPOIS (com repositories):**
```dart
import '../core/di/repository_provider.dart';
import '../domain/repositories/egg_repository.dart';

class AppState extends ChangeNotifier {
  final EggRepository _eggRepository = RepositoryProvider.instance.eggRepository;

  List<DailyEggRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  // Estado
  List<DailyEggRecord> get records => List.unmodifiable(_records);
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Carregar registos do Supabase
  Future<void> loadRecords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _eggRepository.getAll();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Guardar registo
  Future<void> saveRecord(DailyEggRecord record) async {
    try {
      final saved = await _eggRepository.save(record);
      // Actualizar lista local
      final index = _records.indexWhere((r) => r.id == saved.id);
      if (index != -1) {
        _records[index] = saved;
      } else {
        _records.insert(0, saved);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Eliminar registo
  Future<void> deleteRecord(String id) async {
    try {
      await _eggRepository.deleteById(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
```

#### Fazer o mesmo para:
- ✅ **Expenses** → usar `ExpenseRepository`
- ✅ **Vet Records** → usar `VetRepository`

📖 **Exemplos completos:** `lib/data/README.md`

---

### 4️⃣ Actualizar UI para mostrar Loading/Error

Adicione estados de loading nos widgets:

```dart
Widget build(BuildContext context) {
  final appState = Provider.of<AppState>(context);

  if (appState.isLoading) {
    return Center(child: CircularProgressIndicator());
  }

  if (appState.error != null) {
    return Center(
      child: Column(
        children: [
          Text('Erro: ${appState.error}'),
          ElevatedButton(
            onPressed: () => appState.loadRecords(),
            child: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  // ... UI normal ...
}
```

---

### 5️⃣ Chamar loadRecords() quando a app inicia

No `main.dart` ou `auth_gate.dart`, após login:

```dart
// Após login bem-sucedido
final appState = Provider.of<AppState>(context, listen: false);
await appState.loadRecords();
```

---

## 🎯 Vantagens da Nova Arquitetura

### ✅ Antes (Mock Data)
- ❌ Dados perdidos ao fechar a app
- ❌ Sem sincronização entre dispositivos
- ❌ Sem backup
- ❌ Difícil de testar
- ❌ Lógica de dados misturada com UI

### ✅ Depois (Repository Pattern + Supabase)
- ✅ Dados persistentes na cloud
- ✅ Sincronização automática
- ✅ Backup automático
- ✅ Fácil de testar (mocks)
- ✅ Separação clara de responsabilidades
- ✅ Segurança (Row Level Security)
- ✅ Multi-utilizador (cada user vê só os seus dados)

---

## 📊 Fluxo de Dados

```
User Interface (Pages/Widgets)
         ↕
   AppState (Provider)
         ↕
    Repositories (interfaces)
         ↕
Repository Implementations
         ↕
    Remote Datasources
         ↕
   Supabase REST API
         ↕
  PostgreSQL Database
```

---

## 🔐 Segurança (Row Level Security)

Todas as tabelas têm **RLS** activado:
- ✅ Users só vêem os **seus próprios dados**
- ✅ Impossível aceder a dados de outros users
- ✅ `user_id` automaticamente adicionado pelo Supabase

---

## 🧪 Como Testar

### Testar manualmente no Supabase:

```sql
-- Ver os seus dados
SELECT * FROM daily_egg_records;
SELECT * FROM expenses;
SELECT * FROM vet_records;

-- Inserir teste
INSERT INTO daily_egg_records (date, eggs_collected, eggs_sold, eggs_consumed, price_per_egg)
VALUES (CURRENT_DATE, 12, 10, 2, 0.50);
```

### Testar na app:
1. Login
2. Adicionar um registo de ovos
3. Fechar a app
4. Abrir novamente → dados devem estar lá!
5. Verificar no Supabase Table Editor

---

## 📚 Documentação Adicional

- **`supabase/README.md`** - Setup da base de dados
- **`lib/data/README.md`** - Guia da arquitetura e exemplos de código
- **`supabase/schema.sql`** - Schema SQL completo com comentários

---

## 🆘 Troubleshooting

### Erro: "Database error: permission denied"
→ RLS não configurado. Execute `supabase/schema.sql` completo.

### Erro: "relation does not exist"
→ Tabelas não criadas. Execute `supabase/schema.sql`.

### Dados não aparecem
→ Verifique se `loadRecords()` está a ser chamado após login.

### "Repository not initialized"
→ Adicione `RepositoryProvider.instance.initialize()` no bootstrap.

---

## 🔄 Roadmap Futuro (Opcional)

1. **Offline Support**
   - Adicionar Hive para cache local
   - Sync automático quando online
   - Conflict resolution

2. **BLoC Pattern**
   - Migrar de Provider para BLoC/Cubit
   - Estados mais claros (Loading/Success/Error)
   - Melhor testabilidade

3. **Analytics**
   - Gráficos avançados
   - Relatórios exportáveis
   - Previsões com ML

4. **Real-time Updates**
   - Usar Supabase Realtime
   - Updates instantâneos entre dispositivos

---

## ✅ Checklist de Implementação

- [ ] Executar `supabase/schema.sql` no Supabase
- [ ] Verificar tabelas criadas no Table Editor
- [ ] Adicionar `RepositoryProvider.instance.initialize()` no bootstrap
- [ ] Migrar `AppState` para usar `EggRepository`
- [ ] Migrar `AppState` para usar `ExpenseRepository`
- [ ] Migrar `AppState` para usar `VetRepository`
- [ ] Adicionar loading states na UI
- [ ] Adicionar error handling na UI
- [ ] Chamar `loadRecords()` após login
- [ ] Testar CRUD completo (Create/Read/Update/Delete)
- [ ] Verificar dados no Supabase Table Editor
- [ ] Testar logout e login novamente (dados devem persistir)

---

## 🎉 Resultado Final

Depois de seguir todos os passos, terá:
- ✅ App totalmente funcional com backend real
- ✅ Dados persistentes e seguros
- ✅ Arquitectura profissional e escalável
- ✅ Código limpo e testável
- ✅ Pronto para produção!

---

Bom trabalho! 🚀
