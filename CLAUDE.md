# cDisplay

macOSデスクトップアプリ。黒いマスク（レターボックス/ピラーボックス）を画面に重ねて、任意のアスペクト比の疑似表示領域を作成する。

仕様書: [docs/SPEC.md](docs/SPEC.md)

## ビルド・実行

```bash
# ビルド
xcodebuild -scheme cDisplay -configuration Debug build

# リリースビルド
xcodebuild -scheme cDisplay -configuration Release build

# テスト
xcodebuild test -scheme cDisplay
```

- Xcode 15以上
- デプロイメントターゲット: macOS 14.0

## コードスタイル

- 型名: UpperCamelCase、プロパティ・メソッド: lowerCamelCase
- アクセス制御: private をデフォルトとし、必要に応じて緩める
- force unwrap (`!`) 禁止（IBOutlet以外）。guard-let / if-let を使う
- 非同期処理: Swift Concurrency (async/await) を優先。AppKitのスレッド制約がある場合のみGCD
- UI関連コードは `@MainActor`

## アーキテクチャ

- パターン: MVVM-lite（Views + ViewModels、重量フレームワーク不使用）
- ライフサイクル: AppDelegate方式（SwiftUI Appではない）
- メニューバー: NSStatusItem + NSMenu
- マスク描画: NSPanel（floating、non-activating）
- 設定保存: UserDefaults（MAS Sandbox互換）
- サードパーティ依存: なし

詳細: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

## 制約

- App Sandbox: ON（MAS必須）。特別なentitlementは不要
- 画面収録権限: 不要（マスクはオーバーレイウィンドウであり、キャプチャではない）
- UI言語: 英語のみ（v1）
- Dockアイコン: 表示。クリックでマスクON/OFFトグル
- マスク範囲: メニューバーより下のみ（メニューバーは覆わない）
- 対象ディスプレイ: 一度に1つのみ

## ファイル構成

```
cDisplay/
  App/              -- AppDelegate、アプリライフサイクル
  Models/           -- AspectRatio、DisplayInfo、Settings 等の列挙型・構造体
  ViewModels/       -- MaskViewModel、MenuViewModel
  Views/            -- MaskOverlayPanel、OnboardingWindow
  Menu/             -- StatusBarController、MenuBuilder
  Services/         -- DisplayService、MaskService、SettingsService
  Resources/        -- Assets.xcassets、メニューバーアイコン
  Supporting/       -- Info.plist、Entitlements
```
