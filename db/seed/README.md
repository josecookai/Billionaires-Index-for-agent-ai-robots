# Seed data

本目录用于把“Top N 实体的静态 SNW 数据”导入 Postgres（基于 `db/schema.sql`）。

## 前置

1) 先建库并执行 DDL：`db/schema.sql`
2) 再执行 seed SQL

## Top 30（2026-02-04）

- SQL：`db/seed/seed_2026-02-04_top30.sql`

执行示例：

```bash
psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed/seed_2026-02-04_top30.sql
```

说明：
- seed 会先删除同名实体的历史快照/组件快照（通过 `entity.name` 匹配）再重新插入，保证可重复执行。
- `as_of_ts` 固定为 `2026-02-04T00:00:00Z`，`calc_version` 为 `seed_v1`。

