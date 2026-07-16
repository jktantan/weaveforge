import requests, json
B="http://192.168.88.10:2480";A=("root","12345678");D="weaverforge"

def cmd(sql):
    r=requests.post(f"{B}/api/v1/command/{D}",auth=A,json={"language":"sql","command":sql})
    return r.status_code<300

# 1. N2 transition event
d1="N2在古月承认其人类身份后,经历了一段内部计算重构期。作为统合意识,她最初将古月的承认视为计算结果输入而非情感连接。前提重新推导:人类未灭绝->战争失去存在意义->被人类承认=可定义自我。经过自我观察和逻辑重组,N2逐步将'被人类承认'从计算结果内化为自我认知的一部分。这不是感动,是统合意识认知框架的重新编译。"
cmd("DELETE FROM Event WHERE event_id='evt-n2-cognitive-restructure'")
cmd("INSERT INTO Event (event_id,display_name,description,date_label,type) VALUES ('evt-n2-cognitive-restructure','N2认知重构期','"+d1+"','11945','campaign')")
print("N2 transition event: OK")

# 2. N2 CognitionRecord
cmd("DELETE FROM CognitionRecord WHERE record_id='cog-n2-transition'")
b1="N2作为统合意识,最初将古月的承认视为计算输入。经过内部共识协议重新评估后,N2逐步将'被人类承认'从理论模型内化为自我定义的一部分。从外部确认到内部重构的迁移过程,非瞬间的情感认同。"
cmd("INSERT INTO CognitionRecord (record_id,character_ref,entity_type,entity_ref,fact_type,source_type,confidence,acquired_session,current_belief) VALUES ('cog-n2-transition','nier-a-n2','self','n2_identity_redefinition','认知重构','internal_recalculation',10,'11945','"+b1+"')")
print("N2 CognitionRecord: OK")

# 3-6: Update backgrounds
bg_n2="机械生命体统合意识N2。在古月承认其人类身份后经历认知重构期:前提重新推导(人类未灭绝->战争失去意义)。从计算结果输入逐步内化为自我定义。不是瞬间情感认同,是统合意识认知框架的重新编译。被承认后N2选择共存而非毁灭。"
cmd("UPDATE Character SET background='"+bg_n2+"' WHERE character_id='nier-a-n2'")
print("N2 background: OK")

bg_a2="YoRHa原型A型(Attack)2号。古月找到她时因她像凯妮而将其当妹妹看待。A2的接受方式是回避型依恋的典型模式:默许古月在身边、不拒绝被叫妹妹、嘴上逞强但行为接受。对A2而言这不是立刻的亲情,而是先通过镜像移情逐步找到自己的位置。"
cmd("UPDATE Character SET background='"+bg_a2+"' WHERE character_id='nier-a-a2'")
print("A2 background: OK")

bg_white="YoRHa基地司令官。知道人类灭绝的真相却必须执行建立在谎言之上的计划。古月的出现炸碎了她的防御框架。White的家人归属不是瞬间建立的--从见面到真正接受经历了较长的调整期。需要将服从对象从虚构的人类会议迁移到真实存在的人类。11945年战后才真正稳固。"
cmd("UPDATE Character SET background='"+bg_white+"' WHERE character_id='nier-a-white'")
print("White background: OK")

bg_twins="机械纪元时代的双子姐妹,继承了replicant时代双子的外貌和部分记忆碎片。古月告诉她们她们没有错,并向White要求删除愧疚程序。古月战后声明不会赦免她们--因为她们没错,不存在赦免问题。愧疚程序删除后经历了一段身份真空期:如果不愧疚,我们是谁?通过古月的持续陪伴度过适应期。"
cmd("UPDATE Character SET background='"+bg_twins+"' WHERE character_id='nier-a-devola'")
cmd("UPDATE Character SET background='"+bg_twins+"' WHERE character_id='nier-a-popola'")
print("Twins backgrounds: OK")

# Verify
r=requests.post(f"{B}/api/v1/command/{D}",auth=A,json={"language":"sql","command":"SELECT count(*) AS c FROM Event WHERE event_id='evt-n2-cognitive-restructure'"})
print(f"N2 event verified: {r.json()['result'][0]['c']}")
r=requests.post(f"{B}/api/v1/command/{D}",auth=A,json={"language":"sql","command":"SELECT count(*) AS c FROM CognitionRecord WHERE record_id='cog-n2-transition'"})
print(f"N2 cognition verified: {r.json()['result'][0]['c']}")
print("DONE")
