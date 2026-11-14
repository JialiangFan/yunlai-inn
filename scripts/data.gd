extends RefCounted
## 游戏数据表：菜系、伙计、道具、访客事件、比赛。想调数值就改这里。

const WEEKDAYS := ["周一", "周二", "周三", "周四", "周五", "周六", "休假日"]

# ---------------- 伙计 ----------------
const ROLES := ["掌柜", "厨师", "跑堂", "杂役"]
const ROLE_STAT := {"掌柜": "计算", "厨师": "厨艺", "跑堂": "技巧", "杂役": "反应"}
const ROLE_LIMIT := {"掌柜": 1, "厨师": 3, "跑堂": 4, "杂役": 2}
const ROLE_COLOR := {"掌柜": "5b3a6e", "厨师": "b0452c", "跑堂": "4f6d8f", "杂役": "7a5a36"}
const ROLE_HINT := {
	"掌柜": "在柜台收钱。计算越高结账越快；魅力能招揽客人。没有掌柜，客人只能在桌边慢慢自己算账。",
	"厨师": "守一口灶做菜，也负责研发新菜。厨艺越高做得越快；魅力能招揽客人。",
	"跑堂": "点菜、传菜（没有杂役时也收拾桌子）。技巧越高手脚越快；魅力让客人更满意。",
	"杂役": "收拾桌子、照应客人。反应越高，客人越沉得住气。",
}
const STATS := ["厨艺", "计算", "技巧", "反应", "魅力", "毅力", "向心力"]
const SKILL_STATS := ["厨艺", "计算", "技巧", "反应"]
const SURNAMES := ["王", "李", "张", "刘", "陈", "杨", "赵", "黄", "周", "吴", "徐", "孙", "马", "朱", "胡", "郭", "何", "林", "罗", "高", "梁", "宋", "唐", "许", "韩"]
const GIVEN := ["大有", "小六", "阿福", "二牛", "春桃", "秋菊", "石头", "铁柱", "来顺", "满仓", "喜儿", "招财", "金宝", "长生", "翠花", "宝山", "顺子", "阿青", "云生", "小乙", "三娘", "四喜", "冬生", "玉兰"]

# 杂货铺的道具：买给某个伙计，提升一项能力，顺带提升向心力
const ITEMS := [
	{"name": "铜算盘", "stat": "计算", "amount": 15, "loyal": 5, "price": 600},
	{"name": "精钢菜刀", "stat": "厨艺", "amount": 12, "loyal": 5, "price": 800},
	{"name": "千层布鞋", "stat": "技巧", "amount": 15, "loyal": 5, "price": 500},
	{"name": "鸡毛掸子", "stat": "反应", "amount": 15, "loyal": 5, "price": 400},
	{"name": "绸缎新衣", "stat": "魅力", "amount": 12, "loyal": 8, "price": 700},
	{"name": "玉扳指", "stat": "毅力", "amount": 15, "loyal": 8, "price": 650},
	{"name": "银手镯", "stat": "向心力", "amount": 20, "loyal": 0, "price": 500},
]

# ---------------- 店面装修 ----------------
# 桌椅档次：满意度加成
const TABLE_GRADES := [
	{"name": "松木桌", "cost": 0, "sat": 0.0},
	{"name": "红木桌", "cost": 1200, "sat": 0.03},
	{"name": "雕花红木桌", "cost": 3000, "sat": 0.06},
]
# 灶台档次：做菜速度倍率
const STOVE_GRADES := [
	{"name": "铁锅灶", "cost": 0, "speed": 1.0},
	{"name": "青砖大灶", "cost": 1000, "speed": 1.15},
	{"name": "黄铜御灶", "cost": 2800, "speed": 1.3},
]
# 摆件：每样买一次，摆在大堂的摆件位上，可以换位置
# 加成：sat 满意度、patience 客人耐心、arrival 来客、rep 声望增长、tip 赏钱、rich 有钱客人
const DECOR_ITEMS := [
	{"id": "screen", "name": "山水屏风", "cost": 800, "bonus": "sat", "value": 0.03, "desc": "满意度 +3%"},
	{"id": "scroll", "name": "名家字画", "cost": 1200, "bonus": "rep", "value": 0.1, "desc": "声望增长 +10%"},
	{"id": "fish", "name": "金鱼缸", "cost": 600, "bonus": "patience", "value": 0.08, "desc": "客人耐心 +8%"},
	{"id": "flower", "name": "牡丹花架", "cost": 500, "bonus": "arrival", "value": 0.08, "desc": "来客 +8%"},
	{"id": "curio", "name": "博古架", "cost": 1500, "bonus": "rich", "value": 1.0, "desc": "有钱的商贾更爱来"},
	{"id": "censer", "name": "铜鼎香炉", "cost": 900, "bonus": "tip", "value": 0.3, "desc": "赏钱 +30%"},
]

# ---------------- 菜系 ----------------
# 每个菜系三道菜，由浅到深依次研发。成本、标准售价、做菜秒数、美味(1~5)
const CATEGORIES := [
	{"name": "面食", "dishes": [
		{"name": "阳春面", "cost": 6, "price": 20, "cook": 3.0, "taste": 1, "color": "eadcae"},
		{"name": "炸酱面", "cost": 12, "price": 36, "cook": 4.0, "taste": 2, "color": "8a5a2b"},
		{"name": "牛肉拉面", "cost": 22, "price": 62, "cook": 5.0, "taste": 3, "color": "c26a3a"}]},
	{"name": "点心", "dishes": [
		{"name": "小笼包", "cost": 10, "price": 30, "cook": 4.0, "taste": 2, "color": "f4ead6"},
		{"name": "虾饺", "cost": 20, "price": 56, "cook": 5.0, "taste": 3, "color": "f2d7c4"},
		{"name": "蟹黄汤包", "cost": 40, "price": 110, "cook": 7.0, "taste": 4, "color": "e8b04a"}]},
	{"name": "家常", "dishes": [
		{"name": "麻婆豆腐", "cost": 14, "price": 42, "cook": 5.0, "taste": 2, "color": "c8442f"},
		{"name": "宫保鸡丁", "cost": 22, "price": 60, "cook": 6.0, "taste": 3, "color": "d9731f"},
		{"name": "鱼香肉丝", "cost": 28, "price": 74, "cook": 6.0, "taste": 3, "color": "b8492a"}]},
	{"name": "烧肉", "dishes": [
		{"name": "回锅肉", "cost": 24, "price": 66, "cook": 6.0, "taste": 3, "color": "b5562e"},
		{"name": "东坡肉", "cost": 35, "price": 92, "cook": 8.0, "taste": 4, "color": "8e3b1f"},
		{"name": "北京烤鸭", "cost": 80, "price": 188, "cook": 12.0, "taste": 5, "color": "b5571d"}]},
	{"name": "河鲜", "dishes": [
		{"name": "清蒸鲈鱼", "cost": 30, "price": 82, "cook": 7.0, "taste": 3, "color": "d8d0b0"},
		{"name": "西湖醋鱼", "cost": 45, "price": 112, "cook": 9.0, "taste": 4, "color": "a8682e"},
		{"name": "松鼠鳜鱼", "cost": 70, "price": 170, "cook": 11.0, "taste": 5, "color": "e07b2a"}]},
	{"name": "汤品", "dishes": [
		{"name": "酸辣汤", "cost": 8, "price": 26, "cook": 3.0, "taste": 1, "color": "c9873a"},
		{"name": "老鸭汤", "cost": 30, "price": 86, "cook": 8.0, "taste": 4, "color": "d9c08a"},
		{"name": "佛跳墙", "cost": 110, "price": 268, "cook": 14.0, "taste": 5, "color": "c9a227"}]},
]
const START_UNLOCKED := {"面食": 1, "点心": 1}

# ---------------- 访客事件 ----------------
# 营业时偶尔有人上门，掌柜决定接不接。%d 处填 cost。
const EVENTS := [
	{"id": "storyteller", "title": "说书先生来访", "cost": 200, "yes": "请他开讲", "no": "婉拒",
		"text": "一位说书先生想在大堂里说一段《三侠五义》，酬金 %d 文。\n今天客人听得入迷，会格外沉得住气。"},
	{"id": "acrobat", "title": "杂耍班子", "cost": 150, "yes": "请他们表演", "no": "婉拒",
		"text": "一队杂耍艺人想在门口热闹一番，赏钱 %d 文。\n今天上门的客人会多不少。"},
	{"id": "scholar", "title": "赶考书生借盘缠", "cost": 300, "yes": "借给他", "no": "婉拒",
		"text": "一位赶考书生盘缠用尽，想借 %d 文，说高中之后必定加倍奉还。\n（他会不会还，就看运气了。）"},
	{"id": "bully", "title": "地痞上门", "cost": 250, "yes": "给钱了事", "no": "不给",
		"text": "几个地痞来收“平安钱” %d 文。\n不给的话，他们怕是要在店里闹事、吓跑客人。"},
	{"id": "critic", "title": "美食家光临", "cost": 0, "yes": "热情招待", "no": "照常营业",
		"text": "城里有名的美食家今天要来吃饭。\n若热情招待，今天客人满意时声望涨得多，不满意时也跌得多。"},
	{"id": "doctor", "title": "游方郎中", "cost": 400, "yes": "买一壶", "no": "婉拒",
		"text": "游方郎中兜售强身药茶，%d 文给全店伙计喝一壶。\n大家都会更卖力（向心力、毅力提升）。"},
	{"id": "master_chef", "title": "落难名厨", "cost": 1200, "yes": "请他留下", "no": "婉拒",
		"text": "一位流落此地的名厨愿意来店里掌勺，安家费 %d 文。\n他的厨艺远胜寻常厨子。"},
]

# ---------------- 比赛 ----------------
# 依次参加。休假日报名，下一周六个营业日比成绩，达到目标即获胜。
const CONTESTS := [
	{"name": "城南小吃评比", "fee": 300, "rep": 0, "tables": 3, "type": "served", "target": 100, "prize": 1500},
	{"name": "县城厨艺会", "fee": 800, "rep": 30, "tables": 5, "type": "income", "target": 7000, "prize": 4000},
	{"name": "府城名店赛", "fee": 2000, "rep": 55, "tables": 6, "type": "satisfaction", "target": 72, "prize": 8000},
	{"name": "省城食府大会", "fee": 4000, "rep": 75, "tables": 7, "type": "income", "target": 22000, "prize": 15000},
	{"name": "天下名厨大会", "fee": 8000, "rep": 95, "tables": 8, "type": "fine", "target": 60, "prize": 30000},
]
const CONTEST_TYPES := {
	"served": "一周招待的客人数",
	"income": "一周的营业收入（文）",
	"satisfaction": "一周客人的平均满意度",
	"fine": "一周卖出的招牌菜份数（各菜系第三道）",
}
