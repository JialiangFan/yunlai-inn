extends RefCounted
## 图片素材加载器：art 文件夹里有对应的图片就用图片，没有就返回 null，由代码画的版本顶上。
## 文件名对照见 art/素材说明.txt。

const ROOT := "res://art/"

const GUEST_FILES := {"农夫": "guests/farmer", "书生": "guests/scholar", "侠客": "guests/swordsman", "商贾": "guests/merchant",
	"镖师": "guests/escort", "道士": "guests/taoist", "和尚": "guests/monk", "官差": "guests/constable",
	"千金小姐": "guests/lady", "乞丐": "guests/beggar", "胡商": "guests/hu_merchant",
	"王员外": "guests/wang", "柳三娘": "guests/liu", "周夫子": "guests/zhou", "赵捕头": "guests/zhao"}
const ROLE_FILES := {"掌柜": "staff/manager", "厨师": "staff/chef", "跑堂": "staff/waiter", "杂役": "staff/helper"}
const EXTS := [".png", ".webp", ".jpg"]

var _cache := {}


## 按相对路径（不带扩展名）取图，比如 "furniture/rtable_0"。
func tex(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var t: Texture2D = null
	for ext in EXTS:
		var path: String = ROOT + key + ext
		if ResourceLoader.exists(path):
			# 在编辑器里导入过的图片
			t = load(path)
		elif FileAccess.file_exists(path):
			# 直接放进文件夹、还没导入的图片
			var img := Image.load_from_file(ProjectSettings.globalize_path(path))
			if img != null and not img.is_empty():
				t = ImageTexture.create_from_image(img)
		if t != null:
			break
	_cache[key] = t
	return t


func guest(type_name: String) -> Texture2D:
	return tex(GUEST_FILES.get(type_name, ""))


## look：第几套长相。staff/chef.png 是第 0 套，staff/chef_2.png、chef_3.png 是另外两套；缺图就用第 0 套。
func staff(role: String, look := 0) -> Texture2D:
	var base: String = ROLE_FILES.get(role, "")
	var t: Texture2D = tex(base + "_%d" % (look + 1)) if look > 0 else null
	return t if t != null else tex(base)


func dish(dish_name: String) -> Texture2D:
	return tex("dishes/" + dish_name)
