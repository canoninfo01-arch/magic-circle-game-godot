extends Node
# 2026-11-25：英語化。日本語の原文をそのままキーにして英語を引く。
# Godot標準の翻訳の仕組み（TranslationServer）に登録するので、Label/Button の text に
# 原文を入れておけば自動で切り替わる。数字を埋め込む文だけは tr("原文") % 値 と書く。
# 言語は「保存済みの選択 → なければ端末/ブラウザの言語（日本語以外は英語）」で決める。

const SETTINGS_PATH := "user://settings.cfg"

const EN := {
	# ── バトルHUD・描画 ──
	"仲間: 0": "Allies: 0",
	"仲間: %d / %d": "Allies: %d / %d",
	"召喚まで: %d/%d": "Summon: %d/%d",
	"✓ ラップ確定": "✓ Lock lap",
	"%d連続！": "%d combo!",
	"属性を選んで仲間を召喚！": "Pick an element to summon!",
	"← スティックで移動・敵を避けよう": "← Drag to move & dodge",
	"出撃前に装備した紋章で強さが決まる！": "Equipped sigils set ally power!",
	# ── 武器選択 ──
	"紋章の武器を選択": "Choose a weapon",
	"NEW！取得": "NEW!",
	"紋章の雨": "Sigil Rain",
	"貫通の矢": "Piercing Arrow",
	"爆裂の紋章弾": "Burst Bolt",
	"稲妻の鎖": "Chain Lightning",
	"固めるビーム": "Binding Beam",
	"衝撃の紋章波": "Shock Wave",
	# ── 属性選択・召喚 ──
	"属性を選ぶ": "Choose element",
	"水": "Water",
	"火": "Fire",
	"土": "Earth",
	"スキップ（戦闘に戻る）": "Skip (back to battle)",
	"PERFECT召喚": "PERFECT Summon",
	"GREAT召喚": "GREAT Summon",
	"GOOD召喚": "GOOD Summon",
	"召喚": "Summon",
	"パワー %d（%d周）": "Power %d (%d laps)",
	"召喚！": "Summon!",
	"紋章・中位！": "Sigil up!",
	"二重丸！": "Double Circle!",
	"六芒星！": "Hexagram!",
	"八芒星！": "Octagram!",
	# ── 一時停止・結果 ──
	"一時停止中": "Paused",
	"再開": "Resume",
	"リスタート": "Restart",
	"ステージ選択へ": "Stage select",
	"%d秒": "%ds",
	"%s 生存": "Survived %s",
	"ベスト: %s": "Best: %s",
	"残光 +%d": "Afterglow +%d",
	"次へ": "Next",
	"紋章tier2が解放された！": "Tier 2 sigils unlocked!",
	"紋章tier3が解放された！": "Tier 3 sigils unlocked!",
	"エンドレスモードが解放された！": "Endless mode unlocked!",
	# ── 装備選択（LoadoutScene） ──
	"紋章を選ぶ": "Choose sigils",
	"出撃前に、属性ごとの紋章を装備する": "Equip a sigil for each element",
	"残光: %d": "Afterglow: %d",
	"セーブをリセット": "Reset save",
	"強化": "Upgrade",
	"バトル開始": "Start battle",
	"ステージ": "Stage",
	"%s属性": "%s",
	"基本": "Basic",
	"中位": "Mid",
	"上位": "High",
	"5分": "5 min",
	"10分": "10 min",
	"15分": "15 min",
	"エンドレス": "Endless",
	"セーブをリセットしますか？": "Reset your save?",
	"残光・紋章解放・ステージ解放・最高記録が\n全て消えます（元に戻せません）": "Afterglow, unlocks and best times\nwill be erased (cannot be undone)",
	"リセットする": "Reset",
	"キャンセル": "Cancel",
	# ── 恒久強化 ──
	"恒久強化": "Upgrades",
	"閉じる": "Close",
	"強化 (%d)": "Upgrade (%d)",
	"体力強化": "Vitality",
	"攻撃強化": "Power",
	"機動強化": "Mobility",
	"速射強化": "Rapid Fire",
	"描画時間強化": "Draw Time",
	"最大HP +1/Lv": "Max HP +1/Lv",
	"全弾ダメージ +5%/Lv": "All damage +5%/Lv",
	"移動速度 +4%/Lv": "Move speed +4%/Lv",
	"攻撃間隔 +8%/Lv短縮": "Attack interval -8%/Lv",
	"描画フェーズ +0.6秒/Lv": "Draw phase +0.6s/Lv",
}

func _ready() -> void:
	var en := Translation.new()
	en.locale = "en"
	# 日本語側にも「原文→原文」を登録しておく。無いと日本語設定のときに
	# フォールバック（既定が英語）で英語が出てしまうため
	var ja := Translation.new()
	ja.locale = "ja"
	for k in EN:
		en.add_message(k, EN[k])
		ja.add_message(k, k)
	TranslationServer.add_translation(en)
	TranslationServer.add_translation(ja)
	TranslationServer.set_locale(_initial_lang())

func _initial_lang() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		var saved: String = cfg.get_value("ui", "lang", "") as String
		if saved == "ja" or saved == "en":
			return saved
	return "ja" if OS.get_locale_language() == "ja" else "en"

func is_en() -> bool:
	return TranslationServer.get_locale().begins_with("en")

func set_lang(lang: String) -> void:
	TranslationServer.set_locale(lang)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("ui", "lang", lang)
	cfg.save(SETTINGS_PATH)
