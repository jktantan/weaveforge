# WeaveForge — 织造坊 — ArcadeDB Schema 设计

> 跨宇宙 TRPG 跑团知识管理系统的 ArcadeDB 实现层。
> **上游**：`project-design.md` — 定义数据域与查询能力（数据库无关）  
> 本文件是项目设计在 **ArcadeDB 26.5+** 上的具体实现。

---

## 目录

1. [架构总览](#一架构总览)
2. [多模型映射方法](#二多模型映射方法)
3. [图域设计模式](#三图域设计模式)
4. [文本域设计模式](#四文本域设计模式)
5. [索引策略](#五索引策略)
6. [向量搜索 + 混合检索](#六向量搜索--混合检索)
7. [运行时状态](#七运行时状态)
8. [DDL 模板](#八ddl-模板)

---

## 一、架构总览

```
┌──────────────────────────────────────┐
│   project-design.md                  │
│   数据域 + 查询能力（数据库无关）      │
└──────────────┬───────────────────────┘
               │ 映射
┌──────────────▼───────────────────────┐
│   ArcadeDB                           │
│                                      │
│   ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ │
│   │ 世界  │ │ 角色  │ │ 派系  │ │ 地点  │ │ 事件  │ │剧情线│ │ 桥接  │ │ 规则  │ │
│   │ 域   │ │ 域   │ │ 域   │ │ 域   │ │ 域   │ │ 域   │ │ 域   │ │ 域   │ │
│   └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ │
│   ┌────────────────────────────────────────────────────────────────────┐ │
│   │ Document 集合：设定文档 / 跑团日志 / 小说章节 / 规则文档           │ │
│   └────────────────────────────────────────────────────────────────────┘ │
│                                      │
│   Vertex 类型  +  Edge 类型          │
│   + LSM_VECTOR + FULL_TEXT + GEOSPATIAL │
└──────────────────────────────────────┘
```

**核心原则**：
- `.md` 文件是**源数据**载体，保留不动
- ArcadeDB 是**运行时查询和状态存储**的单一真相源
- 跑团时不直接翻 `.md`，先查数据库，必要时再深读源文件
- 设计优先满足**跑团中最高频的查询类型**

---

## 二、多模型映射方法

ArcadeDB 支持四种数据模型。根据 project-design 中的数据域选择合适的模型：

| 数据域类型 | 映射为 | 原因 |
|------|:--:|------|
| 10 个图域（世界/角色/派系/地点/事件/剧情线/桥接/规则/怪物/物品） | **Vertex + Edge** | 图遍历（KNOWS、CAUSES、CONTAINS、CONNECTS_TO 等） |
| 长篇文本（设定、跑团日志、小说章节） | **Vertex**（需要向量搜索） | LSM_VECTOR 支持 |
| 规则文档 | **Document** | BM25 主索引，无需图关系 |
| 轻量快照（运行状态） | **Document** | 单文档读写，无需关系 |

### Vertex vs Document 选择决策树

```
需要图关系（Edge）？
  ├─ 是 → Vertex
  └─ 否 → 需要向量搜索？
            ├─ 是 → Vertex（推荐，LSM_VECTOR 最早支持）
            │       或 Document（26.x 实测也支持 LSM_VECTOR）
            └─ 否 → Document
```

---

## 三、图域设计模式

### 3.1 标准 Vertex 模板

每个图域对应一个或多个 Vertex 类型。属性分层设计：

```
[Vertex 类型名]
  ── 标识层 ──
  [type]_id     : string  (key, unique)
  display_name  : string
  aliases       : list    用于搜索

  ── 业务层 ──
  [按 project-design 的查询能力表逐项定义字段]

  ── 状态层 ──
  status        : string
  [ref]_ref     : string   → 关联其他 Vertex

  ── 元数据 ──
  world         : string   所属世界
  canon_status  : canon / fanon / original
  first_appeared: string   session_id
```

### 3.2 标准 Edge 模板

Edge 承载**有向、带属性**的关系。

**时间区间化**（推荐）：关系变化不 UPDATE，而是关旧边建新边。

```
Edge 字段模板：
  unified_since : string   起始联合历（NULL=远古）
  unified_until : string   结束联合历（NULL=当前有效）
  closed_by_session : string  关闭此边的 session_id（NULL=仍有效）

过滤当前有效边：WHERE unified_until IS NULL
过滤历史时间点：WHERE unified_since <= X AND (unified_until IS NULL OR X < unified_until)
按 session 回滚：WHERE NOT closed_by_session = 'session_X'
```

**完整 Edge 类型分类**：

| 域 | 关系类别 | Edge 名 | 方向 | 说明 |
|:--:|------|------|------|------|
| 宇宙 | 通道 | CONNECTS_TO | World→Channel→World | 通道属性存于 Channel Vertex（stability/energy_cost/one_way） |
| 宇宙 | 兼容规则 | COMPATIBILITY_RULE | World→World | 物品/能力的默认兼容策略 |
| 宇宙 | 认知映射 | COGNITIVE_MAP | World→World | 语义标记 Edge，映射数据存于 BridgeEntry Vertex |
| 角色 | 人际 | KNOWS | Character→Character | 不对称，含 trust/attraction/respect/history/relationship_phase（相识/命运绑定/若即若离/已破裂/至死不渝） |
| 角色 | 状态快照 | HAS_SNAPSHOT | Character→CharacterSnapshot | 角色状态历史 |
| 派系 | 归属 | BELONGS_TO | Character→Faction | 含 role/loyalty/authority |
| 派系 | 外交 | ALLIED_WITH | Faction→Faction | 含 treaty_type/status |
| 派系 | 敌对 | HOSTILE_WITH | Faction→Faction | 含 conflict_level |
| 派系 | 控制 | CONTROLS | Faction→Location | 含 influence_level |
| 地点 | 空间包含 | CONTAINS | Location→Location | 层级，从大到小 |
| 地点 | 路线 | ROUTE | Location→Location | 含 travel_method/time_cost/danger_level/vehicle_ref；warp航行含 warp_time_variance/warp_encounter_risk/navigator_required |
| 偏离追踪 | 影响 | IMPACTS | DeviationRecord→(Character/Faction/Event) | 偏离的三级影响传播链路 |
| 偏离追踪 | 受偏离影响 | AFFECTED_BY | Event→DeviationRecord | 标记下游事件受哪次偏离影响 |
| 事件 | 参与 | PARTICIPATED_IN | Character→Event | 含 role/impact |
| 事件 | 发生地 | HAPPENED_AT | Event→Location | |
| 剧情线 | 推进 | ADVANCED_BY | Event→PlotThread | 含 narrative_weight |
| 剧情线 | 关联 | RELATED_TO | PlotThread→PlotThread | 主线/支线关系 |
| 剧情线 | 伏笔兑现 | FORETOLD_BY | Event→Foreshadowing | 伏笔兑现关联 |
| 桥接 | 穿越记录 | CROSSED_THROUGH | Character→World | 含 carry_items/compatibility |
| 桥接 | 物品穿越 | CARRIED_ACROSS | Item→World | 含 compatibility_level/mapping |
| 物品 | 转让 | TRANSFERRED_TO | Character→Character（on Item） | 含 item_ref/unified_time/trigger_event |
| 规则 | 适用 | APPLIES_TO | OracleRule→World | 规则适用的世界 |
| 规则 | 场景绑定 | ACTIVE_IN | OracleRule→SceneRuleSet | 场景规则包绑定 |

### 3.3 关系变化日志

KNOWS 边只存当前快照。每次变化由独立的 RelationshipEvent 记录：

```
RelationshipEvent:
  from_char / to_char : 关系主体
  unified_time / local_time : 双时间轴
  trigger_desc : 什么事件导致变化
  changes : [{ field, from, to }]  — 一次可改多个字段
  perception : 角色对此变化的主观感受
```

### 3.4 域特定 Vertex 类型定义

#### 3.4.1 宇宙域（World）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| World | world_id (key), display_name, type (canon/fanon/original), timeline_anchor, description, aliases | UNIQUE on world_id |
| WorldCognitionTemplate | template_id (key), world_ref, social_class, geo_scope, knowledge_domains (LIST), rumor_exposure | UNIQUE on template_id |

#### 3.4.2 角色域（Character + CharacterSnapshot + CognitionRecord）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| Character | character_id (key), display_name, aliases, character_origin, is_party_member, party_join_date, species, birth_date, gender, sexuality, chronological_age, apparent_age, height, hair_color, distinguishing_features (LIST), appearance_summary, typical_attire, nationality, social_class, occupation, origin_world, tags (LIST), languages_spoken (LIST), world_travel_history (LIST), default_cognition, personality_tags (LIST), core_motivation, secret, voice, speech_constraints (LIST), background, voice_profile (JSON), canon_awareness (JSON) | UNIQUE on character_id; FULL_TEXT on display_name |
| CharacterSnapshot | character_ref, chapter_ref, location, gender, sexuality, chronological_age, apparent_age, height, hair_color, distinguishing_features (LIST), appearance_summary, typical_attire, nationality, social_class, occupation, physical, psychology, items (LIST), summary | 索引 on (character_ref, chapter_ref) |

#### 3.4.3 派系域（Faction）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| Faction | faction_id (key), display_name, aliases, type, resources (JSON), hierarchy_parent, influence_score (0-100) | UNIQUE on faction_id |

#### 3.4.4 地点域（Location + Vehicle）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| Location | location_id (key), display_name, aliases, coordinates (WKT POINT), location_type, sensory_detail | UNIQUE on location_id; GEOSPATIAL on coordinates |
| Vehicle | vehicle_id (key), type (horse/car/spaceship/portal), speed_kmh, range_km, capacity, special (JSON), world | UNIQUE on vehicle_id |

#### 3.4.5 事件域（Event + CanonEvent + DeviationRecord）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| Event | event_id (key), display_name, description, timeline_pos, date_label, time_flexibility | UNIQUE on event_id |
| CanonEvent | extends Event, canon_level (core/major/minor), source_id | UNIQUE on event_id |
| CanonEventStatus | canon_event_ref, status (pending/triggered/modified/skipped), actual_description, divergence_reason, occurred_in_chapter | 索引 on (canon_event_ref, status) |
| DeviationRecord | record_id (key), source_event_ref, world_ref, status, divergence_reason, occurred_in_chapter, character_impacts (JSON), faction_impacts (JSON), plot_impacts (JSON), broken_chains (LIST) | UNIQUE on record_id; 索引 on source_event_ref |
| CognitionRecord | record_id (key), character_ref, fact_id, fact_type, source_type, confidence, acquired_session, is_conflicted, current_belief, is_false | UNIQUE on record_id; 索引 on character_ref |

#### 3.4.6 剧情线域（PlotThread + Foreshadowing）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| PlotThread | thread_id (key), display_name, status (active/dormant/resolved), narrative_weight, foreshadowing[], ending_conditions (JSON) | UNIQUE on thread_id |
| Foreshadowing | code (key), f_type (情感/身份/事件/道具), description, planted_chapter, resolved_chapter, characters | UNIQUE on code |

#### 3.4.7 桥接域（BridgeMapping）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| BridgeEntry | entry_id (key), item_name, item_category, source_world, target_world, compatibility (full/degraded/reinterpreted/disabled), effect_description, stat_modifiers (JSON), local_name, local_understanding, misconceptions (LIST), reveal_triggers (LIST), perception_difficulty | UNIQUE on entry_id; 索引 on (source_world, target_world) |

#### 3.4.8 规则域（OracleRule + SceneRuleSet）

| Vertex 类型 | 关键属性 | 索引 |
|------|------|:----:|
| OracleRule | rule_id (key), display_name, rule_type, description, formula (JSON), oracle_table (JSON) | UNIQUE on rule_id; FULL_TEXT on description |
| SceneRuleSet | set_id (key), display_name, scene_type, rules (JSON list) | UNIQUE on set_id |

### 3.5 偏离级联查询模式

同人世界事件偏离后，通过图遍历追踪三级影响传播的典型查询模式：

**一级：沿 CAUSES 边下游传播（剧情影响）**
```sql
SELECT expand(traverse()) FROM (SELECT FROM CanonEvent WHERE event_id = :divergedEventId) WHILE $depth <= 10
```

**二级：沿 PARTICIPATED_IN 到角色，再沿 KNOWS 展开（人物影响）**
```sql
-- 找出参与偏离事件的所有角色
SELECT expand(in('PARTICIPATED_IN')) FROM CanonEvent WHERE event_id = :divergedEventId;
-- 展开受影响角色关系网
SELECT expand(out('KNOWS')) FROM Character WHERE character_id IN :affectedCharIds;
```

**三级：沿 BELONGS_TO → CONTROLS/ALLIED_WITH 上溯（政治影响）**
```sql
SELECT expand(out('BELONGS_TO').out('CONTROLS')) FROM Character WHERE character_id IN :affectedCharIds;
```

**偏离报告聚合查询**
```sql
SELECT record_id, source_event_ref, status, divergence_reason, character_impacts, faction_impacts, plot_impacts, broken_chains FROM DeviationRecord WHERE world_ref = :fanonWorldId ORDER BY occurred_in_chapter ASC;
```

---

## 四、文本域设计模式

### 4.1 结构

长篇文本使用 Vertex 类型（需要向量搜索的主要文本域）或 Document 类型：

| 类型 | 推荐模型 | 字段 |
|------|:--:|------|
| 世界观设定 | Vertex | content, embedding (1024d) |
| 跑团日志 | Vertex | content（叙事正文）, transcript（对话转录）, embedding, session_date |
| 小说章节 | Vertex | content, embedding, pov_character, style, corresponding_session, canon_checked, status (draft/published) |
| 规则文档 | Document | content |
| 物品描述 | Document | content, embedding |

### 4.2 向量化原则

- 仅对**叙事正文**向量化，对话转录（transcript）不参与向量搜索
- 所有向量字段用 `ARRAY_OF_FLOATS` 类型
- Vertex 的向量用 `EXTERNAL true` 将嵌入存外置 bucket，加速图遍历

---

## 五、索引策略

### 5.1 索引类型选择

| 索引类型 | 使用场景 | 示例 |
|------|------|------|
| `UNIQUE` | 业务主键 | `character_id`, `faction_id` |
| `FULL_TEXT` | 中文全文搜索 | 实体描述字段 + 文本域 content |
| `LSM_VECTOR` | 语义搜索（1024d COSINE） | 文本域（设定/日志/章节） |
| `GEOSPATIAL` | 空间范围查询 | 地点的 coordinates（WKT POINT） |

> **语义搜索策略说明**：图域实体（World、Character、Event 等）的语义搜索通过关联的文本域间接实现——搜索词在 LoreDocument（世界观设定）、SessionLog（跑团日志）中做向量相似度匹配，命中结果后回溯到对应图实体。图域 Vertex 本身不存储 embedding。需要字段级关键词搜索的图域实体使用 FULL_TEXT 索引。

### 5.2 LSM_VECTOR 推荐参数

```sql
CREATE INDEX ON [type] (embedding) LSM_VECTOR
  METADATA {
    "dimensions": 1024,
    "similarity": "COSINE",
    "quantization": "INT8",
    "maxConnections": 16,
    "beamWidth": 100
  };
```

- `quantization: "INT8"` — 内存 4KB→1KB/条，检索快 2.5x，召回率损失 < 2%
- `maxConnections: 16, beamWidth: 100` — 平衡精度与速度的默认值

> 如果你的向量模型不是 bge-m3 1024 维，修改 `dimensions` 即可。

### 5.3 GEOSPATIAL

```
CREATE PROPERTY Location.coordinates STRING;
CREATE INDEX ON Location (coords) GEOSPATIAL;

-- 查询：polygon 包围盒
WHERE geo.within(coords, geo.geomFromText('POLYGON((...))')) = true
```

---

## 六、向量搜索 + 混合检索

### 6.1 纯向量搜索

```sql
SELECT expand(vector.neighbors('[type][embedding]', :queryVec, 5));
```

### 6.2 混合检索：vector.fuse（推荐，26.5.1+）

一条 SQL 服务端融合稠密向量 + BM25 全文：

```sql
SELECT expand(`vector.fuse`(
    `vector.neighbors`('[type][embedding]', :qVec, 50),
    (SELECT @rid, $score FROM [type]
     WHERE SEARCH_INDEX('[type][content]', :keywords) = true),
    { fusion: 'RRF' }
)) LIMIT 10;
```

**融合策略**：
- `RRF`（默认）— 来源分数分布差异大时最安全
- `DBSF` — 来源分数近似高斯分布
- `LINEAR` — 离线已调好权重

### 6.3 嵌入生成

```
文本 → ollama bge-m3 → 1024维 FLOAT32 → ArcadeDB（INT8 量化存储）
```

---

## 七、运行时状态

轻量 Document，跑团开始加载、结束时写回：

```json
{
  "chaos": 5,
  "current_world": "[world-id]",
  "current_location": "[location-id]",
  "current_time": "[本地时间]",
  "current_season": "summer",
  "unified_year": "UC+9947",
  "active_party": ["[char1]", "[char2]"],
  "nearby_npcs": ["[npc1]"],
  "active_threads": ["[thread1]"],
  "active_oracle": { "combat": "shared", "fate_chart": "shared" },
  "recent_events": ["[...]"],
  "imminent_threats": ["[...]"],
  "narrative_mode": "third_person_limited",
  "chapter_outline": ["[大纲要点]"],
  "novel_gen_status": "idle"
}
```

---

## 八、DDL 模板

> 以下是基于 project-design.md 的完整 DDL 定义。以 `[Name]` 占位符表示待补充的具体名称。

### 8.1 Vertex 类型创建

#### 宇宙域

```sql
CREATE VERTEX TYPE World IF NOT EXISTS;
CREATE PROPERTY World.world_id STRING;
CREATE PROPERTY World.display_name STRING;
CREATE PROPERTY World.type STRING;       -- canon / fanon / original
CREATE PROPERTY World.timeline_anchor STRING;
CREATE PROPERTY World.description STRING;
CREATE PROPERTY World.aliases LIST;
CREATE INDEX ON World (world_id) UNIQUE;
CREATE INDEX ON World (description) FULL_TEXT;
CREATE INDEX ON World (timeline_anchor) NOTUNIQUE;

CREATE VERTEX TYPE Channel IF NOT EXISTS;
CREATE PROPERTY Channel.channel_id STRING;
CREATE PROPERTY Channel.stability INTEGER;   -- 1-10
CREATE PROPERTY Channel.energy_cost STRING;
CREATE PROPERTY Channel.one_way BOOLEAN;
CREATE PROPERTY Channel.channel_type STRING;  -- dimensional_bridge / parallel_world / cross_work_voyage
CREATE INDEX ON Channel (channel_id) UNIQUE;

-- 世界阶层认知模板
CREATE VERTEX TYPE WorldCognitionTemplate IF NOT EXISTS;
CREATE PROPERTY WorldCognitionTemplate.template_id STRING;
CREATE PROPERTY WorldCognitionTemplate.world_ref STRING;
CREATE PROPERTY WorldCognitionTemplate.social_class STRING;  -- peasant/citizen/noble/scholar
CREATE PROPERTY WorldCognitionTemplate.geo_scope STRING;
CREATE PROPERTY WorldCognitionTemplate.knowledge_domains LIST;
CREATE PROPERTY WorldCognitionTemplate.rumor_exposure STRING;  -- high/medium/low
CREATE INDEX ON WorldCognitionTemplate (template_id) UNIQUE;
```

#### 角色域

```sql
CREATE VERTEX TYPE Character IF NOT EXISTS;
CREATE PROPERTY Character.character_id STRING;
CREATE PROPERTY Character.display_name STRING;
CREATE PROPERTY Character.aliases LIST;
CREATE PROPERTY Character.character_origin STRING;      -- canon / fanon / original
CREATE PROPERTY Character.is_party_member BOOLEAN;      -- 是否在主角团
CREATE PROPERTY Character.party_join_date STRING;        -- 加入主角团时间
CREATE PROPERTY Character.species STRING;             -- 人类/精灵/突变体/AI
CREATE PROPERTY Character.birth_date STRING;          -- 本地历
CREATE PROPERTY Character.gender STRING;
CREATE PROPERTY Character.sexuality STRING;
CREATE PROPERTY Character.chronological_age INTEGER;   -- 当前年龄
CREATE PROPERTY Character.apparent_age INTEGER;        -- 当前外貌年龄
CREATE PROPERTY Character.height STRING;               -- 当前身高
CREATE PROPERTY Character.hair_color STRING;           -- 当前发色
CREATE PROPERTY Character.distinguishing_features LIST; -- 当前明显特征
CREATE PROPERTY Character.appearance_summary STRING;   -- 当前样貌概述
CREATE PROPERTY Character.typical_attire STRING;       -- 当前衣着
CREATE PROPERTY Character.nationality STRING;
CREATE PROPERTY Character.social_class STRING;
CREATE PROPERTY Character.occupation STRING;
CREATE PROPERTY Character.origin_world STRING;
CREATE PROPERTY Character.tags LIST;                  -- 纯标签系统
CREATE PROPERTY Character.languages_spoken LIST;       -- 语言能力
CREATE PROPERTY Character.world_travel_history LIST;   -- 去过哪些世界
CREATE PROPERTY Character.default_cognition STRING;    -- 认知基线
CREATE PROPERTY Character.personality_tags LIST;       -- 性格标签 [冲动,忠诚,多疑]
CREATE PROPERTY Character.core_motivation STRING;      -- 核心动机
CREATE PROPERTY Character.secret STRING;               -- 秘密背景
CREATE PROPERTY Character.voice STRING;                 -- 说话方式
CREATE PROPERTY Character.speech_constraints LIST;      -- 禁忌话题列表
CREATE PROPERTY Character.background STRING;            -- 完整背景故事
CREATE PROPERTY Character.voice_profile JSON;           -- 声线资料，未来 TTS 用：{timbre, pitch_range, pace, accent, emotional_default}
CREATE PROPERTY Character.canon_awareness JSON;        -- 认知范围
CREATE PROPERTY Character.corruption_level INTEGER;     -- 腐蚀值 0-100（40K）
CREATE PROPERTY Character.mutation_manifestations LIST;  -- 变异列表
CREATE PROPERTY Character.heresy_conviction INTEGER;     -- 异端信念 0-100
CREATE INDEX ON Character (character_id) UNIQUE;
CREATE INDEX ON Character (display_name) FULL_TEXT;

CREATE VERTEX TYPE CharacterSnapshot IF NOT EXISTS;
CREATE PROPERTY CharacterSnapshot.character_ref STRING;
CREATE PROPERTY CharacterSnapshot.chapter_ref INTEGER;
CREATE PROPERTY CharacterSnapshot.location STRING;
CREATE PROPERTY CharacterSnapshot.gender STRING;
CREATE PROPERTY CharacterSnapshot.sexuality STRING;
CREATE PROPERTY CharacterSnapshot.chronological_age INTEGER;
CREATE PROPERTY CharacterSnapshot.apparent_age INTEGER;    -- 外貌年龄
CREATE PROPERTY CharacterSnapshot.height STRING;
CREATE PROPERTY CharacterSnapshot.hair_color STRING;
CREATE PROPERTY CharacterSnapshot.distinguishing_features LIST;
CREATE PROPERTY CharacterSnapshot.appearance_summary STRING;
CREATE PROPERTY CharacterSnapshot.typical_attire STRING;
CREATE PROPERTY CharacterSnapshot.nationality STRING;
CREATE PROPERTY CharacterSnapshot.social_class STRING;
CREATE PROPERTY CharacterSnapshot.occupation STRING;
CREATE PROPERTY CharacterSnapshot.physical STRING;
CREATE PROPERTY CharacterSnapshot.psychology STRING;
CREATE PROPERTY CharacterSnapshot.items LIST;
CREATE PROPERTY CharacterSnapshot.summary STRING;
```

#### 派系域

```sql
CREATE VERTEX TYPE Faction IF NOT EXISTS;
CREATE PROPERTY Faction.faction_id STRING;
CREATE PROPERTY Faction.display_name STRING;
CREATE PROPERTY Faction.aliases LIST;
CREATE PROPERTY Faction.type STRING;
CREATE PROPERTY Faction.resources JSON;
CREATE PROPERTY Faction.hierarchy_parent STRING;
CREATE PROPERTY Faction.influence_score INTEGER;  -- 影响力 0-100
CREATE INDEX ON Faction (faction_id) UNIQUE;
```

#### 地点域

```sql
CREATE VERTEX TYPE Location IF NOT EXISTS;
CREATE PROPERTY Location.location_id STRING;
CREATE PROPERTY Location.display_name STRING;
CREATE PROPERTY Location.aliases LIST;
CREATE PROPERTY Location.coordinates STRING;  -- WKT POINT
CREATE PROPERTY Location.location_type STRING;
CREATE PROPERTY Location.sensory_detail STRING;
CREATE INDEX ON Location (location_id) UNIQUE;
CREATE INDEX ON Location (display_name) FULL_TEXT;
CREATE INDEX ON Location (coordinates) GEOSPATIAL;

-- 交通工具
CREATE VERTEX TYPE Vehicle IF NOT EXISTS;
CREATE PROPERTY Vehicle.vehicle_id STRING;
CREATE PROPERTY Vehicle.type STRING;         -- horse/car/spaceship/broom/portal
CREATE PROPERTY Vehicle.speed_kmh FLOAT;
CREATE PROPERTY Vehicle.range_km FLOAT;
CREATE PROPERTY Vehicle.capacity INTEGER;
CREATE PROPERTY Vehicle.special JSON;        -- {warp_drive: true, warp_factor: 9}
CREATE PROPERTY Vehicle.world STRING;
CREATE INDEX ON Vehicle (vehicle_id) UNIQUE;

-- 舰船（40K/太空歌剧）
CREATE VERTEX TYPE Ship IF NOT EXISTS;
CREATE PROPERTY Ship.ship_id STRING;
CREATE PROPERTY Ship.type STRING;          -- frigate/destroyer/cruiser/battleship
CREATE PROPERTY Ship.hull_points INTEGER;
CREATE PROPERTY Ship.shield_strength INTEGER;
CREATE PROPERTY Ship.weapon_systems JSON;
CREATE PROPERTY Ship.crew_complement INTEGER;
CREATE PROPERTY Ship.special JSON;
CREATE INDEX ON Ship (ship_id) UNIQUE;

-- 舰队
CREATE VERTEX TYPE Fleet IF NOT EXISTS;
CREATE PROPERTY Fleet.fleet_id STRING;
CREATE PROPERTY Fleet.ships LIST;
CREATE PROPERTY Fleet.flagship STRING;
CREATE PROPERTY Fleet.fleet_power INTEGER;
CREATE PROPERTY Fleet.admiral_ref STRING;
CREATE INDEX ON Fleet (fleet_id) UNIQUE;
```

#### 事件域

```sql
CREATE VERTEX TYPE Event IF NOT EXISTS;
CREATE PROPERTY Event.event_id STRING;
CREATE PROPERTY Event.display_name STRING;
CREATE PROPERTY Event.description STRING;
CREATE PROPERTY Event.timeline_pos STRING;
CREATE PROPERTY Event.date_label STRING;
CREATE PROPERTY Event.time_flexibility STRING;
CREATE INDEX ON Event (event_id) UNIQUE;
CREATE INDEX ON Event (display_name) FULL_TEXT;

CREATE VERTEX TYPE CanonEvent IF NOT EXISTS;
-- 继承自 Event，额外字段：
CREATE PROPERTY CanonEvent.canon_level STRING;   -- core / major / minor
CREATE PROPERTY CanonEvent.source_id STRING;

CREATE VERTEX TYPE CanonEventStatus IF NOT EXISTS;
CREATE PROPERTY CanonEventStatus.canon_event_ref STRING;
CREATE PROPERTY CanonEventStatus.status STRING;  -- pending / triggered / modified / skipped
CREATE PROPERTY CanonEventStatus.actual_description STRING;
CREATE PROPERTY CanonEventStatus.divergence_reason STRING;
CREATE PROPERTY CanonEventStatus.occurred_in_chapter INTEGER;

-- 偏离记录（同人世界每次偏离生成一条）
CREATE VERTEX TYPE DeviationRecord IF NOT EXISTS;
CREATE PROPERTY DeviationRecord.record_id STRING;
CREATE PROPERTY DeviationRecord.source_event_ref STRING;  -- 被偏离的正典事件
CREATE PROPERTY DeviationRecord.world_ref STRING;          -- 发生在哪个同人世界
CREATE PROPERTY DeviationRecord.status STRING;             -- modified / skipped
CREATE PROPERTY DeviationRecord.divergence_reason STRING;
CREATE PROPERTY DeviationRecord.occurred_in_chapter INTEGER;
CREATE PROPERTY DeviationRecord.character_impacts JSON;    -- [{char_id, impact_summary}]
CREATE PROPERTY DeviationRecord.faction_impacts JSON;      -- [{faction_id, impact_summary}]
CREATE PROPERTY DeviationRecord.plot_impacts JSON;         -- [{event_id, impact_summary}]
CREATE PROPERTY DeviationRecord.broken_chains LIST;        -- [event_id, ...] 断裂的因果链端点
CREATE PROPERTY DeviationRecord.changed_aspects JSON;     -- ["participants","outcome","timing",...] 偏离的侧面
CREATE INDEX ON DeviationRecord (record_id) UNIQUE;
CREATE INDEX ON DeviationRecord (source_event_ref) NOTUNIQUE;

-- 认知记录（三维认知模型）
CREATE VERTEX TYPE CognitionRecord IF NOT EXISTS;
CREATE PROPERTY CognitionRecord.record_id STRING;
CREATE PROPERTY CognitionRecord.character_ref STRING;
CREATE PROPERTY CognitionRecord.fact_id STRING;
CREATE PROPERTY CognitionRecord.fact_type STRING;       -- event/item/character/location/concept
CREATE PROPERTY CognitionRecord.source_type STRING;     -- eyewitness / hearsay / literature / speculation
CREATE PROPERTY CognitionRecord.confidence INTEGER;     -- 0-100
CREATE PROPERTY CognitionRecord.acquired_session STRING;
CREATE PROPERTY CognitionRecord.is_conflicted BOOLEAN;  -- 是否有认知冲突
CREATE PROPERTY CognitionRecord.current_belief STRING;  -- 当前相信的版本
CREATE PROPERTY CognitionRecord.is_false BOOLEAN;       -- 已被证伪
CREATE INDEX ON CognitionRecord (record_id) UNIQUE;
CREATE INDEX ON CognitionRecord (character_ref) NOTUNIQUE;
```

#### 剧情线域

```sql
CREATE VERTEX TYPE PlotThread IF NOT EXISTS;
CREATE PROPERTY PlotThread.thread_id STRING;
CREATE PROPERTY PlotThread.display_name STRING;
CREATE PROPERTY PlotThread.status STRING;          -- active / dormant / resolved
CREATE PROPERTY PlotThread.narrative_weight INTEGER;
CREATE PROPERTY PlotThread.foreshadowing LIST;
CREATE PROPERTY PlotThread.ending_conditions JSON;
CREATE INDEX ON PlotThread (thread_id) UNIQUE;
CREATE INDEX ON PlotThread (display_name) FULL_TEXT;

CREATE VERTEX TYPE Foreshadowing IF NOT EXISTS;
CREATE PROPERTY Foreshadowing.code STRING;
CREATE PROPERTY Foreshadowing.f_type STRING;       -- 情感 / 身份 / 事件 / 道具
CREATE PROPERTY Foreshadowing.description STRING;
CREATE PROPERTY Foreshadowing.planted_chapter INTEGER;
CREATE PROPERTY Foreshadowing.resolved_chapter INTEGER;
CREATE PROPERTY Foreshadowing.characters LIST;
CREATE INDEX ON Foreshadowing (code) UNIQUE;
```

#### 桥接域

```sql
CREATE VERTEX TYPE BridgeEntry IF NOT EXISTS;
CREATE PROPERTY BridgeEntry.entry_id STRING;
CREATE PROPERTY BridgeEntry.item_name STRING;
CREATE PROPERTY BridgeEntry.item_category STRING;     -- magical_weapon / mundane / technology
CREATE PROPERTY BridgeEntry.source_world STRING;
CREATE PROPERTY BridgeEntry.target_world STRING;
CREATE PROPERTY BridgeEntry.compatibility STRING;     -- full / degraded / reinterpreted / disabled
CREATE PROPERTY BridgeEntry.effect_description STRING;
CREATE PROPERTY BridgeEntry.stat_modifiers JSON;      -- {"power": -2, "duration": "halved"}
CREATE PROPERTY BridgeEntry.local_name STRING;
CREATE PROPERTY BridgeEntry.local_understanding STRING;
CREATE PROPERTY BridgeEntry.misconceptions LIST;
CREATE PROPERTY BridgeEntry.reveal_triggers LIST;
CREATE PROPERTY BridgeEntry.perception_difficulty STRING;  -- easy / medium / hard
CREATE INDEX ON BridgeEntry (entry_id) UNIQUE;
CREATE INDEX ON BridgeEntry (source_world, target_world) NOTUNIQUE;
```

#### 规则域

```sql
CREATE VERTEX TYPE OracleRule IF NOT EXISTS;
CREATE PROPERTY OracleRule.rule_id STRING;
CREATE PROPERTY OracleRule.display_name STRING;
CREATE PROPERTY OracleRule.rule_type STRING;
CREATE PROPERTY OracleRule.description STRING;
CREATE PROPERTY OracleRule.formula JSON;
CREATE PROPERTY OracleRule.oracle_table JSON;
CREATE INDEX ON OracleRule (rule_id) UNIQUE;
CREATE INDEX ON OracleRule (description) FULL_TEXT;

CREATE VERTEX TYPE SceneRuleSet IF NOT EXISTS;
CREATE PROPERTY SceneRuleSet.set_id STRING;
CREATE PROPERTY SceneRuleSet.display_name STRING;
CREATE PROPERTY SceneRuleSet.scene_type STRING;
CREATE PROPERTY SceneRuleSet.rules LIST;
CREATE INDEX ON SceneRuleSet (set_id) UNIQUE;

-- 怪物/生物
CREATE VERTEX TYPE Monster IF NOT EXISTS;
CREATE PROPERTY Monster.monster_id STRING;
CREATE PROPERTY Monster.display_name STRING;
CREATE PROPERTY Monster.species STRING;
CREATE PROPERTY Monster.threat_level INTEGER;
CREATE PROPERTY Monster.habitat STRING;
CREATE PROPERTY Monster.weaknesses LIST;
CREATE PROPERTY Monster.abilities LIST;
CREATE PROPERTY Monster.typical_bounty STRING;
CREATE PROPERTY Monster.loot LIST;
CREATE INDEX ON Monster (monster_id) UNIQUE;

-- 战役/冲突
CREATE VERTEX TYPE Conflict IF NOT EXISTS;
CREATE PROPERTY Conflict.conflict_id STRING;
CREATE PROPERTY Conflict.type STRING;
CREATE PROPERTY Conflict.belligerents LIST;
CREATE PROPERTY Conflict.front_line LIST;
CREATE PROPERTY Conflict.status STRING;
CREATE PROPERTY Conflict.controlled_zones JSON;
CREATE PROPERTY Conflict.key_battles LIST;
CREATE INDEX ON Conflict (conflict_id) UNIQUE;

-- 契约/任务
CREATE VERTEX TYPE Contract IF NOT EXISTS;
CREATE PROPERTY Contract.contract_id STRING;
CREATE PROPERTY Contract.type STRING;
CREATE PROPERTY Contract.giver STRING;
CREATE PROPERTY Contract.target STRING;
CREATE PROPERTY Contract.reward STRING;
CREATE PROPERTY Contract.status STRING;
CREATE PROPERTY Contract.deadline STRING;
CREATE INDEX ON Contract (contract_id) UNIQUE;

-- 物品
CREATE VERTEX TYPE Item IF NOT EXISTS;
CREATE PROPERTY Item.item_id STRING;
CREATE PROPERTY Item.name STRING;
CREATE PROPERTY Item.category STRING;       -- weapon/armor/consumable/artifact/misc
CREATE PROPERTY Item.properties JSON;        -- {"damage":"1d8","ammo":3}
CREATE PROPERTY Item.origin_world STRING;
CREATE PROPERTY Item.description STRING;
CREATE PROPERTY Item.quantity INTEGER;
CREATE PROPERTY Item.condition STRING;       -- normal/damaged/needs_repair
CREATE INDEX ON Item (item_id) UNIQUE;
```

### 8.2 Edge 类型创建

```sql
-- 宇宙域
CREATE EDGE TYPE CONNECTS_TO IF NOT EXISTS;         -- World→Channel→World（通道属性存于 Channel Vertex）
CREATE EDGE TYPE COMPATIBILITY_RULE IF NOT EXISTS;  -- World→World
CREATE EDGE TYPE COGNITIVE_MAP IF NOT EXISTS;       -- World→World（语义标记，数据存于 BridgeEntry）

-- 角色域
CREATE EDGE TYPE KNOWS IF NOT EXISTS;               -- Character→Character
CREATE EDGE TYPE HAS_SNAPSHOT IF NOT EXISTS;        -- Character→CharacterSnapshot

-- 派系域
CREATE EDGE TYPE BELONGS_TO IF NOT EXISTS;          -- Character→Faction
CREATE EDGE TYPE ALLIED_WITH IF NOT EXISTS;         -- Faction→Faction
CREATE EDGE TYPE HOSTILE_WITH IF NOT EXISTS;        -- Faction→Faction
CREATE EDGE TYPE CONTROLS IF NOT EXISTS;            -- Faction→Location
CREATE EDGE TYPE NEGOTIATES_WITH IF NOT EXISTS;     -- Faction→Faction（细粒度外交，含 diplomatic_status/status_since/mutual_threat/ideological_alignment）

-- 地点域
CREATE EDGE TYPE CONTAINS IF NOT EXISTS;            -- Location→Location
CREATE EDGE TYPE ROUTE IF NOT EXISTS;               -- Location→Location（含 travel_method/time_cost/danger_level/vehicle_ref）

-- 事件域
CREATE EDGE TYPE CAUSES IF NOT EXISTS;              -- Event→Event
CREATE EDGE TYPE PARTICIPATED_IN IF NOT EXISTS;     -- Character→Event
CREATE EDGE TYPE HAPPENED_AT IF NOT EXISTS;         -- Event→Location

-- 偏离追踪域
CREATE EDGE TYPE IMPACTS IF NOT EXISTS;             -- DeviationRecord→Character/Faction/Event
CREATE EDGE TYPE AFFECTED_BY IF NOT EXISTS;         -- Event→DeviationRecord

-- 剧情线域
CREATE EDGE TYPE ADVANCED_BY IF NOT EXISTS;         -- Event→PlotThread
CREATE EDGE TYPE RELATED_TO IF NOT EXISTS;          -- PlotThread→PlotThread
CREATE EDGE TYPE FORETOLD_BY IF NOT EXISTS;         -- Event→Foreshadowing

-- 桥接域
CREATE EDGE TYPE CROSSED_THROUGH IF NOT EXISTS;     -- Character→World
CREATE EDGE TYPE CARRIED_ACROSS IF NOT EXISTS;      -- BridgeEntry→World

-- 物品域
CREATE EDGE TYPE EQUIPPED_BY IF NOT EXISTS;         -- Item→Character
CREATE EDGE TYPE CREATED_AT IF NOT EXISTS;          -- Item→Event
CREATE EDGE TYPE TRANSFERRED_TO IF NOT EXISTS;      -- Character→Character（on Item，含 item_ref/unified_time/trigger_event）

-- 规则域
CREATE EDGE TYPE APPLIES_TO IF NOT EXISTS;          -- OracleRule→World
CREATE EDGE TYPE ACTIVE_IN IF NOT EXISTS;           -- OracleRule→SceneRuleSet
```

### 8.3 Document 类型

```sql
CREATE DOCUMENT TYPE RunState IF NOT EXISTS;

CREATE DOCUMENT TYPE RuleDocument IF NOT EXISTS;
CREATE PROPERTY RuleDocument.content STRING;
CREATE INDEX ON RuleDocument (content) FULL_TEXT;

CREATE DOCUMENT TYPE TurnCheckpoint IF NOT EXISTS;
CREATE PROPERTY TurnCheckpoint.checkpoint_id STRING;
CREATE PROPERTY TurnCheckpoint.session_id STRING;
CREATE PROPERTY TurnCheckpoint.turn INTEGER;
CREATE PROPERTY TurnCheckpoint.events_added LIST;
CREATE PROPERTY TurnCheckpoint.cognition_added LIST;
CREATE PROPERTY TurnCheckpoint.knows_snapshots JSON;
CREATE PROPERTY TurnCheckpoint.runstate_before JSON;
CREATE INDEX ON TurnCheckpoint (checkpoint_id) UNIQUE;
```

### 8.4 文本 Vertex（带向量索引）

```sql
-- 世界观设定
CREATE VERTEX TYPE LoreDocument IF NOT EXISTS;
CREATE PROPERTY LoreDocument.content STRING;
CREATE PROPERTY LoreDocument.embedding ARRAY_OF_FLOATS (EXTERNAL true);
CREATE INDEX ON LoreDocument (content) FULL_TEXT;
CREATE INDEX ON LoreDocument (embedding) LSM_VECTOR METADATA {
  "dimensions": 1024,
  "similarity": "COSINE",
  "quantization": "INT8",
  "maxConnections": 16,
  "beamWidth": 100
};

-- 跑团日志
CREATE VERTEX TYPE SessionLog IF NOT EXISTS;
CREATE PROPERTY SessionLog.content STRING;
CREATE PROPERTY SessionLog.transcript STRING;
CREATE PROPERTY SessionLog.session_date DATE;
CREATE PROPERTY SessionLog.embedding ARRAY_OF_FLOATS (EXTERNAL true);
CREATE INDEX ON SessionLog (content) FULL_TEXT;
CREATE INDEX ON SessionLog (embedding) LSM_VECTOR METADATA {
  "dimensions": 1024,
  "similarity": "COSINE",
  "quantization": "INT8",
  "maxConnections": 16,
  "beamWidth": 100
};

-- 小说章节
CREATE VERTEX TYPE NovelChapter IF NOT EXISTS;
CREATE PROPERTY NovelChapter.content STRING;
CREATE PROPERTY NovelChapter.pov_character STRING;
CREATE PROPERTY NovelChapter.style STRING;
CREATE PROPERTY NovelChapter.corresponding_session STRING;
CREATE PROPERTY NovelChapter.canon_checked BOOLEAN;
CREATE PROPERTY NovelChapter.status STRING;            -- draft / published
CREATE PROPERTY NovelChapter.embedding ARRAY_OF_FLOATS (EXTERNAL true);
CREATE INDEX ON NovelChapter (content) FULL_TEXT;
CREATE INDEX ON NovelChapter (status) NOTUNIQUE;
CREATE INDEX ON NovelChapter (embedding) LSM_VECTOR METADATA {
  "dimensions": 1024,
  "similarity": "COSINE",
  "quantization": "INT8",
  "maxConnections": 16,
  "beamWidth": 100
};
```

### 8.5 索引策略汇总

| Vertex/Document 类型 | 索引字段 | 索引类型 | 目的 |
|------|------|:-------:|------|
| World | world_id | UNIQUE | 精确查找 |
| World | description | FULL_TEXT | 世界设定检索 |
| World | timeline_anchor | NOTUNIQUE | 时间线锚点查询 |
| Character | character_id | UNIQUE | 精确查找 |
| Character | display_name | FULL_TEXT | 中文搜索 |
| Location | location_id | UNIQUE | 精确查找 |
| Location | display_name | FULL_TEXT | 地点名称搜索 |
| Location | coordinates | GEOSPATIAL | 空间查询 |
| Event / CanonEvent | event_id | UNIQUE | 精确查找 |
| Event | display_name | FULL_TEXT | 事件名称搜索 |
| PlotThread | thread_id | UNIQUE | 精确查找 |
| PlotThread | display_name | FULL_TEXT | 剧情线名称搜索 |
| Foreshadowing | code | UNIQUE | 伏笔管理 |
| BridgeEntry | (source_world, target_world) | NOTUNIQUE | 跨世界快速查询 |
| Vehicle | vehicle_id | UNIQUE | 精确查找 |
| OracleRule | rule_id | UNIQUE | 精确查找 |
| OracleRule | description | FULL_TEXT | 规则搜索 |
| LoreDocument | content | FULL_TEXT | 设定检索 |
| LoreDocument | embedding | LSM_VECTOR | 语义检索 |
| SessionLog | content | FULL_TEXT | 日志检索 |
| SessionLog | embedding | LSM_VECTOR | 语义检索 |
| NovelChapter | content | FULL_TEXT | 章节检索 |
| NovelChapter | embedding | LSM_VECTOR | 语义检索 |
| NovelChapter | status | NOTUNIQUE | 筛选草稿/已发布 |
| CanonEventStatus | (canon_event_ref, status) | NOTUNIQUE | 偏离追踪 |
| DeviationRecord | record_id | UNIQUE | 精确查找 |
| DeviationRecord | source_event_ref | NOTUNIQUE | 按源事件查偏离 |
| CognitionRecord | record_id | UNIQUE | 精确查找 |
| CognitionRecord | character_ref | NOTUNIQUE | 按角色查认知 |
| WorldCognitionTemplate | template_id | UNIQUE | 精确查找 |
| TurnCheckpoint | checkpoint_id | UNIQUE | 精确查找 |
| Monster | monster_id | UNIQUE | 精确查找 |
| Conflict | conflict_id | UNIQUE | 精确查找 |
| Contract | contract_id | UNIQUE | 精确查找 |
| Ship | ship_id | UNIQUE | 精确查找 |
| Fleet | fleet_id | UNIQUE | 精确查找 |
| Item | item_id | UNIQUE | 精确查找 |

---

*设计版本：v2.0 — 跨宇宙 TRPG + 小说生成 | 依赖 ArcadeDB 26.5+*
