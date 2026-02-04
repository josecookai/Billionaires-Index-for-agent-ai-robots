# 实时刷新方案（200 实体）

目标：页面“看起来实时”，但数据库只承担“审计/回放/日终快照”，避免每分钟对榜单做重聚合查询。

## 组件

- **Price Ingestor（价格采集器）**
  - 写入：`gpu_market_price / token_price / fx_rate`
  - 频率：token/fx 1–5 分钟；GPU 15–60 分钟（MVP 可人工报价入库）
- **SNW Calculator（估值计算器）**
  - 读取：`entity / asset / exposure / snw_parameter` + 最新价格
  - 输出：
    - 缓存（内存/Redis）：`entity_id -> current_snw`
    - 可选：每 5–15 分钟抽样写一次 `snw_snapshot`
    - 必须：日终写 `snw_snapshot` + `asset_valuation_snapshot`

## 读写路径

- 排行榜/详情“当前值”：读缓存
- 历史曲线/回放：读 `snw_snapshot`（必要时聚合到日/周/月）
- 可解释性：详情页拉取最近一次 `asset_valuation_snapshot` 的 component 分解

## 日终（强制）落盘建议

- 以本地时区的日终窗口为准（例如每天 23:59:59）
- 落盘时同时写入：
  - `snw_snapshot (rank, change_1d_usd, change_ytd_usd, inputs_hash)`
  - `asset_valuation_snapshot`（每个 component 一行）

