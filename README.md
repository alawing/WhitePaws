Only for chinese tbc classic version

1. Help with cat dps skill macro
Can make macro let it auto detect either spell attack skill or shift form, or using mana pot
conditions:energy, mana, next tick time, been rooted, or strong control like stun or fear.

2. Help with bear form
Can make macro let bear use pots and protect shifting to human. (gcd or strong control like stun, fear)
Can make macro let bear auto shift if not enough rage.

3. Auto equip speed up trinket when flying, equip back when not flying

4. Tells if been control

5. Light bar to show next energy and mana tick

只能用于中文燃烧的远征怀旧客户端
1.猫输出宏
帮助写出输出宏，自动决定打出技能还是变身，还是吃蓝
考虑的状态有：能量，法力，下一跳回能时间，是不是被定身，是不是被晕恐惧之类硬控

2.熊用的宏
帮助写出不变人的吃药宏（预防公共cd或者晕恐惧之类硬控）
帮助写出宏让熊在不够能量时重新变身

3.飞行时自动装飞行饰品,不飞时装回

4.被控时会提示

5.法力条和能量条提示下一跳时间

先把目录文件放到Interface/WhitePaws里，插件选择上WhitePaws,就可以用说明.txt里面的宏了

猫输出宏需要提前准备好一个 能量转化器，黑色骨灰或者小宠物，把/施放 能量转化器 换成自己的道具

--09172021 1.4	飞行时自动装上飞行护符，不飞时自动换回去，白爪生日快乐！

--09142021 1.3
--加入被控喊话，分类被控，一键宏现在可以自动解定身和变形了，
--熊在被除了硬控之外可以正确吃药了(被晕吃药不变人,冰环能吃药)

--09122021 1.2
--优化很多手感，加入buff和被控的event

--09092021 1.12
--把latency加入到powerspark

--09082021 1.11
--修复小bug

--09072021 1.1
--加入latency判断，提前变身进施法队列，根据延迟预支能量
--优化决策 1.5秒变身能提早下一个技能原则
--嵌入PowerSpark nextTick

-- 收集到的控制类型
-- STUN_MECHANIC 昏迷
-- STUN 沉睡 放逐 瘫痪 被闷棍 恐惧 魅惑
-- ROOT 被定身
-- POSSESS 魅惑
-- FEAR_MECHANIC 恐惧
-- CONFUSE 变形 迷惑
-- SCHOOL_INTERRUPT 打断
-- SILENCE 变形 沉默
-- DISARM 缴械
-- FEAR 惊骇
