# GAGA セットアップガイド

## 🎉 プロジェクト構造の作成が完了しました！

以下のファイルとディレクトリが作成されました：

### 📁 作成されたファイル構造

```
GAGA/
├── Models/
│   ├── User.swift
│   ├── Photo.swift
│   ├── Country.swift
│   └── Region.swift
├── Core/
│   ├── Globe/
│   │   ├── GlobeView.swift
│   │   ├── GlobeViewController.swift
│   │   ├── GlobeGeometry.swift
│   │   └── GlobeMaterial.swift
│   ├── Photo/
│   │   ├── PhotoProcessor.swift
│   │   ├── PhotoUploader.swift
│   │   └── PhotoCache.swift
│   └── Location/
│       ├── CountryDetector.swift
│       └── GeoDataManager.swift
├── Features/
│   ├── Auth/
│   │   ├── LoginView.swift
│   │   └── AuthManager.swift
│   ├── Camera/
│   │   ├── CameraView.swift
│   │   └── PhotoPicker.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── UserGlobeView.swift
│   └── Social/
│       ├── FollowManager.swift
│       └── UserSearchView.swift
├── Services/
│   ├── FirebaseService.swift
│   ├── StorageService.swift
│   └── NotificationService.swift
├── GAGAApp.swift (更新済み)
└── ContentView.swift (更新済み)
```

## ⚠️ 手動で行う必要がある操作

### 1. Xcodeで新規ファイルをプロジェクトに追加

作成した新規ファイルをXcodeプロジェクトに追加する必要があります：

**方法A: ドラッグ&ドロップ**
1. Xcodeを開く
2. プロジェクトナビゲーターで `GAGA` グループを右クリック
3. `Add Files to "GAGA"...` を選択
4. 以下のフォルダを選択して追加:
   - `Models`
   - `Core`
   - `Features`
   - `Services`

**方法B: Finderからドラッグ**
1. Finderで `/Volumes/Extreme SSD/GAGA/GAGA/` を開く
2. `Models`, `Core`, `Features`, `Services` フォルダをXcodeのプロジェクトナビゲーターにドラッグ
3. **重要**: "Copy items if needed" にチェックを入れない
4. "Create groups" を選択

### 2. 必要な権限をInfo.plistまたはTarget設定に追加

Xcodeで以下の権限を追加してください：

**Target → Info → Custom iOS Target Properties に追加:**

| Key | Value | 説明 |
|-----|-------|------|
| `Privacy - Camera Usage Description` | `写真を撮影するためにカメラへのアクセスが必要です` | カメラアクセス |
| `Privacy - Photo Library Usage Description` | `写真を選択するためにフォトライブラリへのアクセスが必要です` | フォトライブラリ |
| `Privacy - Photo Library Additions Usage Description` | `写真を保存するためにフォトライブラリへのアクセスが必要です` | 写真保存 |
| `Privacy - Location When In Use Usage Description` | `訪問した場所を記録するために位置情報が必要です（オプション）` | 位置情報 |

**Xcodeでの追加方法:**
1. プロジェクトナビゲーターで `GAGA.xcodeproj` を選択
2. `GAGA` ターゲットを選択
3. `Info` タブを開く
4. `Custom iOS Target Properties` セクションで `+` ボタンをクリック
5. 上記の項目を追加

### 3. Swift Package Managerで依存関係を追加

Xcodeで以下のパッケージを追加してください：

**追加方法:**
1. Xcode メニューから `File` → `Add Package Dependencies...`
2. 以下のURLを順番に追加:

#### Firebase iOS SDK
```
https://github.com/firebase/firebase-ios-sdk
```
- バージョン: `10.0.0` 以上
- 追加するプロダクト:
  - FirebaseAuth
  - FirebaseFirestore
  - FirebaseStorage
  - FirebaseMessaging

#### GEOSwift (地理データ処理)
```
https://github.com/GEOSwift/GEOSwift
```
- バージョン: `10.0.0` 以上

#### SDWebImageSwiftUI (画像キャッシュ)
```
https://github.com/SDWebImage/SDWebImageSwiftUI
```
- バージョン: `2.0.0` 以上

### 4. Firebase設定ファイルを追加

1. [Firebase Console](https://console.firebase.google.com/) でプロジェクトを作成
2. iOS アプリを追加
3. `GoogleService-Info.plist` をダウンロード
4. Xcodeプロジェクトのルートに追加 (Target membershipをチェック)

### 5. Capabilities の追加

**Target → Signing & Capabilities で追加:**

1. `Sign in with Apple` を追加
   - `+` ボタン → `Sign in with Apple`
2. `Push Notifications` を追加
   - `+` ボタン → `Push Notifications`
3. `Background Modes` を追加 (将来的に)
   - `+` ボタン → `Background Modes`
   - `Remote notifications` にチェック

## 📝 次のステップ

### すぐに実行可能

現在のコードで基本的なUIは動作します：

1. Xcodeでビルド (`Cmd + B`)
2. シミュレーターまたは実機で実行 (`Cmd + R`)
3. 3D地球儀が表示されます（現在は青い球体）

### 今後の実装が必要な機能

以下の機能はTODOとしてマークされており、今後の実装が必要です：

#### Phase 2: Firebase統合
- [ ] FirebaseApp.configure()の追加
- [ ] 認証機能の実装
- [ ] Firestoreデータ保存・読み込み
- [ ] Storage写真アップロード

#### Phase 3: 地理データ統合
- [ ] Natural Earth GeoJSONのダウンロード
- [ ] 国境線の3D表示
- [ ] タップ位置から国を検出
- [ ] 国の形状マスク生成

#### Phase 4: 写真マスキング
- [ ] Core Imageでのマスキング処理
- [ ] Equirectangular投影
- [ ] テクスチャアトラス管理

## 🐛 トラブルシューティング

### ビルドエラーが出る場合

1. **"Cannot find 'Firebase' in scope"**
   → Swift Package Managerで Firebase SDK を追加

2. **"Missing GoogleService-Info.plist"**
   → Firebase Consoleから plist をダウンロードして追加

3. **"Sign in with Apple capability not found"**
   → Signing & Capabilities で Sign in with Apple を追加

4. **新規ファイルが見つからない**
   → Xcodeプロジェクトにファイルを手動で追加

## 📚 参考リンク

- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [SceneKit Documentation](https://developer.apple.com/documentation/scenekit)
- [Sign in with Apple](https://developer.apple.com/documentation/sign_in_with_apple)
- [Natural Earth Data](https://www.naturalearthdata.com/)

## 🎊 完了！

セットアップが完了すると、GAGAアプリの基本構造が動作します。
README.mdの実装手順に従って、段階的に機能を追加していってください。

質問や問題があれば、プロジェクトのIssuesで報告してください！
