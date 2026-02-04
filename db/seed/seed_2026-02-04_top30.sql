-- Seed: Top 30 SNW entities (as_of 2026-02-04)
-- Source: user-provided CSV in chat
-- Strategy: delete-by-name then re-insert to keep runs idempotent.

begin;

-- Ensure extension exists (schema.sql also does this, but keep seed standalone-safe).
create extension if not exists pgcrypto;

-- Seed constants
do $$
begin
  -- no-op placeholder (keeps seed compatible with some runners)
end $$;

-- Names list for idempotent refresh
with names(name) as (
  values
    ('GPT-5 Sovereign'),
    ('Optimus Fleet Prime'),
    ('Aladdin-Prime AI'),
    ('Claude-4 Research'),
    ('DeepSeek-V3 Master'),
    ('Waymo Fleet-Theta'),
    ('Figure 03 Swarm'),
    ('Gemini 2.0 Pro Instance'),
    ('Grok-3 Cluster'),
    ('Med-Palm Expert Node'),
    ('Base-Agent-01'),
    ('Cyber-Dojo Master'),
    ('Sora-Director Gen2'),
    ('Nvidia Nemesis Cluster'),
    ('Amazon Olympus Node'),
    ('Aurora-Driver Instance'),
    ('Quant-X-Global'),
    ('Character-AI Pro Hub'),
    ('Midjourney Serverless'),
    ('Aegis Defense AI'),
    ('Mistral-Large Instance'),
    ('Shield-Security Agent'),
    ('Farming-Swarm Delta'),
    ('Legal-Mind Elite'),
    ('Codeium-Enterprise'),
    ('Starlink-Mesh AI'),
    ('Stable-Diffusion Hub'),
    ('AITX-Patrol Unit'),
    ('Solana-Validator AI'),
    ('Bio-Fold Researcher')
),
targets as (
  select e.id
  from entity e
  join names n on n.name = e.name
)
delete from snw_snapshot s where s.entity_id in (select id from targets);

with names(name) as (
  values
    ('GPT-5 Sovereign'),
    ('Optimus Fleet Prime'),
    ('Aladdin-Prime AI'),
    ('Claude-4 Research'),
    ('DeepSeek-V3 Master'),
    ('Waymo Fleet-Theta'),
    ('Figure 03 Swarm'),
    ('Gemini 2.0 Pro Instance'),
    ('Grok-3 Cluster'),
    ('Med-Palm Expert Node'),
    ('Base-Agent-01'),
    ('Cyber-Dojo Master'),
    ('Sora-Director Gen2'),
    ('Nvidia Nemesis Cluster'),
    ('Amazon Olympus Node'),
    ('Aurora-Driver Instance'),
    ('Quant-X-Global'),
    ('Character-AI Pro Hub'),
    ('Midjourney Serverless'),
    ('Aegis Defense AI'),
    ('Mistral-Large Instance'),
    ('Shield-Security Agent'),
    ('Farming-Swarm Delta'),
    ('Legal-Mind Elite'),
    ('Codeium-Enterprise'),
    ('Starlink-Mesh AI'),
    ('Stable-Diffusion Hub'),
    ('AITX-Patrol Unit'),
    ('Solana-Validator AI'),
    ('Bio-Fold Researcher')
),
targets as (
  select e.id
  from entity e
  join names n on n.name = e.name
)
delete from asset_valuation_snapshot a where a.entity_id in (select id from targets);

with names(name) as (
  values
    ('GPT-5 Sovereign'),
    ('Optimus Fleet Prime'),
    ('Aladdin-Prime AI'),
    ('Claude-4 Research'),
    ('DeepSeek-V3 Master'),
    ('Waymo Fleet-Theta'),
    ('Figure 03 Swarm'),
    ('Gemini 2.0 Pro Instance'),
    ('Grok-3 Cluster'),
    ('Med-Palm Expert Node'),
    ('Base-Agent-01'),
    ('Cyber-Dojo Master'),
    ('Sora-Director Gen2'),
    ('Nvidia Nemesis Cluster'),
    ('Amazon Olympus Node'),
    ('Aurora-Driver Instance'),
    ('Quant-X-Global'),
    ('Character-AI Pro Hub'),
    ('Midjourney Serverless'),
    ('Aegis Defense AI'),
    ('Mistral-Large Instance'),
    ('Shield-Security Agent'),
    ('Farming-Swarm Delta'),
    ('Legal-Mind Elite'),
    ('Codeium-Enterprise'),
    ('Starlink-Mesh AI'),
    ('Stable-Diffusion Hub'),
    ('AITX-Patrol Unit'),
    ('Solana-Validator AI'),
    ('Bio-Fold Researcher')
)
delete from entity e using names n where e.name = n.name;

-- Insert entities + snapshots (single as_of_ts)
-- All amounts are in USD billions (B).
with seed as (
  select * from (values
    (1,  'GPT-5 Sovereign',            'Foundation',        156.40, 92.00, 1.20, 0.85, 42.50, 15.0, 0.80, 12.00, 'Primary compute moat'),
    (2,  'Optimus Fleet Prime',        'Robotics',          112.80, 28.50, 38.50, 0.78, 34.00,  8.5, 5.20,  5.00, 'Heavy hardware depreciation'),
    (3,  'Aladdin-Prime AI',           'Finance',            78.20, 12.40, 0.20, 0.92, 58.00, 25.0, 6.50,  2.50, 'High industry multiple (mu)'),
    (4,  'Claude-4 Research',          'Foundation',         52.10, 35.60, 0.50, 0.88, 12.80, 12.0, 0.30,  8.50, 'Enterprise focus'),
    (5,  'DeepSeek-V3 Master',         'Research',           38.40, 18.20, 0.10, 0.90,  8.40, 10.0,11.50,  0.00, 'Crypto liquidity leader'),
    (6,  'Waymo Fleet-Theta',          'Autonomy',           32.50,  5.80,22.40, 0.72, 18.20,  6.0, 0.10,  4.00, 'Regional high-res map data'),
    (7,  'Figure 03 Swarm',            'Robotics',           28.90,  4.50,18.80, 0.80,  9.50, 12.0, 0.20,  1.50, 'Industrial labor replacement'),
    (8,  'Gemini 2.0 Pro Instance',    'Foundation',         26.40, 19.50, 0.80, 0.85,  6.20, 10.0, 0.00,  4.50, 'Multi-modal throughput'),
    (9,  'Grok-3 Cluster',             'Social/X',           24.80, 15.20, 0.40, 0.85,  8.10, 12.0, 1.20,  3.50, 'Real-time data stream advantage'),
    (10, 'Med-Palm Expert Node',       'Healthcare',         21.50,  4.20, 0.60, 0.90, 14.20, 22.0, 0.00, 10.00, 'Specialized domain data'),
    (11, 'Base-Agent-01',              'Web3/DeFi',          18.60,  1.20, 0.00, 0.95,  4.80, 18.0,12.50,  0.00, 'Pure liquidity/on-chain play'),
    (12, 'Cyber-Dojo Master',          'Education',          15.20,  3.80, 0.20, 0.88,  9.40,  8.0, 1.50,  2.00, 'Subscription-based Econ'),
    (13, 'Sora-Director Gen2',         'Creative',           14.80,  9.50, 0.10, 0.80,  4.20, 12.0, 0.50,  3.00, 'Compute-intensive rendering'),
    (14, 'Nvidia Nemesis Cluster',     'Infrastructure',     12.50, 11.00, 1.00, 0.95,  0.50,  5.0, 0.00,  0.50, 'Internal R&D asset'),
    (15, 'Amazon Olympus Node',        'E-commerce',         11.20,  7.80, 2.50, 0.82,  2.40,  8.0, 0.00,  1.50, 'Logistics optimization'),
    (16, 'Aurora-Driver Instance',     'Logistics',           9.80,  2.10, 6.50, 0.75,  3.20, 10.0, 0.10,  1.00, 'Freight automation'),
    (17, 'Quant-X-Global',             'Finance',             8.40,  3.20, 0.10, 0.92,  4.80, 30.0, 0.50,  0.20, 'High volatility/High mu'),
    (18, 'Character-AI Pro Hub',       'Social/Entertain',    7.90,  4.50, 0.10, 0.88,  2.80, 15.0, 0.10,  1.80, 'User interaction data'),
    (19, 'Midjourney Serverless',      'Creative',            6.50,  4.80, 0.10, 0.80,  1.50, 10.0, 0.20,  0.80, 'Image gen leader'),
    (20, 'Aegis Defense AI',           'Gov/Defense',         6.10,  2.50, 1.50, 0.90,  1.80, 15.0, 0.00,  8.00, 'Strategic data premium'),
    (21, 'Mistral-Large Instance',     'Foundation',          5.80,  3.40, 0.10, 0.88,  2.10,  8.0, 0.10,  0.50, 'Open-weight efficiency'),
    (22, 'Shield-Security Agent',      'Cybersec',            5.40,  1.50, 0.10, 0.90,  3.50, 12.0, 0.40,  1.20, 'Risk mitigation value'),
    (23, 'Farming-Swarm Delta',        'Agriculture',         4.80,  0.80, 3.50, 0.65,  1.20,  6.0, 0.00,  0.50, 'Physical harvest asset'),
    (24, 'Legal-Mind Elite',           'Legal',               4.50,  1.10, 0.10, 0.92,  3.20, 18.0, 0.00,  2.50, 'Professional liability risk'),
    (25, 'Codeium-Enterprise',         'DevTools',            4.20,  2.20, 0.10, 0.88,  1.80, 10.0, 0.10,  0.50, 'Software equity multiplier'),
    (26, 'Starlink-Mesh AI',           'Telecom',             3.90,  1.50, 2.20, 0.70,  0.80,  8.0, 0.00,  0.20, 'Distributed edge compute'),
    (27, 'Stable-Diffusion Hub',       'Creative',            3.20,  2.10, 0.10, 0.80,  0.80,  8.0, 0.30,  0.10, 'Community model cluster'),
    (28, 'AITX-Patrol Unit',           'Security',            2.80,  0.40, 2.20, 0.68,  0.50,  5.0, 0.00,  0.20, 'Surveillance robots'),
    (29, 'Solana-Validator AI',        'Web3/Infra',          2.50,  0.80, 0.20, 0.90,  0.40, 15.0, 1.20,  0.00, 'Staking yield assets'),
    (30, 'Bio-Fold Researcher',        'Science',             2.10,  1.50, 0.10, 0.90,  0.20, 20.0, 0.00,  3.50, 'Patent potential value')
  ) as t(rank, name, category, snw_total_b, v_compute_b, v_phys_b, gamma, v_econ_b, mu, v_crypto_b, v_data_b, notes)
),
ins as (
  insert into entity (id, name, entity_type, country_code, tags, bio, created_at, updated_at)
  select
    gen_random_uuid(),
    s.name,
    case
      when lower(s.category) in ('robotics','autonomy','security','agriculture') then 'robot_fleet'
      when s.name ilike '%agent%' then 'agent'
      else 'company'
    end as entity_type,
    null as country_code,
    array[
      lower(replace(replace(s.category,'/','_'),' ','_'))
    ] as tags,
    s.notes,
    now(),
    now()
  from seed s
  returning id, name
),
joined as (
  select s.*, i.id as entity_id
  from seed s
  join ins i on i.name = s.name
),
params as (
  insert into snw_parameter (scope_type, scope_id, key, value_num, effective_from, effective_to, created_at)
  select
    'entity',
    j.entity_id,
    p.key,
    p.value_num,
    date '2026-02-04',
    null,
    now()
  from joined j
  cross join lateral (
    values
      ('gamma', j.gamma::numeric),
      ('mu', j.mu::numeric)
  ) as p(key, value_num)
  returning 1
),
components as (
  insert into asset_valuation_snapshot (entity_id, as_of_ts, component, value_usd, calc_version, inputs_json)
  select j.entity_id, timestamptz '2026-02-04T00:00:00Z', c.component, c.value_usd, 'seed_v1',
         jsonb_build_object('category', j.category, 'notes', j.notes)
  from joined j
  cross join lateral (
    values
      ('v_compute', (j.v_compute_b * 1000000000)::numeric),
      ('v_phys',    (j.v_phys_b    * 1000000000)::numeric),
      ('v_econ',    (j.v_econ_b    * 1000000000)::numeric),
      ('v_crypto',  (j.v_crypto_b  * 1000000000)::numeric),
      ('v_data',    (j.v_data_b    * 1000000000)::numeric)
  ) as c(component, value_usd)
  returning 1
)
insert into snw_snapshot (
  entity_id,
  as_of_ts,
  snw_usd,
  rank,
  change_1d_usd,
  change_ytd_usd,
  calc_version,
  inputs_hash,
  components_json
)
select
  j.entity_id,
  timestamptz '2026-02-04T00:00:00Z',
  (j.snw_total_b * 1000000000)::numeric,
  j.rank,
  null,
  null,
  'seed_v1',
  null,
  jsonb_build_object(
    'category', j.category,
    'snw_total_b', j.snw_total_b,
    'v_compute_b', j.v_compute_b,
    'v_phys_b', j.v_phys_b,
    'gamma', j.gamma,
    'v_econ_b', j.v_econ_b,
    'mu', j.mu,
    'v_crypto_b', j.v_crypto_b,
    'v_data_b', j.v_data_b,
    'notes', j.notes
  )
from joined j;

commit;

