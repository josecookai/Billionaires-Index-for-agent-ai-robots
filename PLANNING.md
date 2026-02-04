# Bloomberg Billionaires Index（agent/ai/robots）项目规划（v1）

范围确认：
- 只做 **AI/robotics 主题榜（前 200）**
- 更看重 **实时变动**
- 数据策略：**手工录入 + 公开披露**（价格类数据可插拔“准实时”源）

## 1) MVP 功能范围（先做出来）

- **排行榜页**
  - rank、实体名、`SNW`（USD）、今日变动（Δ$ / Δ%）、YTD 变动、国家/地区、类型（company/agent/robot-fleet）、标签
  - 筛选：国家、行业/标签、类型（company/agent/robot-fleet）
  - 搜索：实体名 / 关联组织名
- **实体详情页**
  - 基本信息：简介、国家、类型、标签、来源链接
  - `SNW` 时间序列（实时点 + 日终快照）
  - `SNW` 分解：`V_compute / V_phys / V_econ / V_crypto / V_data(可选)`，以及参数 `gamma / mu`
- **数据录入/审计（MVP 必做）**
  - 手工录入：算力清单、电力合同、收入/节省成本口径、物理资产台账、钱包地址
  - 每条录入都要能挂来源（URL/文件/截图/备注）与生效期

## 2) 核心估值：SNW（Silicon Net Worth）

定义（美元口径）：

`SNW = (V_compute + V_phys) * gamma + V_econ * mu + V_crypto + [V_data]`

- `gamma`：硬件折旧系数（可按实体/资产类型设置，也可按时间衰减）
- `mu`：行业估值倍数（建议按 “实体类型 + 行业 + 阶段” 分层，并有生效期）
- `V_data`：可选无形资产项（先做“披露项/加分项”）

重要口径提示：你给的描述里 `mu` 同时出现在 `V_econ` 的倍数法与总公式里。为避免重复乘，MVP 推荐采用：
- `V_econ = (Revenue_daily + CostSaved_daily) * 365`
- `SNW` 里再乘 `mu`

### 2.1 V_compute（算力资产）

硬件价值（实时 GPU 市价驱动）：
- `V_gpu = Σ(Count_i * MarketPrice_i)`
- `V_compute = V_gpu + V_cpu + V_power`

电力合同价值（按溢价）：
- `V_power = P_kw * (Price_market - Price_contract) * Duration`

需要的数据：
- GPU/CPU 清单（型号、数量、生效期、来源）
- GPU 市价（按型号、时间戳、来源/可信度）
- 电力合同（功率、合同价、市场价来源、期限、生效期）

### 2.2 V_econ（经济吞吐）

需要的数据（按日）：
- `Revenue_daily`
- `CostSaved_daily = Saved_Human_Hours * Hourly_Rate`

推荐存储方式：
- 录入“每日收入/节省成本”的原始口径与来源（可按周/月录入，系统再均摊到日）
- `mu` 用参数表按行业/类型生效

### 2.3 V_phys（物理资产）

账面价值法：
- `V_phys = Σ(Asset_Cost - Accumulated_Depreciation)`（可加地理溢价）

需要的数据：
- 资产台账（成本、折旧方法/期限、累计折旧、位置）

### 2.4 V_crypto（链上资产）

实时计价：
- `V_crypto = Σ(Token_i * Price_i)`

需要的数据：
- 钱包地址/托管账户（归属、链、标签、生效期）
- Token 价格（时间戳、来源）

### 2.5 V_data（数据主权，可选）

建议 MVP 做成单独项（USD），而不是全局乘数：
- `V_data = ExclusiveTokens * QualityScore * USD_per_token`（`USD_per_token` 可作为参数表维护）

## 3) 需要哪些表（为“可追溯 SNW”服务）

原则：所有“输入”都必须有 `effective_from/effective_to` 与 `source_document_id`，所有“输出”都必须有 `calc_version` 与 `inputs_hash`。

MVP 表清单（12 张）：
- `entity`（200 个估值对象）
- `org`（可选：实体关联公司/机构）
- `asset`（GPU/CPU、电力合同、物理资产项、钱包、经济指标项、数据项）
- `exposure`（entity-asset 关系：数量/参数/地址/功率等 + 生效期）
- `snw_parameter`（`gamma/mu/usd_per_token/hourly_rate` 等参数 + 生效期）
- `gpu_market_price`（型号 -> USD 价格时间序列）
- `token_price`（token -> USD 价格时间序列）
- `fx_rate`（可选：如果输入不全是 USD）
- `non_public_valuation_event`（无法直接由行情驱动的估值事件/人工调整）
- `asset_valuation_snapshot`（把每个实体的各项估值结果落盘，便于审计/回放）
- `snw_snapshot`（最终 SNW 快照 + rank）
- `source_document`（来源链接/文件元数据）

## 4) 数据库与实时刷新策略

### 4.1 数据库：PostgreSQL（首选）

- 关系清晰（实体/资产/关联/参数/来源）
- 时间序列可用分区表（按月）或后续再上 TimescaleDB
- JSONB 可承载“components 分解”与“输入引用”

### 4.2 实时体验：缓存 + 抽样落盘

- **计算层**（定时任务/worker）：
  - 拉取 `token_price/fx/gpu_market_price`
  - 重新计算 200 实体的 `SNW`，写入缓存（内存或 Redis）
- **落盘策略**：
  - 强制：每日本地日终落 1 次 `snw_snapshot`（用于历史回放/审计）
  - 可选：日内每 5–15 分钟抽样落盘 1 次（用于更平滑的曲线）
- **读路径**：
  - 榜单/详情“实时值”读缓存
  - 历史曲线/回放读 `snw_snapshot`

## 5) 下一步（我建议先定 3 个“硬约束”）

1) `gamma`：是全局常数、按实体常数，还是按资产/时间衰减？（这决定参数表与计算逻辑）
2) `mu`：按“行业/类型”给固定表，还是允许对单个实体覆盖？（这决定参数优先级）
3) GPU “实时市价”来源：先用人工录入报价（带来源/可信度）还是接入某个报价 API？（这决定价格采集器复杂度）
