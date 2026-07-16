# Apply 8 fixes to raven-yacht.md
with open("seed/infinite-vessel/lore/raven-yacht.md", "r", encoding="utf-8") as f:
    c = f.read()

# 1. Engine room section after engine table
er = '\n### 引擎舱\n\n引擎舱位于舰体后段，占据约全长1/4的空间。小型数学率跃迁引擎和常规幽能推进引擎并排安装在独立减震框架上。\n\n当前状态：两种引擎均可正常运行。'
c = c.replace("**当前最快的航速**", er + "\n\n**当前最快的航速**")

# 2. Power core before 大气飞行
pc = '\n### 能源核心\n\n渡鸦号的独立幽能核心位于舰体中段下方——与无限号同技术的微型虚空能->幽能转换器。全盛期可支持主炮持续开火和隐身全功率。当前输出有限——优先引擎和隐身，主炮充能排最后。'
c = c.replace("## 大气层飞行", pc + "\n\n## 大气层飞行")

# 3. Sensors section before 隐身
c += "SENSORS_PLACEHOLDER"
old_sensors = "## 隐身系统"
sn = '\n## 传感器系统\n\n渡鸦号搭载微型扫描阵列——与无限号同技术但低一级。用于打击前目标锁定和跃迁后态势确认。\n\n| 系统 | 说明 | 当前 |\n|:----:|:----:|:--:|\n| 主传感器 | 舰首集成式——目标锁定+导航 | 在线 |\n| 被动监控 | 全向低能耗——接收不发射 | 在线 |\n| 战术扫描 | 开火前激活——高能耗短时高精度 | 可用 |\n\n> 渡鸦号不依赖自身传感器作战——战术模式是无限号指哪打哪。'
c = c.replace("## 隐身系统", sn + "\n\n## 隐身系统")
c = c.replace("SENSORS_PLACEHOLDER", "")

# 4. Shields before 武装
sd = '\n## 防御系统\n\n渡鸦号的防御逻辑是不被发现比被发现了再扛更有用。\n\n| 系统 | 说明 | 状态 |\n|:----:|:----:|:--:|\n| 幽能护盾 | 与无限号同技术但小一级——扛数轮驱逐舰炮击 | 在线 |\n| 力场包裹 | 抵消空气阻力和热效应 | 在线 |\n| 装甲 | 复合合金板——扛破片和轻武器。战列舰主炮命中即致命 | 够用 |\n\n> 极光：别被打中。它不扛揍，它揍人。'
c = c.replace("## 武装", sd + "\n\n## 武装")

# 5. Fix 120 people living
c = c.replace("| **原设计最大乘员** | ~**120人**（含舰桥、武器、工程、陆战分遣队） |", "| **原设计最大乘员** | ~**120人**（含舰桥、武器、工程、陆战分遣队——密集铺位+轮换制，非每人单间） |")

# 6. Cargo section before 居住舱
cg = '\n### 货舱\n\n原设计用于携带陆战装备和小型补给。当前存放急需物资和高价值设备——约200m3，空置约七成。'
c = c.replace("### 居住舱", cg + "\n\n### 居住舱")

# 7. Hull armor in 外观 section
ha = '\n\n装甲：复合幽能合金板，与无限号同材料但厚度不足其千分之一。扛小口径炮击和破片有余——战列舰级主炮命中即致命。'
c = c.replace("**日常涂装**：深灰色低可探测涂层，无标识——渡鸦号从不暴露身份。", "**日常涂装**：深灰色低可探测涂层，无标识——渡鸦号从不暴露身份。" + ha)

with open("seed/infinite-vessel/lore/raven-yacht.md", "w", encoding="utf-8") as f:
    f.write(c)

print("All 8 fixes applied")
