# 🌍 GAGA- 3D地球儀写真共有アプリ

旅行の思い出を3D地球儀に刻む、新しい形の写真共有アプリ

## 📋 プロジェクト概要

GAGAは、ユーザーが訪れた国や地域の写真を3D地球儀上に投稿し、地球を自分の写真で埋めていく革新的なソーシャルアプリです。他のユーザーの地球儀を閲覧し、世界中の旅行体験を共有できます。

### 主要コンセプト
- 🌐 回転・ズーム可能な3D地球儀インターフェース
- 📷 国や地域の形にマスキングされた写真表示
- 🎯 タップで簡単に写真投稿
- 👥 他ユーザーの地球儀を探索
- 🏆 地球を写真で埋めていく達成感

## 🎯 要件定義

### 機能要件

#### Phase 1: MVP（1-2ヶ月）
- [ ] **認証システム**
  - Apple ID サインイン
  - メールアドレス認証
  - プロフィール作成

- [ ] **3D地球儀**
  - 球体表示（SceneKit）
  - 回転・ズーム操作
  - 国境線表示（国レベル）
  - タップ位置検出

- [ ] **写真投稿**
  - カメラ/ライブラリから選択
  - 位置情報タグ付け
  - 国・地域の形にマスキング
  - Firebase Storageアップロード

- [ ] **写真表示**
  - 地球儀上に写真テクスチャ表示
  - 未投稿地域は白色表示
  - タップで投稿詳細画面
  - 写真の削除・編集

- [ ] **ユーザー機能**
  - 自分の地球儀表示
  - 他ユーザーの地球儀閲覧
  - フォロー/フォロワー機能

#### Phase 2: SNS機能（3ヶ月目以降）
- [ ] いいね・コメント機能
- [ ] プッシュ通知
- [ ] 州・県レベル表示
- [ ] ランキング・統計
- [ ] 多言語対応（日本語・英語）

### 非機能要件
- **パフォーマンス**: 60fps維持（iPhone 12以降）
- **対応OS**: iOS 16.0以上
- **対応デバイス**: iPhone専用（初期版）
- **データ容量**: 写真1枚あたり最大2MB（圧縮後）
- **応答時間**: 地球儀操作は即座、写真読み込みは3秒以内

## 🛠 技術スタック

### フロントエンド
```yaml
UI Framework: SwiftUI + Combine
3D Engine: SceneKit（将来的にRealityKit移行）
地理データ: GEOSwift + Natural Earth
画像処理: Core Image + Vision Framework
画像キャッシュ: SDWebImage
```

### バックエンド
```yaml
認証: Firebase Authentication
データベース: Cloud Firestore
ストレージ: Firebase Storage
サーバー処理: Cloud Functions
プッシュ通知: Firebase Cloud Messaging
```

### 開発環境
```yaml
IDE: Xcode 15.0+
言語: Swift 5.9
依存管理: Swift Package Manager
開発補助: Cursor AI Editor
```

## 📦 Package Dependencies

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/GEOSwift/GEOSwift", from: "10.0.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "2.0.0"),
]
```

## 🗂 プロジェクト構造

```
TravelGlobe/
├── App/
│   ├── TravelGlobeApp.swift
│   └── AppDelegate.swift
├── Core/
│   ├── Globe/
│   │   ├── GlobeView.swift           # SceneKit地球儀View
│   │   ├── GlobeViewController.swift  # 3D制御ロジック
│   │   ├── GlobeGeometry.swift       # ジオメトリ生成
│   │   └── GlobeMaterial.swift       # テクスチャ管理
│   ├── Photo/
│   │   ├── PhotoProcessor.swift      # マスキング処理
│   │   ├── PhotoUploader.swift       # Firebase Storage
│   │   └── PhotoCache.swift          # キャッシュ管理
│   └── Location/
│       ├── CountryDetector.swift     # タップ位置→国判定
│       └── GeoDataManager.swift      # Natural Earthデータ
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
├── Models/
│   ├── User.swift
│   ├── Photo.swift
│   ├── Country.swift
│   └── Region.swift
├── Services/
│   ├── FirebaseService.swift
│   ├── StorageService.swift
│   └── NotificationService.swift
├── Resources/
│   ├── Assets.xcassets/
│   ├── GeoData/
│   │   ├── countries-50m.geojson
│   │   ├── states-10m.geojson
│   │   └── country-masks/
│   └── Shaders/
│       └── PhotoBlend.metal
└── GoogleService-Info.plist
```

## 🚀 実装手順

### Week 1-2: 基盤構築
```bash
# 1. プロジェクトセットアップ
xcodegen generate  # プロジェクト生成
swift package resolve  # 依存関係解決

# 2. Firebase設定
firebase init
# Functions, Firestore, Storage, Authenticationを選択

# 3. 地理データ準備
./scripts/prepare-geodata.sh
# Natural EarthからGeoJSONダウンロード・簡略化
```

#### 主要タスク
- [ ] Xcodeプロジェクト作成
- [ ] Firebase SDK統合
- [ ] SwiftUIの基本画面構成
- [ ] SceneKit地球儀の基本実装

### Week 3-4: 3D地球儀実装
```swift
// GlobeView.swift - 基本実装
struct GlobeView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        
        // 地球儀作成
        let globe = SCNSphere(radius: 1.0)
        globe.segmentCount = 96
        
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "earth_base")
        globe.materials = [material]
        
        let globeNode = SCNNode(geometry: globe)
        scene.rootNode.addChildNode(globeNode)
        
        // カメラ設定
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 0, 3)
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.scene = scene
        sceneView.allowsCameraControl = true
        
        return sceneView
    }
}
```

#### 主要タスク
- [ ] 地球儀の表示とジェスチャー操作
- [ ] 国境線の表示（GeoJSONから生成）
- [ ] タップ位置から国を特定
- [ ] LODシステム実装（ズームレベル対応）

### Week 5-6: 写真投稿機能
```swift
// PhotoProcessor.swift - マスキング処理
func maskPhotoToCountry(_ photo: UIImage, country: Country) -> UIImage? {
    let context = CIContext()
    
    // 1. 国の形状マスクを取得
    let mask = country.generateMask(size: photo.size)
    
    // 2. Core Imageでマスキング
    guard let photoCI = CIImage(image: photo),
          let maskCI = CIImage(image: mask) else { return nil }
    
    let filter = CIFilter.blendWithAlphaMask()
    filter.inputImage = photoCI
    filter.maskImage = maskCI
    filter.backgroundImage = CIImage.white()
    
    // 3. 結果を返す
    guard let output = filter.outputImage,
          let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
    
    return UIImage(cgImage: cgImage)
}
```

#### 主要タスク
- [ ] カメラ/写真選択UI
- [ ] 写真のマスキング処理
- [ ] Firebase Storageアップロード
- [ ] 地球儀テクスチャ更新

### Week 7-8: ユーザー機能とSNS
```swift
// UserGlobeManager.swift
class UserGlobeManager: ObservableObject {
    @Published var userPhotos: [String: Photo] = [:]
    
    func loadUserGlobe(userId: String) async {
        let photos = try await FirebaseService.shared
            .getPhotos(for: userId)
        
        // 国ごとにグループ化
        let grouped = Dictionary(grouping: photos) { $0.countryCode }
        
        // テクスチャ更新
        for (country, photos) in grouped {
            if let latest = photos.first {
                updateGlobeTexture(country: country, photo: latest)
            }
        }
    }
}
```

#### 主要タスク
- [ ] ユーザープロフィール画面
- [ ] フォロー/フォロワー機能
- [ ] 他ユーザーの地球儀閲覧
- [ ] いいね・コメント基本実装

## ⚡ パフォーマンス最適化

### テクスチャ管理
```swift
// TextureAtlasManager.swift
class TextureAtlasManager {
    private let atlasSize = 2048
    private let regionSize = 256
    
    func createAtlas(photos: [Country: UIImage]) -> MTLTexture {
        // 1. 2048x2048のアトラス作成
        // 2. 8x8グリッドに64カ国分配置
        // 3. Metal Textureとして返す
    }
    
    func updateRegion(_ country: Country, with photo: UIImage) {
        // contentsTransformでGPU上で更新
        // 再アップロード不要
    }
}
```

### LOD（Level of Detail）
```yaml
距離 > 10: 国レベルのみ表示（110m精度）
距離 5-10: 主要州・県表示（50m精度）
距離 < 5: 詳細表示（10m精度）
```

### メモリ管理
- 写真は3サイズ生成: オリジナル(2MB)、中(1MB)、サムネイル(256KB)
- SDWebImageで自動キャッシング
- 非表示領域のテクスチャは解放

## 🔧 開発環境セットアップ

```bash
# 1. リポジトリクローン
git clone https://github.com/yourusername/TravelGlobe.git
cd TravelGlobe

# 2. 依存関係インストール
swift package resolve

# 3. Firebase設定
cp GoogleService-Info-Example.plist GoogleService-Info.plist
# Firebase Consoleからダウンロードしたファイルをコピー

# 4. 地理データ準備
./scripts/setup.sh

# 5. ビルド&実行
open TravelGlobe.xcodeproj
# Cmd+R で実行
```

## 🧪 テスト

```bash
# Unit Tests
swift test

# UI Tests
xcodebuild test -scheme TravelGlobe -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 📱 デバイス要件

- **最小OS**: iOS 16.0
- **推奨デバイス**: iPhone 12以降
- **必要な権限**:
  - カメラ（写真撮影）
  - フォトライブラリ（写真選択）
  - 通知（プッシュ通知）
  - 位置情報（オプション）

## 🚢 リリース計画

### Phase 1: MVP（2ヶ月）
- 基本的な地球儀と写真投稿
- ユーザー認証
- 自分の地球儀管理

### Phase 2: ソーシャル機能（3ヶ月目）
- フォロー機能
- いいね・コメント
- ユーザー検索

### Phase 3: 拡張機能（4-6ヶ月）
- 州・県レベル表示
- ランキング・統計
- 多言語対応
- iPad対応

### Phase 4: 次世代版（6ヶ月以降）
- RealityKitへ移行
- visionOS対応
- AR機能追加

## 🔮 将来の拡張計画

- **技術移行**: SceneKit → RealityKit 4
- **プラットフォーム**: iPad, Mac, Apple Vision Pro
- **収益化**: 
  - 広告表示（無料版）
  - Pro版サブスク（広告非表示、複数写真投稿）
- **AI機能**: 
  - 写真の自動ジオタグ
  - 旅行ルート提案

## 📄 ライセンス

MIT License



## 📞 サポート

- Issues: [GitHub Issues](https://github.com/yourusername/TravelGlobe/issues)
- Email: support@travelglobe.app
- Discord: [Community Server](https://discord.gg/travelglobe)

## 🙏 謝辞

- [Natural Earth](https://www.naturalearthdata.com/) - 地理データ提供
- [SwiftGlobe](https://github.com/dmojdehi/SwiftGlobe) - 実装参考
- Firebase - バックエンドインフラ

---

**Built with ❤️ for travelers and photo enthusiasts worldwide**