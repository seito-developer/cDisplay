# 実装計画

仕様書・アーキテクチャに基づく段階的実装スケジュール。各フェーズをプルリクエスト単位で進める。

> **方針転換**: 当初のマスクのみの方式から、解像度変更＋マスクのハイブリッド方式に移行済み。

## フェーズ一覧

| # | タイトル | 状態 |
|---|----------|------|
| 1 | Xcodeプロジェクト基盤 | ✅ 完了 |
| 2 | モデル層 | ✅ 完了 |
| 3 | SettingsService | ✅ 完了 |
| 4 | DisplayService | ✅ 完了 |
| 5 | MaskOverlayPanel | ✅ 完了 |
| 6 | MaskService | ✅ 完了 |
| 7 | StatusBarController / MenuBuilder | ✅ 完了 |
| 8 | ガイドライン表示 | ✅ 完了（描画実装済み、UIトグルは未実装） |
| 9 | Dockアイコン操作 | ✅ 完了 |
| 10 | 解像度変更（DisplayModeService） | ✅ 完了 |
| 11 | ハイブリッド方式（DisplayModeViewModel） | ✅ 完了 |
| 12 | App Storeリリース準備 | 未着手 |

---

## 各フェーズ詳細

### Phase 1: Xcodeプロジェクト基盤 ✅

- Xcodeプロジェクト作成（デプロイメントターゲット macOS 14.0、App Sandbox ON）
- ディレクトリ構成（App / Models / ViewModels / Views / Menu / Services / Resources / Supporting）
- `AppDelegate.swift`、`main.swift`
- `Info.plist`、`cDisplay.entitlements`

---

### Phase 2: モデル層 ✅

- `AspectRatio.swift` — 5つのプリセット（widescreen / standard / cinemascope / square / vertical）
- `OffsetPosition.swift` — 3つの位置（center / top / bottom）
- `DisplayInfo.swift` — 画面情報の構造体

---

### Phase 3: SettingsService ✅

- `SettingsService.swift` — UserDefaultsラッパー（シングルトン）
- 保存項目: selectedAspectRatio、selectedTarget（幅・高さ・ラベル）、selectedModeID、keyboardShortcut
- マスクON/OFF状態は保存しない（起動時は常にOFF）

---

### Phase 4: DisplayService ✅

- `DisplayService.swift` — 画面情報取得・ジオメトリ計算
- `MaskRects` 構造体（displayRect + maskRects配列）
- 内接矩形計算（アスペクト比 + オフセット位置）
- 同一アスペクト比の検出

---

### Phase 5: MaskOverlayPanel ✅

- `MaskOverlayPanel.swift` — NSPanelサブクラス（borderless、floating、non-activating）
- `MaskPanelView.swift` — contentView（ガイドライン描画対応）
- クリック透過（ignoresMouseEvents = true 固定）

---

### Phase 6: MaskService ✅

- `MaskService.swift` — マスクパネルの生成・破棄管理
- フェードイン/フェードアウト（0.25秒、NSAnimationContext）
- ガイドライン方向の自動判定（GuidelineEdge）

---

### Phase 7: StatusBarController / MenuBuilder ✅

- `StatusBarController.swift` — NSStatusItem管理、アイコン切り替え（rectangle.dashed / rectangle.fill）
- `MenuBuilder.swift` — ドロップダウンメニュー構築
  - Enable/Disable トグル
  - Resolution サブメニュー（アスペクト比ごとにグループ化されたターゲット解像度）
  - ディスプレイ情報（ネイティブ解像度、アクティブ状態）
  - バージョン表示、Quit

---

### Phase 8: ガイドライン表示 ✅（部分）

- `MaskPanelView.draw(_:)` で1pt白線描画
- パネルの表示領域側の端に描画（GuidelineEdge で方向判定）
- **未実装**: メニューからのON/OFFトグルUI

---

### Phase 9: Dockアイコン操作 ✅

- `applicationShouldHandleReopen` で表示トグル
- `activationPolicy: .regular` でDockアイコン表示

---

### Phase 10: 解像度変更（DisplayModeService） ✅

- `DisplayModeService.swift` — CoreGraphics APIによる解像度切り替え
- 利用可能モードの取得・グループ化（HiDPI優先）
- 最近接モード検索（アスペクト比一致優先 → 面積の近さ）
- 元解像度の保存・復元
- クラッシュリカバリ（main.swift で起動時に復元チェック）

---

### Phase 11: ハイブリッド方式（DisplayModeViewModel） ✅

- `DisplayModeViewModel.swift` — ハイブリッド表示の統合ロジック
- `DisplayMethod` 列挙型（.resolution / .mask / .resolutionPlusMask）
- `TargetResolution` 構造体（幅・高さ・アスペクトラベル）
- 3段階フォールバック（完全一致 → 最近接+マスク → マスクのみ）
- アプリ終了時の解像度復元

---

### Phase 12: App Storeリリース準備（未着手）

- アプリアイコン全サイズ（`AppIcon.appiconset`）
- App Store Connect用メタデータ（説明文、スクリーンショット等）
- Sandbox動作の最終確認（特にCGDisplaySetDisplayMode）
- `Release` ビルド・アーカイブ
