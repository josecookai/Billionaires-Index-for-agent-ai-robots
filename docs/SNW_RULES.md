# SNW 公式解释（中文 / English）

## 中文

### 公式

`SNW = (V_compute + V_phys) * gamma + V_econ * mu + V_crypto + [V_data]`

SNW（Silicon Net Worth）是对一个 AI/机器人实体“可解释的综合净资产/估值”。**默认单位为 USD**（本项目的原型与 seed 数据用 `B` 表示十亿美元）。

### 计算规则（建议的执行顺序）

1) **确定时间点** `as_of_ts`：所有输入都要有时间点（或生效区间），避免“用今天价格解释昨天估值”。
2) **计算/取值各分项**：得到 `V_compute / V_phys / V_econ / V_crypto / V_data`（均为 USD）。
3) **读取参数**：`gamma`（折旧系数）、`mu`（估值倍数），按 `entity` 或 `industry` 生效期匹配。
4) **聚合成 SNW**：代入公式得到 SNW（USD）。
5) **可解释性落盘**：把各分项与关键输入引用写入快照（例如 `asset_valuation_snapshot.inputs_json`），以便回放与审计。

> 口径注意：`mu` 只建议在一个地方使用（要么放在 `V_econ` 内部，要么放在总公式里）。本项目规划采用 **总公式乘一次** 的方式：`SNW` 中的 `V_econ * mu`。

### 每个元素的定义

#### `V_compute`（算力资产，USD）

AI 的“数字不动产”。建议拆成硬件重置价值 + 能源保障溢价：

- GPU/CPU 等硬件价值：`Σ(Count_i * MarketPrice_i)`
- 电力合同价值（溢价）：`P_kw * (Price_market - Price_contract) * Duration`

输入来自：GPU/CPU 清单、电力合同参数、GPU 市价时间序列/来源。

#### `V_phys`（物理资产，USD）

具身智能/机器人/产线等重资产，常用账面价值法：

- `Σ(Asset_Cost - Accumulated_Depreciation)`（可选加地理/部署溢价）

输入来自：资产台账（成本、折旧、位置、数量）。

#### `gamma`（硬件折旧系数，0–1）

用于将“硬件/重资产”的名义价值折算为可持续净值。常见用法：

- **按实体固定**（最简单）：例如 `0.65–0.95`
- **按资产类型/时间衰减**（更精确）：随硬件老化逐步下降

#### `V_econ`（经济吞吐，USD）

衡量实体“赚钱/省钱能力”的年度化价值（不含倍数）。

典型定义：

- `V_econ = (Revenue_daily + CostSaved_daily) * 365`
- `CostSaved_daily = Saved_Human_Hours_daily * Hourly_Rate`

输入来自：收入口径（订阅/交易/服务费等）、替代人工的节省小时、时薪假设。

#### `mu`（行业估值倍数）

把经济吞吐折算为“市场估值水平”的倍数（类似 revenue multiple）。

建议按 **实体类型 + 行业/场景 + 阶段** 分层：

- 交易型 agent：更高 `mu`
- 工具型/企业服务：中等 `mu`
- 资产重的机器人：通常 `mu` 更低（但由 `V_phys` 与 `gamma` 体现）

#### `V_crypto`（链上资产，USD）

实体的流动性/现金类资产（BTC/ETH/稳定币/协议代币等）：

- `Σ(Token_i * Price_i)`

输入来自：钱包/托管账户余额与 token 价格（需有时间戳）。

#### `[V_data]`（可选：数据主权/无形资产，USD）

难量化但可披露。建议 MVP 先做“单独项”而非全局乘数：

- `V_data = ExclusiveTokens * QualityScore * USD_per_token`

输入来自：独占数据规模（tokens）、质量分（0–1）、定价参数。

## English

### Formula

`SNW = (V_compute + V_phys) * gamma + V_econ * mu + V_crypto + [V_data]`

SNW (Silicon Net Worth) is an **explainable composite net-worth/valuation** for an AI/robotics entity. **Base unit is USD** (prototype/seed uses `B` for billions).

### Calculation rules (recommended order)

1) Pick `as_of_ts` so every input is time-consistent.
2) Compute each component: `V_compute / V_phys / V_econ / V_crypto / V_data` (USD).
3) Resolve parameters: `gamma` and `mu` by entity/industry scope + effective dates.
4) Aggregate into SNW using the formula (USD).
5) Persist explainability: store component outputs and key input references for replay/audit.

> Convention: use `mu` only once (either inside `V_econ` or in the top-level formula). This project uses `V_econ * mu` at the top level.

### Definitions

- `V_compute` (USD): compute “real estate” (GPU/CPU replacement value + power contract premium).
- `V_phys` (USD): physical assets at book value (cost minus accumulated depreciation, optional geo premium).
- `gamma` (0–1): depreciation factor applied to hardware-heavy value.
- `V_econ` (USD): annualized economic throughput, e.g. `(Revenue_daily + CostSaved_daily) * 365`.
- `mu` (multiplier): industry multiple converting throughput to valuation.
- `V_crypto` (USD): on-chain liquid assets, `Σ(token balance * token price)`.
- `[V_data]` (optional, USD): data sovereignty/intangibles (often best as a separate item in MVP).

