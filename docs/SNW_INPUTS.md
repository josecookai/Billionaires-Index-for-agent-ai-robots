# SNW 输入映射（MVP）

本文把公式里的每一项，映射到 `db/schema.sql` 的表与字段，方便后续做录入界面与计算服务。

## 总公式

`SNW = (V_compute + V_phys) * gamma + V_econ * mu + V_crypto + [V_data]`

输出落盘：
- `snw_snapshot`：`snw_usd / components_json / calc_version / inputs_hash`
- `asset_valuation_snapshot`：每个 component 的 `value_usd` 与 `inputs_json`

参数：
- `snw_parameter`：
  - `gamma`：`key='gamma' value_num=...`
  - `mu`：`key='mu' value_num=...`
  - 可选：`usd_per_token / hourly_rate / depreciation_*` 等

## V_compute

目标：可解释地算出 `V_gpu + V_cpu + V_power`。

1) GPU/CPU 清单（手工录入）
- `asset (asset_type='gpu_model'|'cpu_model')`
  - `name`：例如 `H100 SXM`, `B200`
- `exposure`
  - `entity_id`
  - `asset_id`（指向 해당 GPU/CPU model）
  - `quantity`：`Count_i`
  - `effective_from/effective_to`
  - `source_document_id`

2) GPU/CPU 市价（准实时）
- `gpu_market_price`
  - `model`：与 `asset.name` 对齐（或在 `asset.metadata` 里维护映射）
  - `ts, price_usd, source_document_id, confidence`

3) 电力合同（手工录入 + 可引用市场价来源）
- `asset (asset_type='power_contract')`
  - `metadata`：建议包含
    - `p_kw`
    - `price_contract_usd_per_kw`
    - `price_market_usd_per_kw`（或 `price_market_source`，由计算时查表）
    - `duration_days`（或 start/end）
- `exposure`：把合同归属到 `entity_id`

## V_econ

目标：计算 `(Revenue_daily + CostSaved_daily) * 365`（倍数 `mu` 在总公式里应用）。

建议（MVP）两种录入方式二选一：

A) 直接录入日值（最简单）
- `asset (asset_type='econ_metric')`
- `exposure.metadata`：
  - `revenue_daily_usd`
  - `cost_saved_daily_usd`
  - `notes`

B) 录入可推导值（更可解释）
- `exposure.metadata`：
  - `agent_revenue_daily_usd`
  - `saved_human_hours_daily`
  - `hourly_rate_usd`（或用 `snw_parameter key='hourly_rate'`）

## V_phys

目标：账面价值法（成本 - 累计折旧）+ 可选位置溢价。

- `asset (asset_type='physical_asset')`
  - `metadata`：建议包含
    - `asset_cost_usd`
    - `depreciation_method`（straight_line 等）
    - `useful_life_days`
    - `accumulated_depreciation_usd`（如果你想手工锁定）
    - `geo_premium_multiplier`（可选）
- `exposure`：把资产项归属到 `entity_id`

## V_crypto

目标：链上余额 * token 价格。

- `asset (asset_type='crypto_wallet')`
  - `metadata`：`chain, address, labels[]`
- `exposure`：把钱包归属到 `entity_id`
- Token 价格：`token_price (symbol, chain, ts, price_usd)`

> 链上余额本身建议作为“计算时实时拉取”，但为了可回放，计算时把“使用到的余额快照”写进 `asset_valuation_snapshot.inputs_json`。

## V_data（可选）

建议 MVP 做成单独项（USD），避免做全局乘数引发解释困难。

- `asset (asset_type='data_metric')`
- `exposure.metadata`：
  - `exclusive_tokens`
  - `quality_score`（0-1）
- 参数：`snw_parameter key='usd_per_token'`

