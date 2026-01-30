# Supabase Database Setup

## Quick Start

1. Go to [supabase.com](https://supabase.com) and open your project
2. Navigate to **SQL Editor** in the sidebar
3. Click **New Query**
4. Copy the entire contents of `schema.sql`
5. Paste into the editor and click **Run**
6. Done! All tables are created.

## Tables Overview

The `schema.sql` file creates all 8 tables needed for HCKEgg Lite:

| Table | Purpose |
|-------|---------|
| `user_profiles` | User profile with display name and avatar |
| `daily_egg_records` | Daily egg production tracking |
| `egg_sales` | Sales with pricing and customer info |
| `egg_reservations` | Future egg reservations |
| `expenses` | Farm operational expenses |
| `vet_records` | Veterinary and health records |
| `feed_stocks` | Feed inventory levels |
| `feed_movements` | Feed stock movement history |

## Table Details

### `daily_egg_records`
Daily egg production records.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `date` | DATE | Record date (unique per user) |
| `eggs_collected` | INTEGER | Eggs collected |
| `eggs_consumed` | INTEGER | Eggs consumed |
| `hen_count` | INTEGER | Number of hens |
| `notes` | TEXT | Optional notes |

### `egg_sales`
Egg sales with pricing.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `date` | DATE | Sale date |
| `quantity_sold` | INTEGER | Number of eggs sold |
| `price_per_egg` | DECIMAL | Price per egg |
| `price_per_dozen` | DECIMAL | Price per dozen |
| `customer_name` | TEXT | Customer name |
| `is_lost` | BOOLEAN | Mark as unpaid/lost sale |

### `egg_reservations`
Future egg reservations.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `date` | DATE | Reservation date |
| `pickup_date` | DATE | Expected pickup date |
| `quantity` | INTEGER | Number of eggs reserved |
| `customer_name` | TEXT | Customer name |

### `expenses`
Operational expenses (excludes vet costs).

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `date` | DATE | Expense date |
| `category` | VARCHAR | feed, maintenance, equipment, utilities, other |
| `amount` | DECIMAL | Expense amount |
| `description` | TEXT | Description |

### `vet_records`
Veterinary and health records.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `date` | DATE | Record date |
| `type` | VARCHAR | vaccine, disease, treatment, death, checkup |
| `hens_affected` | INTEGER | Number of hens affected |
| `description` | TEXT | Description |
| `medication` | TEXT | Medication used |
| `cost` | DECIMAL | Cost |
| `next_action_date` | DATE | Follow-up date |
| `severity` | VARCHAR | low, medium, high, critical |

### `feed_stocks`
Feed inventory levels.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `type` | VARCHAR | layer, grower, starter, scratch, supplement, other |
| `brand` | TEXT | Brand name |
| `current_quantity_kg` | DECIMAL | Current stock in kg |
| `minimum_quantity_kg` | DECIMAL | Low stock threshold |
| `price_per_kg` | DECIMAL | Price per kg |

### `feed_movements`
Feed stock movement history.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users |
| `feed_stock_id` | UUID | Foreign key to feed_stocks |
| `movement_type` | VARCHAR | purchase, consumption, adjustment, loss |
| `quantity_kg` | DECIMAL | Quantity moved |
| `cost` | DECIMAL | Cost (for purchases) |
| `date` | DATE | Movement date |

### `user_profiles`
User profile information.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `user_id` | UUID | Foreign key to auth.users (unique) |
| `display_name` | TEXT | Display name |
| `avatar_url` | TEXT | Avatar image URL |
| `bio` | TEXT | User bio |

## Security (Row Level Security)

All tables have **RLS (Row Level Security)** enabled:

- Users can only see **their own data**
- Users can only **create/edit/delete** their own records
- No access to other users' data

Policies implemented for all tables:
- SELECT: `auth.uid() = user_id`
- INSERT: `auth.uid() = user_id`
- UPDATE: `auth.uid() = user_id`
- DELETE: `auth.uid() = user_id`

## Storage

The schema creates an `avatars` storage bucket for user profile images:
- Public read access
- Users can only upload/update/delete their own avatar

## Functions

| Function | Description |
|----------|-------------|
| `update_updated_at_column()` | Auto-updates `updated_at` timestamp |
| `delete_user_account()` | Allows users to delete their own account |

## Verify Installation

After running the schema, check the Table Editor to confirm all 8 tables are created:

1. `user_profiles`
2. `daily_egg_records`
3. `egg_sales`
4. `egg_reservations`
5. `expenses`
6. `vet_records`
7. `feed_stocks`
8. `feed_movements`
