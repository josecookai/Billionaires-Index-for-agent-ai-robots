-- Postgres schema (MVP) for SNW-based AI/robotics index
-- Notes:
-- - Keep all money values in USD where possible.
-- - Every manual input should carry a source_document_id and effective date range.

create extension if not exists pgcrypto;

-- ---------- sources / audit ----------

create table if not exists source_document (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('url','file','note')),
  title text,
  url text,
  captured_at timestamptz,
  notes text,
  created_at timestamptz not null default now()
);

-- ---------- core entities ----------

create table if not exists entity (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  entity_type text not null check (entity_type in ('company','agent','robot_fleet')),
  country_code text,
  tags text[] not null default '{}',
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists org (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  country_code text,
  industry text,
  is_public boolean not null default false,
  ticker text,
  exchange text,
  currency text,
  created_at timestamptz not null default now()
);

-- Optional link: entity <-> org (many-to-many)
create table if not exists entity_org (
  entity_id uuid not null references entity(id) on delete cascade,
  org_id uuid not null references org(id) on delete cascade,
  relationship text,
  primary key (entity_id, org_id)
);

-- ---------- assets & exposures ----------

create table if not exists asset (
  id uuid primary key default gen_random_uuid(),
  asset_type text not null check (asset_type in (
    'gpu_model',
    'cpu_model',
    'power_contract',
    'physical_asset',
    'crypto_wallet',
    'econ_metric',
    'data_metric'
  )),
  name text not null,
  currency text not null default 'USD',
  org_id uuid references org(id) on delete set null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- entity-asset association, with time validity and source tracking.
-- Examples:
-- - GPU: quantity=Count_i, metadata={"model":"H100","notes":"..."}
-- - Power contract: quantity=P_kw, metadata={"price_contract":..., "price_market_source":..., "duration_days":...}
-- - Wallet: quantity=1, metadata={"chain":"ethereum","address":"0x..."}
-- - Econ metric: quantity can be omitted, metadata={"revenue_daily_usd":..., "cost_saved_daily_usd":...}
create table if not exists exposure (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references entity(id) on delete cascade,
  asset_id uuid not null references asset(id) on delete restrict,
  quantity numeric,
  metadata jsonb not null default '{}'::jsonb,
  effective_from date not null,
  effective_to date,
  source_document_id uuid references source_document(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to >= effective_from)
);

create index if not exists idx_exposure_entity_effective
  on exposure (entity_id, effective_from desc);

-- ---------- price feeds ----------

-- GPU "market price" (USD) by model name, quasi-realtime.
create table if not exists gpu_market_price (
  model text not null,
  ts timestamptz not null,
  price_usd numeric not null,
  source_document_id uuid references source_document(id) on delete set null,
  confidence numeric,
  primary key (model, ts)
);

create index if not exists idx_gpu_market_price_recent
  on gpu_market_price (model, ts desc);

-- Token price (USD) by symbol (and optional chain).
create table if not exists token_price (
  symbol text not null,
  chain text not null default 'any',
  ts timestamptz not null,
  price_usd numeric not null,
  source_document_id uuid references source_document(id) on delete set null,
  primary key (symbol, chain, ts)
);

create index if not exists idx_token_price_recent
  on token_price (symbol, chain, ts desc);

-- FX rates when inputs are not USD (optional MVP).
create table if not exists fx_rate (
  base_ccy text not null,
  quote_ccy text not null,
  ts timestamptz not null,
  rate numeric not null,
  source_document_id uuid references source_document(id) on delete set null,
  primary key (base_ccy, quote_ccy, ts)
);

create index if not exists idx_fx_rate_recent
  on fx_rate (base_ccy, quote_ccy, ts desc);

-- ---------- valuation parameters ----------

-- Parameters with effective dates and scoping.
-- scope_type:
-- - global: scope_id is null
-- - entity: scope_id = entity.id
-- - industry: scope_id = text key stored in scope_key (e.g. "trading_agent", "tooling_agent", "robotics")
create table if not exists snw_parameter (
  id uuid primary key default gen_random_uuid(),
  scope_type text not null check (scope_type in ('global','entity','industry')),
  scope_id uuid,
  scope_key text,
  key text not null,
  value_num numeric,
  value_json jsonb,
  effective_from date not null,
  effective_to date,
  source_document_id uuid references source_document(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to >= effective_from),
  check (
    (scope_type = 'global' and scope_id is null and scope_key is null) or
    (scope_type = 'entity' and scope_id is not null) or
    (scope_type = 'industry' and scope_key is not null)
  )
);

create index if not exists idx_snw_parameter_lookup
  on snw_parameter (scope_type, scope_id, scope_key, key, effective_from desc);

-- ---------- manual valuation events ----------

create table if not exists non_public_valuation_event (
  id uuid primary key default gen_random_uuid(),
  entity_id uuid not null references entity(id) on delete cascade,
  component text not null check (component in ('v_compute','v_phys','v_econ','v_crypto','v_data','snw')),
  value_usd numeric not null,
  reason text,
  effective_from date not null,
  effective_to date,
  source_document_id uuid references source_document(id) on delete set null,
  created_at timestamptz not null default now(),
  check (effective_to is null or effective_to >= effective_from)
);

create index if not exists idx_non_public_event_entity_effective
  on non_public_valuation_event (entity_id, effective_from desc);

-- ---------- computed outputs ----------

-- Component-level outputs for audit / explainability.
create table if not exists asset_valuation_snapshot (
  entity_id uuid not null references entity(id) on delete cascade,
  as_of_ts timestamptz not null,
  component text not null check (component in ('v_compute','v_phys','v_econ','v_crypto','v_data')),
  value_usd numeric not null,
  calc_version text not null,
  inputs_json jsonb not null default '{}'::jsonb,
  primary key (entity_id, as_of_ts, component, calc_version)
);

create index if not exists idx_asset_valuation_snapshot_recent
  on asset_valuation_snapshot (as_of_ts desc);

-- Final SNW snapshot; rank is persisted for historical replay.
create table if not exists snw_snapshot (
  entity_id uuid not null references entity(id) on delete cascade,
  as_of_ts timestamptz not null,
  snw_usd numeric not null,
  rank integer,
  change_1d_usd numeric,
  change_ytd_usd numeric,
  calc_version text not null,
  inputs_hash text,
  components_json jsonb not null default '{}'::jsonb,
  primary key (entity_id, as_of_ts, calc_version)
);

create index if not exists idx_snw_snapshot_rank
  on snw_snapshot (as_of_ts desc, snw_usd desc);
