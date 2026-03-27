# 開発ガイド

## 前提条件

| 項目                  | 要件           |
|-----------------------|----------------|
| Xcode                 | 15.0以上       |
| macOS SDK             | 14.0以上       |
| デプロイメントターゲット | macOS 14.0     |
| Swift                 | 5.9以上        |
| Apple Developer       | 必要（MAS配布） |

## プロジェクトセットアップ

```bash
# リポジトリのクローン
git clone <repository-url>
cd cDisplay

# Xcodeで開く
open cDisplay.xcodeproj
```

Xcodeで開いた後：
1. Signing & Capabilities でチーム（Apple Developer Account）を選択
2. Bundle Identifierを設定
3. Product > Run (⌘R) でビルド・実行

## ビルド設定

### Debug

開発・デバッグ用。コンパイラ最適化なし、デバッグシンボル有効。

```bash
xcodebuild -scheme cDisplay -configuration Debug build
```

### Release

App Store提出用。コンパイラ最適化有効、デバッグシンボル無効。

```bash
xcodebuild -scheme cDisplay -configuration Release build
```

## テスト戦略

### ユニットテスト

以下の純粋なロジックに対してユニットテストを作成する：

#### アスペクト比計算
- `AspectRatio` 列挙型の比率値が正しいこと
- 各プリセットの幅/高さ比率の検証

#### マスク矩形計算
- 16:10画面に16:9を適用 → 上下にマスク
- 16:9画面に4:3を適用 → 左右にマスク
- 16:9画面に9:16を適用 → 左右に広いマスク
- 各オフセット位置（中央/上寄せ/下寄せ）での矩形計算
- 画面と同一アスペクト比の検出

#### 設定の永続化
- UserDefaultsへの保存と読み込みの往復テスト
- デフォルト値の検証

```bash
xcodebuild test -scheme cDisplay
```

### UIテスト

v1では優先度低。将来的に以下を検討：
- メニューバーアイコンのクリックでメニューが開くこと
- マスクON/OFFでアイコンが変化すること

## App Sandbox設定

### Entitlements

必要最小限のentitlement：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
</dict>
</plist>
```

追加のentitlementは不要：
- 画面収録権限不要（オーバーレイウィンドウの表示に権限は不要）
- ネットワークアクセス不要
- ファイルアクセス不要

## App Store提出チェックリスト

### ビルド準備

- [ ] Bundle Identifierの確認
- [ ] バージョン番号の設定（CFBundleShortVersionString, CFBundleVersion）
- [ ] Release構成でアーカイブ
- [ ] App Sandbox entitlementの確認

### アプリ情報

- [ ] アプリアイコン（1024x1024 App Store用 + 各サイズ）
- [ ] スクリーンショット（少なくとも1サイズ）
- [ ] アプリ説明文（英語）
- [ ] カテゴリ選択（Utilities または Video）
- [ ] 価格設定

### 審査対策

- [ ] アプリの動作説明（審査メモ）: 画面上に黒いオーバーレイを表示するアプリであり、画面収録やスクリーンショットは行わないことを明記
- [ ] VoiceOver基本対応の確認
- [ ] メニュー項目すべてにアクセシビリティラベルが設定されていること

### 提出

- [ ] Xcode > Product > Archive
- [ ] Organizer > Distribute App > App Store Connect
- [ ] App Store Connectで提出

## デバッグ Tips

### マスクウィンドウの確認

Xcodeのデバッグコンソールで現在のウィンドウ一覧を確認：

```swift
NSApp.windows.forEach { window in
    print("Window: \(window.title), Level: \(window.level.rawValue), Frame: \(window.frame)")
}
```

### 画面情報の確認

```swift
if let screen = NSScreen.main {
    print("Frame: \(screen.frame)")
    print("VisibleFrame: \(screen.visibleFrame)")
    print("BackingScaleFactor: \(screen.backingScaleFactor)")
}
```
