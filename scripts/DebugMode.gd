extends Node

# デバッグ専用機能の一括ゲート（2026-09-24追加）。目的は自動プレイテスト（描画ジェスチャーが
# 再現できない・ステージ解放に時間がかかる等）を賀来（Claude Code）側からでも進められるようにすること。
#
# 本番URL（GitHub Pages / itch.io）ではONにならないよう、Web版ではURLクエリに`debug=1`が
# 付いている時だけ有効になる。`https://.../?debug=1`のようにアクセスした時だけ裏メニューが出る。
# 一般プレイヤーがこのURLを踏むことは通常ないが、11月の一般公開前には本当に隠すべきか再検討すること。
#
# デスクトップ実行（Godotエディタでの再生、デバッグAPK等）では常に有効（動作確認用）。
var enabled: bool = false

func _ready() -> void:
	if OS.has_feature("web"):
		var query: String = JavaScriptBridge.eval("window.location.search || ''", true) as String
		enabled = query.find("debug=1") != -1
	else:
		enabled = true
