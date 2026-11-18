extends RefCounted

const CODES := ["en", "zh_CN", "zh_TW", "ja", "ko"]
const NAMES := ["English", "中文（简体）", "中文（繁體）", "日本語", "한국어"]
const FONTS := ["", "SC", "TC", "JP", "KR"]
static var faces: Dictionary = {}
static var installed := false

static func install() -> void:
	if installed:
		return
	for code in CODES:
		var path := "res://i18n/strings.%s.translation" % code
		if ResourceLoader.exists(path):
			TranslationServer.add_translation(load(path))
	installed = true

static func current() -> int:
	return maxi(0, CODES.find(TranslationServer.get_locale()))

static func text(key: String) -> String:
	return String(TranslationServer.translate(key))

static func face(index: int, headline := false) -> Font:
	var file: String = FONTS[index]
	if file.is_empty():
		file = "BarlowCondensed-ExtraBold" if headline else "Inter"
	else:
		file = "ShiftSans" + file
	if not faces.has(file):
		var path := "res://assets/" + file + ".ttf"
		if ResourceLoader.exists(path):
			faces[file] = load(path)
		else:
			return ThemeDB.fallback_font
	return faces[file]
