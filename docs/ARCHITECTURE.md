# アーキテクチャ

## 全体構成

```
┌──────────────────────────────────────────────────────┐
│                     AppDelegate                      │
│  ┌──────────────┐  ┌─────────────────────────────┐  │
│  │ StatusBar    │  │ DisplayModeViewModel         │  │
│  │ Controller   │  │  ├─ DisplayModeService       │  │
│  │  ├─ NSStatus │  │  │   (CoreGraphics解像度変更) │  │
│  │  │   Item    │  │  ├─ MaskService              │  │
│  │  └─ Menu     │  │  │   ├─ MaskOverlayPanel x2-4│  │
│  │     Builder  │  │  │   └─ DisplayService       │  │
│  └──────────────┘  │  └─ SettingsService          │  │
│                    └─────────────────────────────┘  │
│  ┌──────────────────────────────────────────────┐   │
│  │     main.swift (クラッシュリカバリ)            │   │
│  └──────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────┘
```

## データフロー

```
ユーザー操作 (メニュー/Dock)
  → StatusBarController.toggle()
    → DisplayModeViewModel.toggle() / applyTarget()
      ┌─ DisplayModeService.applyMode()     ... 解像度変更
      ├─ DisplayService.maskRects()          ... ジオメトリ計算
      └─ MaskService.showMask()             ... マスクパネル表示
        → MaskOverlayPanel(s) 画面描画
  → SettingsService に永続化
  → メニュー再構築 & アイコン更新
```

## ハイブリッド表示方式

`DisplayMethod` 列挙型で3つの表示方式を管理する：

| 方式 | enum case | 動作 |
|------|-----------|------|
| 解像度変更のみ | `.resolution(DisplayMode)` | CoreGraphicsでOS解像度を切り替え |
| マスクのみ | `.mask(AspectRatio)` | NSPanelオーバーレイで表示領域を制限 |
| 解像度変更＋マスク補完 | `.resolutionPlusMask(DisplayMode, TargetResolution)` | 最近接解像度に変更後、差分をマスクで補完 |

`DisplayModeViewModel.applyTarget()` が以下のロジックでフォールバックする：

1. ターゲット解像度に最も近いディスプレイモードを検索
2. モードが存在しない → `.mask` (マスクのみ)
3. モードがターゲットと完全一致 → `.resolution` (解像度変更のみ)
4. モードがターゲットと不一致 → `.resolutionPlusMask` (解像度変更後、マスク補完)

## マスク描画方式

**複数NSPanel方式**を採用する。

アスペクト比と画面比率に応じて、2枚または4枚のNSPanelを配置する：

- 横長アスペクト比（例: 16:9の画面に4:3を適用）: 左右に2枚
- 縦長アスペクト比（例: 16:10の画面に16:9を適用）: 上下に2枚
- 表示領域が画面と縦横両方異なる場合: 上下左右に最大4枚

### NSPanelの構成

```swift
let panel = NSPanel(
    contentRect: maskRect,
    styleMask: [.borderless, .nonactivatingPanel],
    backing: .buffered,
    defer: false
)
panel.level = .floating
panel.backgroundColor = .black
panel.isOpaque = true
panel.hasShadow = false
panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
panel.ignoresMouseEvents = true  // クリック透過（固定）
```

## ウィンドウレベル

`NSWindow.Level.floating` を使用する。

- 通常のアプリケーションウィンドウ（`.normal`）より上
- システムUI（メニューバー、Spotlight、通知センター）より下
- フルスクリーンアプリケーションとは競合しない

## 画面ジオメトリ計算

### 基準座標

`NSScreen.main?.visibleFrame` を基準とする。`visibleFrame` はメニューバーとDockを除いた利用可能領域を返すため、メニューバーを覆わない要件を自然に満たす。

### マスク矩形の算出

```
入力:
  - screenFrame: NSScreen.visibleFrame（利用可能画面領域）
  - ratio: ターゲット解像度のアスペクト比
  - offset: オフセット位置（center / top / bottom）

処理:
  1. screenFrameのアスペクト比と目標比率を比較
  2. 目標比率に合う最大の内接矩形を算出
  3. offsetに基づいて内接矩形を配置
  4. screenFrameから内接矩形を引いた残りがマスク領域
```

### オフセット位置の計算

横方向マスク（上下に黒帯）の場合:
- **中央**: 上下のマスク高さが均等
- **上寄せ**: 表示領域がvisibleFrameの上端に配置。下側のみマスク
- **下寄せ**: 表示領域がvisibleFrameの下端に配置。上側のみマスク

縦方向マスク（左右に黒帯）の場合:
- 常に水平中央固定。左右のマスク幅は均等

## 解像度変更（DisplayModeService）

CoreGraphics APIを使用してOS表示解像度を切り替える。

### 主要メソッド

- `availableModeGroups()`: 利用可能な全ディスプレイモードを取得し、アスペクト比ごとにグループ化。HiDPIモードを優先して重複排除
- `closestMode(toWidth:toHeight:)`: ターゲット解像度に最も近いモードを検索。アスペクト比一致を優先し、次に面積の近さで選択
- `applyMode(_:)`: `CGDisplaySetDisplayMode` で解像度を切り替え。初回切り替え時に元のモードを保存
- `restoreOriginalMode()`: 元の解像度に復元

### クラッシュリカバリ

解像度変更は永続的なOS設定の変更であるため、クラッシュリカバリ機構を実装する：

1. 解像度変更時に元のモードIDをUserDefaultsに保存
2. `main.swift` でUI初期化前に `DisplayModeService.restoreIfNeeded()` を呼び出し
3. クラッシュフラグが存在する場合、元の解像度を復元してフラグをクリア

## フェードアニメーション

`NSAnimationContext` を使用して0.25秒のフェード効果を実現する：

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.25
    for panel in maskPanels {
        panel.animator().alphaValue = targetAlpha  // 0.0 or 1.0
    }
} completionHandler: {
    if targetAlpha == 0.0 {
        for panel in maskPanels {
            panel.orderOut(nil)
        }
    }
}
```

## ガイドライン描画

マスクパネルの表示領域側の端に1ptの白線を描画する。

`MaskPanelView` の `draw(_:)` メソッドで、`GuidelineEdge`（top/bottom/left/right）に応じた端に白い境界線を描画する。`MaskService` がマスク矩形と表示領域の位置関係からガイドラインの描画方向を自動判定する。

## 同一アスペクト比の検出

`DisplayService.maskRects()` で、表示領域のアスペクト比が画面と一致する場合（マスク幅が実質0の場合）nilを返す。許容範囲（0.01）を設けて浮動小数点の丸め誤差を考慮する。
