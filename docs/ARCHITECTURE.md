# アーキテクチャ

## 全体構成

```
┌─────────────────────────────────────────────┐
│                  AppDelegate                 │
│  ┌──────────────┐  ┌──────────────────────┐ │
│  │ StatusBar    │  │ MaskService          │ │
│  │ Controller   │  │  ├─ MaskViewModel    │ │
│  │  ├─ NSStatus │  │  ├─ MaskOverlay     │ │
│  │  │   Item    │  │  │   Panel (x2-4)   │ │
│  │  └─ NSMenu   │  │  └─ DisplayService  │ │
│  └──────────────┘  └──────────────────────┘ │
│  ┌──────────────────────────────────────────┐│
│  │           SettingsService                ││
│  │           (UserDefaults)                 ││
│  └──────────────────────────────────────────┘│
└─────────────────────────────────────────────┘
```

## マスク描画方式

**複数NSPanel方式**を採用する。

アスペクト比と画面比率に応じて、2枚または4枚のNSPanelを配置する：

- 横長アスペクト比（例: 16:9の画面に4:3を適用）: 左右に2枚
- 縦長アスペクト比（例: 16:10の画面に16:9を適用）: 上下に2枚
- 表示領域が画面と縦横両方異なる場合: 上下左右に最大4枚

### 採用理由

- **クリック透過制御がシンプル**: 各パネルで `ignoresMouseEvents` を個別に設定可能
- **描画が単純**: 各パネルは単色の黒い矩形。カスタム描画不要
- **ガイドライン表示が容易**: パネルの内側端に1ptの白線を描画するだけ

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
panel.ignoresMouseEvents = true  // デフォルト: クリック透過
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
  - ratio: 選択されたアスペクト比（例: 16/9）
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

## クリックモード実装

### クリック透過モード（デフォルト）

```swift
panel.ignoresMouseEvents = true
```

全てのマウスイベントがマスクを透過し、背後のウィンドウに到達する。

### クリック遮断モード

```swift
panel.ignoresMouseEvents = false
```

マスク領域でのクリックを遮断する。カーソルがマスク上に入ったとき、禁止カーソルを表示する：

```swift
// NSViewのresetCursorRectsをオーバーライド
override func resetCursorRects() {
    addCursorRect(bounds, cursor: .operationNotAllowed)
}
```

## ディスプレイ変更検知

以下の通知を監視し、マスクを自動的に無効化する：

```swift
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleScreenChange),
    name: NSApplication.didChangeScreenParametersNotification,
    object: nil
)
```

検知する変更:
- ディスプレイ解像度の変更
- 外部モニターの接続・切断
- ディスプレイ配置の変更

変更検知時の動作:
1. マスクを即座にOFFにする
2. メニューバーアイコンをOFF状態に更新

## フェードアニメーション

`NSAnimationContext` を使用して0.2〜0.3秒のフェード効果を実現する：

```swift
NSAnimationContext.runAnimationGroup { context in
    context.duration = 0.25
    for panel in maskPanels {
        panel.animator().alphaValue = targetAlpha  // 0.0 or 1.0
    }
} completionHandler: {
    // アニメーション完了後の処理
    if targetAlpha == 0.0 {
        for panel in maskPanels {
            panel.orderOut(nil)
        }
    }
}
```

## ガイドライン描画

マスクパネルの表示領域側の端に1ptの白線を描画する。

実装方法: マスクパネルのcontentViewに `NSView` サブクラスを配置し、`draw(_:)` メソッドで境界線を描画する。

```swift
override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    if showGuideline {
        NSColor.white.setStroke()
        let path = NSBezierPath()
        // パネルの表示領域側の端に線を描画
        path.lineWidth = 1.0
        // ... 位置はパネルの配置方向による
        path.stroke()
    }
}
```

## 同一アスペクト比の検出

表示領域のアスペクト比が画面と一致する場合（マスク幅が実質0の場合）、マスクを適用せずユーザーに通知する。判定には浮動小数点の丸め誤差を考慮し、許容範囲（例: 0.01）を設けて比較する。
