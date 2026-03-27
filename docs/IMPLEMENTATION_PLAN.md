# 実装計画

仕様書・アーキテクチャに基づく段階的実装スケジュール。各フェーズをプルリクエスト単位で進める。

## フェーズ一覧

| # | タイトル | 概要 | 優先度 |
|---|----------|------|--------|
| 1 | Xcodeプロジェクト基盤 | プロジェクト骨格、ファイル構成、AppDelegate | 必須 |
| 2 | モデル層 | AspectRatio、OffsetPosition、ClickMode等の値型 | 必須 |
| 3 | SettingsService | UserDefaultsによる設定永続化 | 必須 |
| 4 | DisplayService | 画面情報取得・ジオメトリ計算 | 必須 |
| 5 | MaskOverlayPanel | NSPanelによるマスク描画（コア機能） | 必須 |
| 6 | MaskService / MaskViewModel | マスクON/OFF制御・フェードアニメーション | 必須 |
| 7 | StatusBarController / MenuBuilder | メニューバーアイコン・ドロップダウンメニュー | 必須 |
| 8 | ガイドライン表示 | マスク境界の白線描画 | 必須 |
| 9 | クリックモード | クリック透過 / 遮断切り替え | 必須 |
| 10 | グローバルキーボードショートカット | マスクON/OFFショートカット・カスタマイズ | 必須 |
| 11 | Dockアイコン操作 | Dockクリックでマスクトグル | 必須 |
| 12 | ディスプレイ変更検知 | 解像度変更・外部モニター抜差し時の自動OFFと同一アスペクト比検出 | 必須 |
| 13 | オンボーディング | 初回起動時の2〜3ステップツアー | 仕上げ |
| 14 | アクセシビリティ | VoiceOverラベル・状態アナウンス | 仕上げ |
| 15 | App Storeリリース準備 | アイコン、メタデータ、Sandboxテスト | リリース前 |

---

## 各フェーズ詳細

### Phase 1: Xcodeプロジェクト基盤

**目標**: ビルドが通る最小限の骨格を作る

- Xcodeプロジェクト（`.xcodeproj`）の作成
  - Bundle ID: `com.example.cDisplay`（後で変更可）
  - デプロイメントターゲット: macOS 14.0
  - App Sandbox: ON、必要最小限のEntitlements
- CLAUDE.mdに記載のファイル構成どおりにディレクトリ作成
- `AppDelegate.swift`（空のスタブ）
- `Info.plist` / `cDisplay.entitlements`
- `MainMenu.xib` なし（コードのみ）

**完了条件**: `xcodebuild -scheme cDisplay -configuration Debug build` が成功する

---

### Phase 2: モデル層

**目標**: アプリ全体で使う値型を定義する

- `AspectRatio.swift` — enum（widescreen/standard/cinemascope/square/vertical）、比率計算プロパティ
- `OffsetPosition.swift` — enum（center/top/bottom）
- `ClickMode.swift` — enum（passthrough/blocking）
- `DisplayInfo.swift` — struct（解像度・利用可能領域）

**完了条件**: モデルの単体テストが通る

---

### Phase 3: SettingsService

**目標**: UserDefaultsラッパーで設定を読み書きする

- `SettingsService.swift`
  - 保存項目: AspectRatio、OffsetPosition、ClickMode、showGuideline、keyboardShortcut
  - デフォルト値の定義
  - 保存しない項目: マスクON/OFF（起動時は常にOFF）

**完了条件**: 設定の書き込み・読み込みが正しく動作するテストが通る

---

### Phase 4: DisplayService

**目標**: 画面情報取得とジオメトリ計算

- `DisplayService.swift`
  - `NSScreen.main?.visibleFrame` 取得
  - 内接矩形計算（アスペクト比 + オフセット）
  - マスク矩形群の算出（2〜4枚のNSPanelに対応するRectの配列）
  - 同一アスペクト比の検出（許容差0.01）

**完了条件**: 各アスペクト比・オフセットの組み合わせで正しいRectが算出されるテストが通る

---

### Phase 5: MaskOverlayPanel

**目標**: 黒いマスクパネルを画面に表示する

- `MaskOverlayPanel.swift` — NSPanelサブクラス
  - `styleMask: [.borderless, .nonactivatingPanel]`
  - `level = .floating`
  - `backgroundColor = .black`、`isOpaque = true`、`hasShadow = false`
  - `collectionBehavior: [.canJoinAllSpaces, .stationary]`
- `MaskPanelView.swift` — contentViewサブクラス（ガイドライン描画用、Phase 8で使用）
- 複数パネルの配置ロジック

**完了条件**: 手動でパネルを表示すると画面上に黒帯が現れる

---

### Phase 6: MaskService / MaskViewModel

**目標**: マスクのON/OFF制御とフェードアニメーション

- `MaskViewModel.swift`
  - `isMaskEnabled: Bool`（Publisherパターンまたはコールバック）
  - アスペクト比・オフセット変更時のパネル更新
- `MaskService.swift`
  - パネルの生成・破棄管理
  - フェードイン（0.25秒）/ フェードアウト（0.25秒）
  - `NSAnimationContext` による実装

**完了条件**: メニューバーなしでコードからON/OFFトグルが動作する

---

### Phase 7: StatusBarController / MenuBuilder

**目標**: メニューバーアイコンとドロップダウンメニュー

- `StatusBarController.swift` — NSStatusItem管理
  - マスクOFF時: アウトライン風アイコン
  - マスクON時: ソリッド風アイコン
- `MenuBuilder.swift` — NSMenuの構築
  - マスクON/OFFトグル
  - アスペクト比サブメニュー（チェックマーク付き）
  - オフセット位置サブメニュー
  - クリックモードサブメニュー
  - ガイドライントグル
  - ディスプレイ情報（マスクON時のみ）
  - バージョン表示
  - 終了
- `Resources/` にメニューバーアイコン素材追加（SF Symbols or カスタム）

**完了条件**: メニューバーからマスクのON/OFFと全設定が操作できる

---

### Phase 8: ガイドライン表示

**目標**: マスク境界に白い1pt線を描画する

- `MaskPanelView.draw(_:)` に境界線描画ロジック実装
- パネルの向き（上下/左右）に応じた端の判定
- showGuideline の変更をリアルタイムで反映

**完了条件**: メニューからガイドラインのON/OFFが切り替わり、境界線が表示される

---

### Phase 9: クリックモード

**目標**: クリック透過 / 遮断の切り替え

- クリック透過: `panel.ignoresMouseEvents = true`
- クリック遮断: `panel.ignoresMouseEvents = false` + `resetCursorRects()` で禁止カーソル

**完了条件**: クリック遮断モードでマスク上のカーソルが禁止アイコンになり、クリックが背後に届かない

---

### Phase 10: グローバルキーボードショートカット

**目標**: マスクON/OFFのグローバルショートカット

- デフォルトキー: `⌃⌥⌘M`（OBS等との競合を避けた組み合わせ）
- `CGEventTap` または `NSEvent.addGlobalMonitorForEvents` を使用
- メニューバーのドロップダウンからキー変更UI

**完了条件**: アプリが非フォーカス状態でもショートカットでマスクがトグルする

---

### Phase 11: Dockアイコン操作

**目標**: Dockクリックでマスクをトグル

- `AppDelegate.applicationShouldHandleReopen(_:hasVisibleWindows:)` でトグル実装
- Dockアイコン用アセット（`AppIcon`）の設定

**完了条件**: Dockアイコンをクリックするとマスクがトグルする

---

### Phase 12: ディスプレイ変更検知・同一アスペクト比検出

**目標**: 解像度変更時の自動OFFと同一比率の通知

- `NSApplication.didChangeScreenParametersNotification` を監視
- 変更時: マスク即時OFF + アイコン更新
- マスクON時: 同一アスペクト比検出 → アラート表示してOFFを維持

**完了条件**: 解像度変更または外部モニター抜差しでマスクが自動OFFになる

---

### Phase 13: オンボーディング

**目標**: 初回起動時の操作ガイド

- `OnboardingWindow.swift` — 2〜3ステップのウィンドウ
  - Step 1: マスクの切り替え方法
  - Step 2: アスペクト比と設定
  - Step 3: 画面キャプチャツールとの併用
- 表示済みフラグを UserDefaults に保存

**完了条件**: 初回起動時のみオンボーディングが表示され、次回以降は表示されない

---

### Phase 14: アクセシビリティ

**目標**: 基本的なVoiceOver対応

- メニュー項目の `accessibilityLabel` 設定
- マスクON/OFF時の `NSAccessibility.post(element:notification:)` による状態アナウンス

**完了条件**: VoiceOverでメニュー操作が可能で、状態変化が読み上げられる

---

### Phase 15: App Storeリリース準備

**目標**: MAS提出可能な状態にする

- アプリアイコン全サイズ（`AppIcon.appiconset`）
- App Store Connect用メタデータ（説明文、スクリーンショット等）
- Sandbox動作の最終確認
- アクセシビリティ監査
- `Release` ビルド・アーカイブ・ノータリゼーション

**完了条件**: `xcodebuild -scheme cDisplay -configuration Release archive` が成功し、Sandbox制約に問題がない
