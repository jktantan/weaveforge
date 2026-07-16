#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Seed worlds and characters into ArcadeDB."""
import requests, json

BASE = "http://192.168.88.10:2480"
AUTH = ("root", "12345678")
DB = "weaverforge"

def cmd(sql):
    r = requests.post(f"{BASE}/api/v1/command/{DB}", auth=AUTH,
        json={"language": "sql", "command": sql}, timeout=15)
    return r.status_code < 300, r.json() if r.status_code < 300 else r.text[:200]

def insert_world(wid, name, typ, anchor, desc, aliases, dims):
    sql = f"INSERT INTO World (world_id, display_name, type, timeline_anchor, description, aliases, supported_dimensions) VALUES ('{wid}', '{name}', '{typ}', '{anchor}', '{desc}', {json.dumps(aliases)}, {json.dumps(dims)})"
    return cmd(sql)

def insert_character(cid, name, origin, species, gender, birth, height, hair, features, attire, nationality, social, occ, world, tags, langs, personality, motivation, secret, voice, constraints, background, age=39):
    sql = f"""INSERT INTO Character (character_id, display_name, character_origin, is_party_member, species, gender, birth_date, chronological_age, apparent_age, height, hair_color, distinguishing_features, appearance_summary, typical_attire, nationality, social_class, occupation, origin_world, tags, languages_spoken, personality_tags, core_motivation, secret, voice, speech_constraints, background) VALUES ('{cid}', '{name}', '{origin}', true, '{species}', '{gender}', '{birth}', {age}, {age}, '{height}', '{hair}', {json.dumps(features)}, '{name}{height}体形发福', '{attire}', '{nationality}', '{social}', '{occ}', '{world}', {json.dumps(tags)}, {json.dumps(langs)}, {json.dumps(personality)}, '{motivation}', '{secret}', '{voice}', {json.dumps(constraints)}, '{background}')"""
    return cmd(sql)

# === Worlds ===
ok, _ = insert_world("earth-modern", "现代地球", "original", "2026-06-15=UC-8534",
    "21世纪初的现实地球。主角古月的原生世界。", ["地球","Earth"], ["adventure"])
print(f"World earth-modern: {'OK' if ok else 'FAIL'}")

ok, _ = insert_world("nier", "尼尔世界", "fanon", "11999-02-19=UC+0",
    "NieR Replicant ver.1.22474487139(2021版)+NieR:Automata。", ["尼尔","Nier世界"], ["adventure"])
print(f"World nier: {'OK' if ok else 'FAIL'}")

# === Character: 古月 ===
ok, _ = insert_character("guyue", "古月", "original", "人类", "男", "1986-08-01",
    "160cm", "黑发",
    ["体型发福"],
    "淡蓝色T恤，七分工装裤，运动鞋",
    "中国", "中产", "软件工程师", "earth-modern",
    ["软件工程师","海外硕士","宅男"],
    ["中文","英文","俄语"],
    ["外人面前话少","熟人话多易乱说话","胆小怕事","预判无果则退缩","帮人先评估能力","双标内群体偏好","善良底色","隐藏的残忍"],
    "渴望家庭温暖，弥补原生家庭缺失",
    "内心深处有不为人知的残忍面，与平时怂包形象反差极大",
    "普通男声，中文带南方口音",
    ["仅对自己人话多","对陌生人寡言","紧张时可能语无伦次"],
    "1986年8月1日出生于中国南方某城市。海外本硕。软件工程师。与原生家庭关系极差但渴望家人。2026-06-15上班途中被未知原因抛入尼尔世界。"
)
print(f"Character guyue: {'OK' if ok else 'FAIL'}")

# === Locations ===
cmd(f"INSERT INTO Location (location_id, display_name, location_type, description) VALUES ('guyue-home', '古月家', '住宅', '三房两厅，自购')")
cmd(f"INSERT INTO Location (location_id, display_name, location_type, description) VALUES ('guyue-office', '古月公司', '工作场所', '软件公司')")

# === LoreDocument (optional) ===
from pathlib import Path
lore_path = Path(__file__).parent.parent / "seed" / "earth-modern" / "lore.md"
if lore_path.exists():
    content = lore_path.read_text(encoding="utf-8")
    cmd(f"INSERT INTO LoreDocument (world_id, content) VALUES ('earth-modern', '{content.replace(chr(39),chr(39)+chr(39))}')")

print("\nDone. Use SELECT FROM World / Character / Location to verify.")
