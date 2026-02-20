# Plano: Sistema Multi-Utilizador com Permissões

## Resumo
Permitir que múltiplos utilizadores acedam ao mesmo capoeiro com permissões específicas (Owner/Editor).

## Decisões Tomadas
- **1 capoeiro por utilizador** (sem switching)
- **Convites por email** (via Supabase)
- **2 roles**: Owner (controlo total) + Editor (criar/editar/eliminar dados)

---

## Fase 1: Schema de Base de Dados (Supabase)

### 1.1 Nova tabela `farms`
```sql
CREATE TABLE farms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users(id) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### 1.2 Nova tabela `farm_members`
```sql
CREATE TYPE farm_role AS ENUM ('owner', 'editor');

CREATE TABLE farm_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID REFERENCES farms(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role farm_role NOT NULL DEFAULT 'editor',
  invited_by UUID REFERENCES auth.users(id),
  joined_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(farm_id, user_id)
);
```

### 1.3 Nova tabela `farm_invitations`
```sql
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'expired', 'cancelled');

CREATE TABLE farm_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  farm_id UUID REFERENCES farms(id) ON DELETE CASCADE NOT NULL,
  email TEXT NOT NULL,
  role farm_role NOT NULL DEFAULT 'editor',
  invited_by UUID REFERENCES auth.users(id) NOT NULL,
  status invitation_status DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + interval '7 days'),
  accepted_at TIMESTAMPTZ,
  UNIQUE(farm_id, email, status) -- Evitar convites duplicados pendentes
);
```

### 1.4 Adicionar `farm_id` às tabelas existentes
```sql
-- Adicionar coluna farm_id a todas as tabelas de dados
ALTER TABLE daily_egg_records ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE sales ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE egg_reservations ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE vet_records ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE vet_appointments ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE expenses ADD COLUMN farm_id UUID REFERENCES farms(id);
ALTER TABLE feed_stock ADD COLUMN farm_id UUID REFERENCES farms(id);
-- Adicionar a outras tabelas conforme necessário
```

### 1.5 Migração de dados existentes
```sql
-- Criar farm para cada utilizador existente
INSERT INTO farms (id, name, created_by)
SELECT gen_random_uuid(), 'Meu Capoeiro', user_id
FROM (SELECT DISTINCT user_id FROM daily_egg_records) AS users;

-- Adicionar owners às farms
INSERT INTO farm_members (farm_id, user_id, role)
SELECT f.id, f.created_by, 'owner'
FROM farms f;

-- Atualizar registos existentes com farm_id
UPDATE daily_egg_records r
SET farm_id = f.id
FROM farms f
WHERE f.created_by = r.user_id;

-- Repetir para todas as tabelas...
```

---

## Fase 2: Row-Level Security (RLS)

### 2.1 Helper function para obter farm do utilizador
```sql
CREATE OR REPLACE FUNCTION get_user_farm_id()
RETURNS UUID AS $$
  SELECT farm_id FROM farm_members
  WHERE user_id = auth.uid()
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION user_has_farm_access(target_farm_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM farm_members
    WHERE user_id = auth.uid() AND farm_id = target_farm_id
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION user_is_farm_owner(target_farm_id UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS(
    SELECT 1 FROM farm_members
    WHERE user_id = auth.uid()
    AND farm_id = target_farm_id
    AND role = 'owner'
  );
$$ LANGUAGE sql SECURITY DEFINER;
```

### 2.2 Políticas RLS para tabelas de dados
```sql
-- Exemplo para daily_egg_records (repetir para outras tabelas)
ALTER TABLE daily_egg_records ENABLE ROW LEVEL SECURITY;

-- SELECT: membros da farm podem ver
CREATE POLICY "Members can view farm data" ON daily_egg_records
  FOR SELECT USING (user_has_farm_access(farm_id));

-- INSERT: membros podem criar (owner ou editor)
CREATE POLICY "Members can insert farm data" ON daily_egg_records
  FOR INSERT WITH CHECK (user_has_farm_access(farm_id));

-- UPDATE: membros podem editar
CREATE POLICY "Members can update farm data" ON daily_egg_records
  FOR UPDATE USING (user_has_farm_access(farm_id));

-- DELETE: membros podem eliminar
CREATE POLICY "Members can delete farm data" ON daily_egg_records
  FOR DELETE USING (user_has_farm_access(farm_id));
```

### 2.3 Políticas para farm_members (apenas owners gerem)
```sql
ALTER TABLE farm_members ENABLE ROW LEVEL SECURITY;

-- Ver membros da própria farm
CREATE POLICY "Members can view farm members" ON farm_members
  FOR SELECT USING (user_has_farm_access(farm_id));

-- Apenas owners podem adicionar/remover membros
CREATE POLICY "Owners can manage members" ON farm_members
  FOR ALL USING (user_is_farm_owner(farm_id));
```

---

## Fase 3: Sistema de Convites (Backend)

### 3.1 Função para enviar convite
```sql
CREATE OR REPLACE FUNCTION invite_to_farm(
  p_email TEXT,
  p_role farm_role DEFAULT 'editor'
)
RETURNS farm_invitations AS $$
DECLARE
  v_farm_id UUID;
  v_invitation farm_invitations;
BEGIN
  -- Obter farm do utilizador atual
  SELECT farm_id INTO v_farm_id
  FROM farm_members
  WHERE user_id = auth.uid() AND role = 'owner';

  IF v_farm_id IS NULL THEN
    RAISE EXCEPTION 'Only farm owners can send invitations';
  END IF;

  -- Verificar se já é membro
  IF EXISTS(
    SELECT 1 FROM farm_members fm
    JOIN auth.users u ON u.id = fm.user_id
    WHERE fm.farm_id = v_farm_id AND u.email = p_email
  ) THEN
    RAISE EXCEPTION 'User is already a member of this farm';
  END IF;

  -- Cancelar convites pendentes anteriores
  UPDATE farm_invitations
  SET status = 'cancelled'
  WHERE farm_id = v_farm_id AND email = p_email AND status = 'pending';

  -- Criar novo convite
  INSERT INTO farm_invitations (farm_id, email, role, invited_by)
  VALUES (v_farm_id, p_email, p_role, auth.uid())
  RETURNING * INTO v_invitation;

  RETURN v_invitation;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.2 Função para aceitar convite (chamada após login/registo)
```sql
CREATE OR REPLACE FUNCTION accept_farm_invitation()
RETURNS BOOLEAN AS $$
DECLARE
  v_invitation farm_invitations;
  v_user_email TEXT;
BEGIN
  -- Obter email do utilizador atual
  SELECT email INTO v_user_email
  FROM auth.users WHERE id = auth.uid();

  -- Verificar se já pertence a uma farm
  IF EXISTS(SELECT 1 FROM farm_members WHERE user_id = auth.uid()) THEN
    RETURN FALSE; -- Já tem farm
  END IF;

  -- Procurar convite pendente
  SELECT * INTO v_invitation
  FROM farm_invitations
  WHERE email = v_user_email
    AND status = 'pending'
    AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_invitation IS NULL THEN
    RETURN FALSE; -- Sem convite
  END IF;

  -- Adicionar como membro
  INSERT INTO farm_members (farm_id, user_id, role, invited_by)
  VALUES (v_invitation.farm_id, auth.uid(), v_invitation.role, v_invitation.invited_by);

  -- Marcar convite como aceite
  UPDATE farm_invitations
  SET status = 'accepted', accepted_at = now()
  WHERE id = v_invitation.id;

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.3 Edge Function para enviar email de convite
```typescript
// supabase/functions/send-farm-invite/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  const { invitation_id } = await req.json()

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Obter detalhes do convite
  const { data: invitation } = await supabase
    .from('farm_invitations')
    .select('*, farms(name), inviter:invited_by(raw_user_meta_data)')
    .eq('id', invitation_id)
    .single()

  // Enviar email via Supabase Auth ou serviço externo
  // ...

  return new Response(JSON.stringify({ success: true }))
})
```

---

## Fase 4: Alterações no Frontend (Flutter)

### 4.1 Novos modelos
```dart
// lib/models/farm.dart
class Farm {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  // ...
}

// lib/models/farm_member.dart
enum FarmRole { owner, editor }

class FarmMember {
  final String id;
  final String farmId;
  final String userId;
  final FarmRole role;
  final String? userEmail;
  final String? userName;
  // ...
}

// lib/models/farm_invitation.dart
class FarmInvitation {
  final String id;
  final String email;
  final FarmRole role;
  final DateTime expiresAt;
  // ...
}
```

### 4.2 Novo provider
```dart
// lib/features/farm/presentation/providers/farm_provider.dart
class FarmProvider extends ChangeNotifier {
  Farm? _currentFarm;
  List<FarmMember> _members = [];
  List<FarmInvitation> _pendingInvitations = [];
  FarmRole? _currentUserRole;

  bool get isOwner => _currentUserRole == FarmRole.owner;
  bool get isEditor => _currentUserRole != null;

  Future<void> loadFarm() async { ... }
  Future<void> inviteMember(String email, FarmRole role) async { ... }
  Future<void> removeMember(String userId) async { ... }
  Future<void> cancelInvitation(String invitationId) async { ... }
  Future<void> updateFarmName(String name) async { ... }
}
```

### 4.3 Novos ecrãs/dialogs
```
lib/
├── features/
│   └── farm/
│       ├── data/
│       │   └── farm_repository.dart
│       ├── domain/
│       │   └── entities/
│       └── presentation/
│           ├── providers/
│           │   └── farm_provider.dart
│           ├── pages/
│           │   └── farm_settings_page.dart
│           └── widgets/
│               ├── member_list_tile.dart
│               ├── invite_member_dialog.dart
│               └── pending_invitations_card.dart
```

### 4.4 Fluxo de novo utilizador
1. Utilizador regista-se
2. App verifica se tem convite pendente (`accept_farm_invitation()`)
3. Se sim → Adicionado à farm existente
4. Se não → Criar nova farm (`create_farm()`)

### 4.5 UI na página de Settings
```
┌─────────────────────────────────────┐
│ ⚙️ Definições                       │
├─────────────────────────────────────┤
│ 👤 Perfil                           │
│ 🌍 Idioma                           │
│ 🎨 Tema                             │
├─────────────────────────────────────┤
│ 🏠 Capoeiro                         │  ← NOVA SECÇÃO
│   Nome: "Quinta da Maria"           │
│   Membros: 3                        │
│   [Gerir Membros]  (só para owner)  │
├─────────────────────────────────────┤
│ 🔐 Segurança                        │
│ ℹ️ Sobre                            │
└─────────────────────────────────────┘
```

---

## Fase 5: Atualizar Providers Existentes

### 5.1 Modificar queries para filtrar por farm_id
Todos os providers existentes precisam:
1. Obter `farm_id` do utilizador atual
2. Incluir `farm_id` em todos os INSERTs
3. RLS trata do filtro automático nos SELECTs

```dart
// Antes
Future<void> saveRecord(DailyEggRecord record) async {
  await _supabase.from('daily_egg_records').upsert(record.toJson());
}

// Depois
Future<void> saveRecord(DailyEggRecord record) async {
  final farmId = await _getFarmId();
  await _supabase.from('daily_egg_records').upsert({
    ...record.toJson(),
    'farm_id': farmId,
  });
}
```

---

## Checklist de Implementação

### Base de Dados
- [ ] Criar tabela `farms`
- [ ] Criar tabela `farm_members` com enum `farm_role`
- [ ] Criar tabela `farm_invitations`
- [ ] Adicionar `farm_id` a todas as tabelas de dados
- [ ] Criar migration para dados existentes
- [ ] Implementar funções helper RLS
- [ ] Criar políticas RLS para todas as tabelas
- [ ] Criar função `invite_to_farm()`
- [ ] Criar função `accept_farm_invitation()`
- [ ] Criar função `create_farm()`

### Backend (Edge Functions)
- [ ] Função para enviar email de convite
- [ ] Template de email de convite

### Frontend
- [ ] Modelo `Farm`
- [ ] Modelo `FarmMember`
- [ ] Modelo `FarmInvitation`
- [ ] `FarmRepository`
- [ ] `FarmProvider`
- [ ] Secção "Capoeiro" na página Settings
- [ ] `FarmSettingsPage` (gestão de membros)
- [ ] `InviteMemberDialog`
- [ ] Fluxo de onboarding (criar farm ou aceitar convite)
- [ ] Atualizar todos os providers para incluir `farm_id`
- [ ] Traduções i18n para novos textos

### Testes
- [ ] Testes unitários para FarmProvider
- [ ] Testes de integração para convites
- [ ] Testar RLS policies manualmente

---

## Estimativa de Esforço
- **Fase 1-2 (DB + RLS):** ~2-3 horas
- **Fase 3 (Convites backend):** ~1-2 horas
- **Fase 4-5 (Frontend):** ~4-6 horas
- **Testes & polish:** ~2 horas

**Total: ~10-15 horas de desenvolvimento**

---

## Notas Adicionais

### Segurança
- Convites expiram após 7 dias
- Email de convite não é clickable link direto (utilizador faz login/registo normal)
- RLS garante isolamento de dados a nível de DB

### UX
- Owner vê badge "Owner" no seu perfil
- Membros veem "Editor"
- Apenas owners veem botão "Convidar Membro"
- Feedback claro quando convite é enviado/aceite

### Futuro (não incluído agora)
- Role "Viewer" (apenas leitura)
- Permissões granulares por feature
- Múltiplas farms por utilizador
- Histórico de atividade por membro
