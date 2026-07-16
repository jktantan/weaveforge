-- WeaveForge DDL - Auto-generated from arcadedb-schema.md
-- Target: ArcadeDB 26.5+

CREATE INDEX ON [type] (embedding) LSM_VECTOR
  METADATA {
    "dimensions": 1024,
    "similarity": "COSINE",
    "quantization": "INT8",
    "maxConnections": 16,
    "beamWidth": 100
  };

CREATE VERTEX TYPE World IF NOT EXISTS;
CREATE PROPERTY World.world_id STRING;
CREATE PROPERTY World.display_name STRING;
CREATE PROPERTY World.type STRING;       -- canon / fanon / original
CREATE PROPERTY World.timeline_anchor STRING;
CREATE PROPERTY World.description STRING;
CREATE PROPERTY World.aliases LIST;
CREATE PROPERTY World.supported_dimensions LIST;  -- 玩法维度：adventure/naval_combat/mass_warfare/politics/nation_building/economy
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
CREATE PROPERTY Character.tags LIST;                  -- 纯标签系统（向后兼容）
CREATE PROPERTY Character.abilities LIST;              -- 🆕 结构化能力列表 LIST<JSON>
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
CREATE PROPERTY Character.unfamiliar_concepts LIST;     -- 无法理解的跨世界概念
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
CREATE INDEX ON CharacterSnapshot (character_ref, chapter_ref) NOTUNIQUE;

CREATE VERTEX TYPE Faction IF NOT EXISTS;
CREATE PROPERTY Faction.faction_id STRING;
CREATE PROPERTY Faction.display_name STRING;
CREATE PROPERTY Faction.aliases LIST;
CREATE PROPERTY Faction.type STRING;
CREATE PROPERTY Faction.resources JSON;
CREATE PROPERTY Faction.hierarchy_parent STRING;
CREATE PROPERTY Faction.influence_score INTEGER;  -- 影响力 0-100
CREATE PROPERTY Faction.troop_strength STRING;    -- 兵力描述
CREATE PROPERTY Faction.government_type STRING;   -- 政体：monarchy/military_junta/council/tribe
CREATE PROPERTY Faction.sovereignty STRING;       -- 主权：sovereign/vassal/occupied/exiled
CREATE INDEX ON Faction (faction_id) UNIQUE;

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
CREATE INDEX ON CanonEventStatus (canon_event_ref, status) NOTUNIQUE;

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

CREATE VERTEX TYPE BridgeEntry IF NOT EXISTS;
CREATE PROPERTY BridgeEntry.entry_id STRING;
CREATE PROPERTY BridgeEntry.item_name STRING;
CREATE PROPERTY BridgeEntry.item_category STRING;     -- magical_weapon/mundane/technology/character_ability/power_adapter
CREATE PROPERTY BridgeEntry.source_world STRING;
CREATE PROPERTY BridgeEntry.target_world STRING;
CREATE PROPERTY BridgeEntry.compatibility STRING;     -- full/degraded/reinterpreted/disabled
CREATE PROPERTY BridgeEntry.effect_description STRING;
CREATE PROPERTY BridgeEntry.stat_modifiers JSON;
-- 🆕 能力相关
CREATE PROPERTY BridgeEntry.ability_name STRING;      -- 用于 character_ability
-- 🆕 适配器相关
CREATE PROPERTY BridgeEntry.adapter_type STRING;      -- item/character_ability/bloodline
CREATE PROPERTY BridgeEntry.source_power STRING;      -- 适配器产生能源
CREATE PROPERTY BridgeEntry.compatible_targets LIST;   -- 可驱动哪些 power_source
CREATE PROPERTY BridgeEntry.conversion_efficiency FLOAT; -- 0.0-1.0
CREATE PROPERTY BridgeEntry.usage_limit STRING;
CREATE PROPERTY BridgeEntry.local_name STRING;
CREATE PROPERTY BridgeEntry.local_understanding STRING;
CREATE PROPERTY BridgeEntry.misconceptions LIST;
CREATE PROPERTY BridgeEntry.reveal_triggers LIST;
CREATE PROPERTY BridgeEntry.perception_difficulty STRING;
CREATE INDEX ON BridgeEntry (entry_id) UNIQUE;
CREATE INDEX ON BridgeEntry (source_world, target_world) NOTUNIQUE;

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

-- 关系变化事件
CREATE VERTEX TYPE RelationshipEvent IF NOT EXISTS;
CREATE PROPERTY RelationshipEvent.event_id STRING;
CREATE PROPERTY RelationshipEvent.from_char STRING;
CREATE PROPERTY RelationshipEvent.to_char STRING;
CREATE PROPERTY RelationshipEvent.unified_time STRING;
CREATE PROPERTY RelationshipEvent.local_time STRING;
CREATE PROPERTY RelationshipEvent.session_id STRING;
CREATE PROPERTY RelationshipEvent.trigger_desc STRING;
CREATE PROPERTY RelationshipEvent.changes JSON;
CREATE PROPERTY RelationshipEvent.perception STRING;
CREATE INDEX ON RelationshipEvent (event_id) UNIQUE;
CREATE INDEX ON RelationshipEvent (session_id) NOTUNIQUE;
CREATE INDEX ON RelationshipEvent (from_char) NOTUNIQUE;

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

-- 宇宙域
CREATE EDGE TYPE CONNECTS_TO IF NOT EXISTS;
CREATE EDGE TYPE COMPATIBILITY_RULE IF NOT EXISTS;
CREATE EDGE TYPE COGNITIVE_MAP IF NOT EXISTS;

-- 角色域
CREATE EDGE TYPE KNOWS IF NOT EXISTS;
CREATE PROPERTY KNOWS.trust INTEGER;
CREATE PROPERTY KNOWS.attraction INTEGER;
CREATE PROPERTY KNOWS.respect INTEGER;
CREATE PROPERTY KNOWS.history STRING;
CREATE PROPERTY KNOWS.relationship_phase STRING;
CREATE PROPERTY KNOWS.unified_since STRING;
CREATE PROPERTY KNOWS.unified_until STRING;
CREATE PROPERTY KNOWS.created_by_session STRING;
CREATE PROPERTY KNOWS.closed_by_session STRING;

CREATE EDGE TYPE HAS_SNAPSHOT IF NOT EXISTS;

-- 派系域
CREATE EDGE TYPE BELONGS_TO IF NOT EXISTS;
CREATE PROPERTY BELONGS_TO.role STRING;
CREATE PROPERTY BELONGS_TO.loyalty INTEGER;
CREATE PROPERTY BELONGS_TO.authority STRING;
CREATE PROPERTY BELONGS_TO.unified_since STRING;
CREATE PROPERTY BELONGS_TO.unified_until STRING;
CREATE PROPERTY BELONGS_TO.created_by_session STRING;
CREATE PROPERTY BELONGS_TO.closed_by_session STRING;

CREATE EDGE TYPE ALLIED_WITH IF NOT EXISTS;
CREATE PROPERTY ALLIED_WITH.treaty_type STRING;
CREATE PROPERTY ALLIED_WITH.status STRING;
CREATE PROPERTY ALLIED_WITH.unified_since STRING;
CREATE PROPERTY ALLIED_WITH.unified_until STRING;
CREATE PROPERTY ALLIED_WITH.created_by_session STRING;
CREATE PROPERTY ALLIED_WITH.closed_by_session STRING;

CREATE EDGE TYPE HOSTILE_WITH IF NOT EXISTS;
CREATE PROPERTY HOSTILE_WITH.conflict_level STRING;
CREATE PROPERTY HOSTILE_WITH.unified_since STRING;
CREATE PROPERTY HOSTILE_WITH.unified_until STRING;
CREATE PROPERTY HOSTILE_WITH.created_by_session STRING;
CREATE PROPERTY HOSTILE_WITH.closed_by_session STRING;

CREATE EDGE TYPE CONTROLS IF NOT EXISTS;
CREATE PROPERTY CONTROLS.influence_level STRING;
CREATE PROPERTY CONTROLS.unified_since STRING;
CREATE PROPERTY CONTROLS.unified_until STRING;
CREATE PROPERTY CONTROLS.created_by_session STRING;
CREATE PROPERTY CONTROLS.closed_by_session STRING;

CREATE EDGE TYPE NEGOTIATES_WITH IF NOT EXISTS;
CREATE PROPERTY NEGOTIATES_WITH.diplomatic_status STRING;
CREATE PROPERTY NEGOTIATES_WITH.status_since STRING;
CREATE PROPERTY NEGOTIATES_WITH.mutual_threat STRING;
CREATE PROPERTY NEGOTIATES_WITH.ideological_alignment INTEGER;
CREATE PROPERTY NEGOTIATES_WITH.unified_since STRING;
CREATE PROPERTY NEGOTIATES_WITH.unified_until STRING;
CREATE PROPERTY NEGOTIATES_WITH.created_by_session STRING;
CREATE PROPERTY NEGOTIATES_WITH.closed_by_session STRING;

CREATE EDGE TYPE FACTION_RELATION_EVENT IF NOT EXISTS;
CREATE PROPERTY FACTION_RELATION_EVENT.from_faction STRING;
CREATE PROPERTY FACTION_RELATION_EVENT.to_faction STRING;
CREATE PROPERTY FACTION_RELATION_EVENT.trigger_desc STRING;
CREATE PROPERTY FACTION_RELATION_EVENT.changes JSON;
CREATE PROPERTY FACTION_RELATION_EVENT.session_id STRING;
CREATE PROPERTY FACTION_RELATION_EVENT.remark STRING;

CREATE EDGE TYPE CONTENDED_BY IF NOT EXISTS;
CREATE EDGE TYPE BATTLEFIELD IF NOT EXISTS;

-- 地点域
CREATE EDGE TYPE CONTAINS IF NOT EXISTS;
CREATE EDGE TYPE ROUTE IF NOT EXISTS;
CREATE PROPERTY ROUTE.travel_method STRING;
CREATE PROPERTY ROUTE.time_cost STRING;
CREATE PROPERTY ROUTE.distance_km FLOAT;
CREATE PROPERTY ROUTE.danger_level INTEGER;
CREATE PROPERTY ROUTE.vehicle_ref STRING;
CREATE PROPERTY ROUTE.conditions LIST;
CREATE PROPERTY ROUTE.travel_type STRING;
CREATE PROPERTY ROUTE.warp_time_variance STRING;
CREATE PROPERTY ROUTE.warp_encounter_risk INTEGER;
CREATE PROPERTY ROUTE.navigator_required BOOLEAN;

-- 事件域
CREATE EDGE TYPE CAUSES IF NOT EXISTS;
CREATE PROPERTY CAUSES.causality_type STRING;

CREATE EDGE TYPE PARTICIPATED_IN IF NOT EXISTS;
CREATE PROPERTY PARTICIPATED_IN.role STRING;
CREATE PROPERTY PARTICIPATED_IN.impact STRING;

CREATE EDGE TYPE HAPPENED_AT IF NOT EXISTS;

-- 偏离追踪域
CREATE EDGE TYPE IMPACTS IF NOT EXISTS;
CREATE EDGE TYPE AFFECTED_BY IF NOT EXISTS;

-- 剧情线域
CREATE EDGE TYPE ADVANCED_BY IF NOT EXISTS;
CREATE PROPERTY ADVANCED_BY.narrative_weight INTEGER;
CREATE EDGE TYPE RELATED_TO IF NOT EXISTS;
CREATE EDGE TYPE FORETOLD_BY IF NOT EXISTS;

-- 桥接域
CREATE EDGE TYPE CROSSED_THROUGH IF NOT EXISTS;
CREATE EDGE TYPE CARRIED_ACROSS IF NOT EXISTS;

-- 物品域
CREATE EDGE TYPE EQUIPPED_BY IF NOT EXISTS;
CREATE EDGE TYPE CREATED_AT IF NOT EXISTS;
CREATE EDGE TYPE TRANSFERRED_TO IF NOT EXISTS;
CREATE PROPERTY TRANSFERRED_TO.item_ref STRING;
CREATE PROPERTY TRANSFERRED_TO.unified_time STRING;
CREATE PROPERTY TRANSFERRED_TO.trigger_event STRING;
CREATE PROPERTY TRANSFERRED_TO.remark STRING;

CREATE EDGE TYPE BELONGS_TO_ON_ITEM IF NOT EXISTS;

-- 怪物域
CREATE EDGE TYPE HABITAT_IN IF NOT EXISTS;
CREATE EDGE TYPE HUNTED_BY IF NOT EXISTS;
CREATE EDGE TYPE DROPS IF NOT EXISTS;

-- 契约域
CREATE EDGE TYPE ASSIGNED_BY IF NOT EXISTS;
CREATE EDGE TYPE TARGETS_MONSTER IF NOT EXISTS;
CREATE EDGE TYPE COMPLETED_BY IF NOT EXISTS;

-- 规则域
CREATE EDGE TYPE APPLIES_TO IF NOT EXISTS;
CREATE EDGE TYPE ACTIVE_IN IF NOT EXISTS;

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
CREATE PROPERTY SessionLog.session_id STRING;
CREATE PROPERTY SessionLog.session_number INTEGER;
CREATE PROPERTY SessionLog.title STRING;
CREATE PROPERTY SessionLog.summary STRING;
CREATE PROPERTY SessionLog.world STRING;
CREATE PROPERTY SessionLog.start_time TIMESTAMP;
CREATE PROPERTY SessionLog.end_time TIMESTAMP;
CREATE PROPERTY SessionLog.game_time_start STRING;
CREATE PROPERTY SessionLog.game_time_end STRING;
CREATE PROPERTY SessionLog.participants LIST;
CREATE PROPERTY SessionLog.oracle_model STRING;          -- AI模型标识（solo模式）或真人GM名
CREATE PROPERTY SessionLog.status STRING;        -- ongoing / completed / abandoned
CREATE PROPERTY SessionLog.content STRING;
CREATE PROPERTY SessionLog.transcript STRING;
CREATE PROPERTY SessionLog.embedding ARRAY_OF_FLOATS (EXTERNAL true);
CREATE INDEX ON SessionLog (session_id) UNIQUE;
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

-- 消息流
CREATE VERTEX TYPE Message IF NOT EXISTS;
CREATE PROPERTY Message.message_id STRING;
CREATE PROPERTY Message.session_id STRING;
CREATE PROPERTY Message.scene_id STRING;
CREATE PROPERTY Message.turn_number INTEGER;
CREATE PROPERTY Message.message_type STRING;  -- gm_narration/gm_response/player_action/player_dialogue/system_roll/oracle_result
CREATE PROPERTY Message.speaker STRING;
CREATE PROPERTY Message.content STRING;
CREATE PROPERTY Message.game_time STRING;
CREATE PROPERTY Message.real_time TIMESTAMP;
CREATE INDEX ON Message (message_id) UNIQUE;
CREATE INDEX ON Message (session_id) NOTUNIQUE;

-- 场景
CREATE VERTEX TYPE Scene IF NOT EXISTS;
CREATE PROPERTY Scene.scene_id STRING;
CREATE PROPERTY Scene.session_id STRING;
CREATE PROPERTY Scene.scene_number INTEGER;
CREATE PROPERTY Scene.location STRING;
CREATE PROPERTY Scene.characters_present LIST;
CREATE PROPERTY Scene.summary STRING;
CREATE INDEX ON Scene (scene_id) UNIQUE;

-- 物品使用日志
CREATE VERTEX TYPE ItemUsageLog IF NOT EXISTS;
CREATE PROPERTY ItemUsageLog.log_id STRING;
CREATE PROPERTY ItemUsageLog.item_id STRING;
CREATE PROPERTY ItemUsageLog.used_by STRING;
CREATE PROPERTY ItemUsageLog.used_in_session STRING;
CREATE PROPERTY ItemUsageLog.used_in_scene STRING;
CREATE PROPERTY ItemUsageLog.effect_description STRING;
CREATE PROPERTY ItemUsageLog.consumed BOOLEAN;
CREATE INDEX ON ItemUsageLog (log_id) UNIQUE;

-- 变更摘要 Document
CREATE DOCUMENT TYPE SessionDelta IF NOT EXISTS;
CREATE PROPERTY SessionDelta.delta_id STRING;
CREATE PROPERTY SessionDelta.session_id STRING;
CREATE PROPERTY SessionDelta.item_changes JSON;
CREATE PROPERTY SessionDelta.relationship_changes JSON;
CREATE PROPERTY SessionDelta.cognition_changes JSON;
CREATE PROPERTY SessionDelta.faction_changes JSON;
CREATE PROPERTY SessionDelta.plot_progress JSON;
CREATE INDEX ON SessionDelta (delta_id) UNIQUE;

