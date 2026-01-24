# 🗄️ Supabase Database Setup

## Como executar o schema SQL

### 1. Aceder ao Supabase Dashboard
1. Vá para [supabase.com](https://supabase.com)
2. Login no seu projeto
3. Selecione o projeto **HCKEgg Lite**

### 2. Limpar database existente (RECOMENDADO)

**⚠️ Se já executou o schema antes ou tem erros de "already exists":**

1. No menu lateral, clique em **SQL Editor**
2. Clique em **New Query**
3. Copie **todo** o conteúdo de `cleanup.sql`
4. Cole no editor SQL
5. Clique em **Run** (ou `Cmd/Ctrl + Enter`)
6. Aguarde a mensagem: "Cleanup completo!"

**⚠️ AVISO: Este passo remove TODAS as tabelas e dados! Use apenas se quiser começar do zero!**

### 3. Executar o SQL principal
1. No **SQL Editor**, clique em **New Query** novamente (ou limpe a query anterior)
2. Copie **todo** o conteúdo de `schema.sql`
3. Cole no editor SQL
4. Clique em **Run** (ou `Cmd/Ctrl + Enter`)
5. Aguarde ~5-10 segundos

### 4. Verificar as tabelas
1. No menu lateral, clique em **Table Editor**
2. Deve ver 3 tabelas criadas:
   - ✅ `daily_egg_records`
   - ✅ `expenses`
   - ✅ `vet_records`

## 📊 Estrutura das Tabelas

### `daily_egg_records`
Registos diários de produção de ovos e despesas associadas.

**Campos principais:**
- `id` - UUID (PK)
- `user_id` - UUID (FK → auth.users)
- `date` - Data do registo
- `eggs_collected`, `eggs_sold`, `eggs_consumed` - Contadores
- `price_per_egg` - Preço unitário (€)
- `feed_expense`, `vet_expense`, `other_expense` - Despesas (€)
- `hen_count` - Número de galinhas
- `notes` - Notas opcionais

**Constraints:**
- Um registo por utilizador por data (`unique_user_date`)

---

### `expenses`
Despesas independentes (não associadas a registos diários).

**Campos principais:**
- `id` - UUID (PK)
- `user_id` - UUID (FK → auth.users)
- `date` - Data da despesa
- `category` - Categoria: `feed`, `veterinary`, `maintenance`, `equipment`, `utilities`, `other`
- `amount` - Montante (€)
- `description` - Descrição obrigatória
- `notes` - Notas opcionais

**Validações:**
- `amount > 0`
- `category` IN (valores permitidos)

---

### `vet_records`
Registos veterinários e de saúde das galinhas.

**Campos principais:**
- `id` - UUID (PK)
- `user_id` - UUID (FK → auth.users)
- `date` - Data do registo
- `type` - Tipo: `vaccine`, `disease`, `treatment`, `death`, `checkup`
- `hens_affected` - Número de galinhas afectadas
- `description` - Descrição obrigatória
- `medication` - Medicação (opcional)
- `cost` - Custo (€)
- `next_action_date` - Data da próxima acção
- `severity` - Gravidade: `low`, `medium`, `high`, `critical`

---

## 🔒 Segurança (Row Level Security)

Todas as tabelas têm **RLS (Row Level Security)** activado:

- ✅ Utilizadores apenas vêem **os seus próprios dados**
- ✅ Utilizadores apenas podem **criar/editar/eliminar** os seus próprios registos
- ✅ Não é possível aceder a dados de outros utilizadores

### Políticas implementadas:
- SELECT: `auth.uid() = user_id`
- INSERT: `auth.uid() = user_id`
- UPDATE: `auth.uid() = user_id`
- DELETE: `auth.uid() = user_id`

---

## 📈 Features Avançadas

### Triggers
- **`updated_at`** é actualizado automaticamente em cada UPDATE

### Indexes
- Indexes em `user_id`, `date`, `created_at` para queries rápidas
- Indexes específicos para `category`, `type`, `severity`, `next_action_date`

### Views
- **`daily_egg_records_with_stats`** - View com campos calculados:
  - `revenue` = `eggs_sold * price_per_egg`
  - `total_expenses` = soma de todas as despesas
  - `net_profit` = `revenue - total_expenses`

### Functions
- **`get_user_stats(user_id, start_date, end_date)`** - Estatísticas agregadas para um período

---

## 🧪 Testar as Tabelas

### No SQL Editor, executar:

```sql
-- Ver as suas tabelas
SELECT * FROM daily_egg_records LIMIT 10;
SELECT * FROM expenses LIMIT 10;
SELECT * FROM vet_records LIMIT 10;

-- Ver estatísticas (substitua o user_id)
SELECT * FROM get_user_stats(
    'YOUR_USER_ID'::UUID,
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE
);

-- Verificar RLS (deve retornar apenas os seus dados)
SELECT * FROM daily_egg_records WHERE user_id = auth.uid();
```

---

## 🚀 Próximos Passos

Após executar o schema:
1. ✅ Verificar tabelas criadas
2. ✅ Testar inserir/ler dados manualmente no Table Editor
3. ✅ Confirmar que RLS está a funcionar
4. 🔄 Implementar Repositories no Flutter (próximo passo!)

---

## 📝 Notas Importantes

- **UUIDs**: Todas as tabelas usam UUIDs (mais seguro que IDs sequenciais)
- **Timestamps**: Usam `TIMESTAMP WITH TIME ZONE` para UTC
- **Decimal**: Valores monetários usam `DECIMAL(10, 2)` para precisão
- **Cascading Deletes**: Se um utilizador for eliminado, todos os seus dados são eliminados automaticamente
