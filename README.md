# HCKEgg 360 Lite

**Gestao avicola simplificada / Poultry farm management made simple**

Aplicacao web (PWA) para pequenos e medios avicultores. Controle producao, vendas, despesas e saude do bando num unico lugar.

---

## Funcionalidades / Features

### Producao / Production
- Registo diario de ovos recolhidos e consumidos
- Contagem de galinhas por dia
- Historico pesquisavel com exportacao CSV

### Vendas / Sales
- Registo de vendas com preco por ovo e por duzia
- Dados de cliente (nome, email, telefone)
- Estado de pagamento (pago, pendente, atrasado, adiantado)
- Marcacao de vendas perdidas

### Reservas / Reservations
- Reservar ovos para clientes com data de levantamento
- Converter reservas em vendas com um clique
- Gestao de precos no momento da reserva

### Despesas / Expenses
- Categorias: racao, manutencao, equipamento, utilidades, outros
- Pesquisa e filtro por categoria
- Historial completo com notas

### Saude das Galinhas / Hen Health
- Registos veterinarios: vacinas, doencas, tratamentos, mortes, exames
- Niveis de gravidade (baixa, media, alta, critica)
- Calendario com lembretes de proximas acoes
- Badge no icone quando ha consultas hoje

### Stock de Racao / Feed Stock
- Tipos: poedeiras, crescimento, inicial, cereais, suplementos
- Alertas de stock baixo
- Registo de consumo
- OCR para digitalizar sacos de racao e faturas (via Tesseract.js)

### Painel / Dashboard
- Graficos de producao e receita (fl_chart)
- Estatisticas: total de ovos, vendas, despesas, lucro
- Resumo dos ultimos 7 e 30 dias

### UX
- Bilingue: Portugues e Ingles
- Tema claro e escuro
- Sidebar colapsavel com mini-rail no desktop
- Drawer com seccoes: Producao, Financeiro, Gestao
- Layout responsivo (desktop, tablet, mobile)

---

## Stack Tecnica / Tech Stack

| Componente   | Tecnologia     | Funcao                           |
|-------------|----------------|----------------------------------|
| Frontend    | Flutter 3.x    | UI cross-platform (web-first)    |
| Linguagem   | Dart 3.x       | Logica da aplicacao              |
| Estado      | Provider        | Gestao de estado reativa         |
| Backend     | Supabase        | Auth, Base de Dados, Storage     |
| OCR         | Tesseract.js    | Reconhecimento de texto (web)    |
| Graficos    | fl_chart        | Visualizacao de dados            |
| Router      | go_router       | Navegacao declarativa            |

---

## Instalacao / Setup

### Pre-requisitos
- Flutter 3.x+
- Projeto Supabase (free tier)

### Passos

```bash
# 1. Clonar o repositorio
git clone https://github.com/PinkOffense/hckegg_lite.git
cd hckegg_lite

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Supabase
#    Copiar supabase/schema.sql para o SQL Editor do Supabase e executar

# 4. Configurar variaveis de ambiente
#    Adicionar SUPABASE_URL e SUPABASE_ANON_KEY no ficheiro de config

# 5. Correr a app
flutter run -d chrome
```

---

## Base de Dados / Database

Executar `supabase/schema.sql` no SQL Editor do Supabase. Cria todas as tabelas, indices, RLS e storage num unico script.

| Tabela              | Descricao                              |
|--------------------|----------------------------------------|
| user_profiles      | Perfil do utilizador (nome, avatar)    |
| daily_egg_records  | Registos diarios de producao de ovos   |
| egg_sales          | Vendas com precos e dados de cliente   |
| egg_reservations   | Reservas de ovos para levantamento     |
| expenses           | Despesas operacionais por categoria    |
| vet_records        | Registos veterinarios e de saude       |
| feed_stocks        | Niveis de inventario de racao          |
| feed_movements     | Historico de movimentos de stock       |

**Storage:** Bucket `avatars` para fotos de perfil.

**Seguranca:** Row Level Security (RLS) em todas as tabelas — cada utilizador so acede aos seus dados.

---

## Estrutura / Project Structure

```
lib/
├── app/                    # App config, auth gate, router
├── core/                   # Constants, DI, API client
├── data/datasources/       # Remote data sources (Supabase)
├── dialogs/                # Dialog widgets (feed stock, etc.)
├── features/               # Feature modules (feed, reservations, health)
├── l10n/                   # Translations (PT/EN)
├── models/                 # Data models
├── pages/                  # App screens
├── services/               # Profile, error handling
├── state/providers/        # Provider classes
└── widgets/                # Shared widgets (scaffold, drawer, charts)
```

---

## Licenca / License

MIT License

---

*HCKEgg 2025-2026 — Aviculture 360*
