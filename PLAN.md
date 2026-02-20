# Plano: Sistema Multi-Utilizador com Permissões

## Resumo
Permitir que múltiplos utilizadores acedam aos mesmos capoeiros com permissões específicas (Owner/Editor).

## Decisões Tomadas
- **Múltiplos capoeiros por utilizador** (com farm switcher)
- **Convites por email** (via Supabase RPC)
- **2 roles**: Owner (controlo total) + Editor (criar/editar/eliminar dados)

---

## Estado de Implementação

### ✅ Concluído

#### Backend (Supabase)
- [x] Criar tabela `farms`
- [x] Criar tabela `farm_members` com roles (owner/editor)
- [x] Criar tabela `farm_invitations`
- [x] Adicionar `farm_id` a todas as tabelas de dados
- [x] Implementar funções helper RLS (`is_farm_member`, `is_farm_owner`)
- [x] Criar políticas RLS para todas as tabelas
- [x] Criar função `create_farm()`
- [x] Criar função `invite_to_farm()`
- [x] Criar função `accept_farm_invitation()`
- [x] Criar função `get_user_farms()`
- [x] Criar função `get_farm_members()`
- [x] Criar função `get_farm_invitations()`
- [x] Criar função `remove_farm_member()`
- [x] Criar função `leave_farm()`
- [x] Criar função `delete_farm()`
- [x] Criar função `cancel_farm_invitation()`
- [x] Criar função `migrate_user_to_farm()` (migração automática)

#### Frontend (Flutter)
- [x] Modelo `Farm`
- [x] Modelo `FarmMember`
- [x] Modelo `FarmInvitation`
- [x] `FarmProvider` com todas as operações
- [x] Registar `FarmProvider` no ServiceLocator
- [x] Traduções i18n (EN + PT)

### 🔲 Pendente

#### Frontend UI
- [ ] Secção "Capoeiro" na página Settings
- [ ] `FarmSettingsPage` (gestão de membros)
- [ ] `InviteMemberDialog`
- [ ] Farm switcher (dropdown no header/sidebar)
- [ ] Fluxo de onboarding (criar farm ou aceitar convite)
- [ ] Atualizar todos os providers para usar `farm_id` ativo

#### Backend
- [ ] Edge Function para enviar email de convite (opcional - pode usar Supabase Auth magic link)

---

## Ficheiros Criados/Modificados

### Novos ficheiros
```
supabase/migrations/multi_user_farms.sql     # Schema completo
lib/models/farm.dart                         # Farm, FarmMember, FarmInvitation
lib/features/farms/presentation/providers/farm_provider.dart
```

### Ficheiros modificados
```
lib/state/providers/providers.dart           # Export FarmProvider
lib/core/di/service_locator.dart             # createFarmProvider()
lib/app/app_widget.dart                      # Registar FarmProvider
lib/l10n/translations.dart                   # 40+ novas traduções
```

---

## Como Usar

### 1. Executar migração no Supabase
```bash
# No Supabase SQL Editor, executar:
supabase/migrations/multi_user_farms.sql
```

### 2. Migrar dados existentes (automático)
Na primeira vez que um utilizador aceder à app após a migração:
```dart
final farmProvider = context.read<FarmProvider>();
await farmProvider.initialize(); // Cria farm "Meu Capoeiro" se não existir
```

### 3. Criar nova farm
```dart
await farmProvider.createFarm('Nova Quinta', description: 'Descrição opcional');
```

### 4. Convidar membro
```dart
await farmProvider.inviteUser('email@exemplo.com', role: FarmRole.editor);
```

### 5. Alternar entre farms
```dart
await farmProvider.setActiveFarm(farmId);
```

---

## Schema de Base de Dados

### Tabela: farms
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | Primary key |
| name | TEXT | Nome do capoeiro |
| description | TEXT | Descrição (opcional) |
| created_by | UUID | Referência ao criador |
| created_at | TIMESTAMPTZ | Data de criação |

### Tabela: farm_members
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | Primary key |
| farm_id | UUID | Referência à farm |
| user_id | UUID | Referência ao utilizador |
| role | TEXT | 'owner' ou 'editor' |
| invited_by | UUID | Quem convidou |
| joined_at | TIMESTAMPTZ | Data de entrada |

### Tabela: farm_invitations
| Coluna | Tipo | Descrição |
|--------|------|-----------|
| id | UUID | Primary key |
| farm_id | UUID | Referência à farm |
| email | TEXT | Email do convidado |
| role | TEXT | Role a atribuir |
| token | TEXT | Token único para aceitar |
| expires_at | TIMESTAMPTZ | Validade (7 dias) |
| accepted_at | TIMESTAMPTZ | Quando foi aceite |

---

## Políticas RLS

### Dados (eggs, sales, expenses, etc.)
- **SELECT**: Membros da farm podem ver
- **INSERT**: Membros podem criar (com farm_id)
- **UPDATE**: Membros podem editar
- **DELETE**: Membros podem eliminar

### Farm Members
- **SELECT**: Membros podem ver outros membros
- **CRUD**: Apenas owners podem gerir (via funções RPC)

### Convites
- **SELECT**: Owners vêem convites da farm + utilizadores vêem próprios convites

---

## Próximos Passos

1. **Criar UI de gestão de farms** na página Settings
2. **Implementar farm switcher** no header/sidebar
3. **Atualizar providers existentes** para filtrar por `activeFarm.id`
4. **Testar fluxo completo** de convites
5. **Opcional**: Edge Function para emails de convite formatados

---

## Notas de Segurança

- Convites expiram após 7 dias
- Token único por convite (32 bytes hex)
- RLS garante isolamento de dados a nível de DB
- Não é possível remover o último owner
- Owner não pode sair sem transferir propriedade
