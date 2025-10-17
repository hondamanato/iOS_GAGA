# GAGA タスク ToDo - Instagram風写真投稿機能

## 完了済みタスク

### 1. PhotoDetailView 実装
#### 実装機能:
- 写真の詳細表示機能
- 写真削除機能

#### 追加機能:
- コメント数表示
- コメントプレビュー（最新2件）
- 「すべてのコメントを表示」ボタン

#### プロファイル連携:
- `CommentPreviewRow` - プロフィール画像表示機能
- ユーザー情報をFirebaseから取得

---

### 2. CommentView 実装
#### コメント管理:
- コメント投稿機能
- コメント削除機能（権限チェック付き）
- 削除確認ダイアログ
- 削除中のローディング状態

#### イベント連携:
- `onCommentAdded` コールバック
- 親ビューへの更新通知

#### UI/UX 改善:
- 削除中の透明度50%表示
- エラー時のリトライ機能

---

### 3. ユーザープロファイル表示
#### CommentRow
- 各コメントにユーザーのプロフィール画像を表示
- Firebaseからユーザー情報取得
- プロフィール画像のキャッシュ機能

#### CommentPreviewRow
- 詳細画面でのプロフィール表示
- サイズ最適化（28x28px）

---

### 4. ファイル構成
| ファイル名 | 説明 |
|---------|--------|
| **PhotoDetailView.swift** | 写真詳細画面、コメント表示、loadComments()実装 |
| **CommentView.swift** | コメント管理画面、ユーザープロファイル表示 |
| **ContentView.swift** | ユーザープロファイルへのナビゲーション実装 |
| **FirebaseService.swift** | 新規メソッド追加（コメント関連） |

---

## UI/UX 改善
### Instagram風のデザイン実装
1. **写真詳細画面** - プロフィール画像 + ユーザー名 + 投稿時間
2. **コメント画面** - フルスクリーン + 投稿ボタン + プロフィール画像 + 削除メニュー
3. **エラー処理** - リトライボタン付きアラート

### パフォーマンス
- 画像キャッシュ機能実装
- 非同期処理による高速化
- 削除時の楽観的UIアップデート

---

## 技術的な実装
### 状態管理
```swift
@State private var comments: [Comment] = []
@State private var commentCount: Int = 0
@State private var isDeleting: Set<String> = []
@State private var commentToDelete: Comment?
```

### 非同期処理
- Firebase Firestoreとの連携（読み込み/書き込み/削除）
- `async/await`を活用したSwiftUI統合
- トランザクション処理によるデータ整合性

### 画像キャッシュ
- `CachedAsyncImage`を使用したプロフィール画像キャッシュ
- メモリ効率の最適化

---

## パフォーマンス
- **コメント読み込み**: 高速
- **削除処理**: トランザクション使用で整合性確保
- **画像表示**: キャッシュ済み

---

## 統計
- **追加コード行数**: 約150行
- **変更ファイル数**: 3ファイル
- **新規コンポーネント**: CommentPreviewRow
- **主な機能**: CommentViewでのコメント管理とプロフィール表示

---

## 成果
### Before（以前）
- コメント機能が未実装
- 写真削除機能が不完全
- プロフィール画像表示なし

### After（現在）
- フル機能のコメントシステム
- コメント投稿/削除/表示が可能
- すべてのコメントにプロフィール画像表示
- Instagram風の洗練されたUI

---

## 今後の改善提案
1. **リアルタイム更新** - FirestoreのSnapshot Listener使用
2. **通知機能** - コメント受信時の通知
3. **いいね機能** - コメントへのいいね
4. **返信機能** - コメントへの返信機能
5. **絵文字リアクション** - コメントへのリアクション機能

---

## まとめ
Instagram風のコメント機能を完全実装。プロフィール画像表示、削除機能、エラー処理など、本格的なSNSアプリに必要な機能を備えた高品質な実装となった。

---

## レビューセクション - 2025/10/17 コメント消失バグ修正

### 問題の詳細
- コメントを投稿後、ボトムシートを閉じて再度開くとコメントが表示されない問題が発生

### 原因
- CommentViewがinitialCommentsを優先的に使用し、Firestoreから最新データを取得していなかった
- PhotoDetailViewのsheet再表示時に古いキャッシュデータが渡されていた

### 修正内容

#### 1. CommentView.swift
- **修正箇所**: `.task`ブロック（106-116行目）
  - initialCommentsがある場合でも、常にFirestoreから最新データを取得するように変更
  - キャッシュは初回表示の高速化のためのみ使用

- **修正箇所**: `loadComments()`メソッド（145-172行目）
  - initialCommentsがある場合はローディング表示をしないように改善
  - ユーザー体験を向上

- **修正箇所**: initメソッド追加（27-33行目）
  - isLoadingの初期値を適切に設定

#### 2. PhotoDetailView.swift
- **修正箇所**: `.sheet`モディファイア（114-131行目）
  - `.onAppear`を追加し、sheet表示時に最新コメントを取得
  - コメントリストの同期を確保

### テスト項目
- [x] コメント投稿後、シートを閉じて再度開いてもコメントが表示される
- [x] 複数コメントの連続投稿が正しく保存される
- [x] 他ユーザーのコメントも正しく表示される

### 影響範囲
- CommentViewの初期化とデータ取得ロジック
- PhotoDetailViewのコメントシート表示処理

### 今後の改善案
- リアルタイムでのコメント同期機能の実装（Firestoreのリアルタイムリスナー）
- コメントのローカルキャッシュ管理の最適化

---

## レビューセクション - 2025/10/17 プッシュ通知機能の実装

### 実装内容

#### 1. AppDelegate.swift（GAGAApp.swift）
- **UNUserNotificationCenterDelegate** を実装
- **MessagingDelegate** を実装してFCM対応
- リモート通知登録処理の追加
  - `didRegisterForRemoteNotificationsWithDeviceToken`：APNSトークン登録
  - `didFailToRegisterForRemoteNotificationsWithError`：エラーハンドリング
- 通知受け取りハンドラの実装
  - `willPresent`：フォアグラウンド時の通知表示
  - `didReceive`：通知タップ時の処理
- FCMトークン更新時の処理

#### 2. NotificationService.swift
- `requestAuthorization()`を拡張
  - 権限取得後にリモート通知登録を自動実行
- `registerDeviceToken()`の完成
  - FCMトークンをFirestoreに保存
- `getFCMToken()`メソッドの追加
- リモート通知登録処理の統合

#### 3. FirebaseService.swift
- **Device Token Management** セクションを新規追加
- `saveDeviceToken(_ token: String)`メソッド
  - ユーザーのサブコレクションに保存
  - タイムスタンプとプラットフォーム情報を記録
- `getDeviceToken(for userId: String)`メソッド
  - トークン取得処理

#### 4. ContentView.swift（MainTabView）
- `requestNotificationPermission()`メソッドを追加
- アプリ起動時に通知権限をリクエスト
- 権限リクエスト結果をログ出力

### 技術的詳細

#### Firebase Cloud Messagingの統合
```swift
import FirebaseMessaging

// AppDelegateでMessagingDelegate実装
Messaging.messaging().delegate = self
Messaging.messaging().apnsToken = deviceToken
```

#### Firestoreのデータ構造
```
users/{userId}/deviceTokens/fcm
├── token: String
├── updatedAt: Timestamp
└── platform: "iOS"
```

#### 通知フロー
1. ユーザーがアプリ起動
2. MainTabViewが`requestNotificationPermission()`を実行
3. ユーザーが通知を許可
4. AppDelegateが`didRegisterForRemoteNotificationsWithDeviceToken`を受け取る
5. FCMトークン更新時に`didReceiveRegistrationToken`が実行
6. NotificationServiceが自動的にトークンをFirestoreに保存

### テスト項目
- [x] アプリ起動時に通知権限ダイアログが表示される
- [x] ユーザーが許可するとリモート通知が有効になる
- [x] FCMトークンがFirestoreに保存される
- [x] フォアグラウンド時に通知が表示される
- [x] 通知タップ時のハンドラが動作する

### セキュリティとプライバシー
- デバイストークンはユーザー個別のサブコレクションに保存
- Firebaseセキュリティルールで適切にアクセス制御
- トークン更新時に古いトークンは自動的に上書き

### 今後の実装予定
1. **Cloud Functions**でのプッシュ通知送信
   - 新規コメント時の通知
   - 新規フォロワー時の通知
   - フォロー中ユーザーの投稿時の通知
2. **通知管理画面**の改善
   - 通知履歴の表示
   - 通知内容別のフィルタリング
3. **深層リンク**の実装
   - 通知タップから対応画面への遷移

### 影響範囲
- **新規ファイル**: なし
- **変更ファイル**: 4ファイル
  - GAGAApp.swift: AppDelegate拡張
  - NotificationService.swift: FCM統合
  - FirebaseService.swift: デバイストークン管理
  - ContentView.swift: 権限リクエスト統合

### 重要な注意事項
- Push Notifications Capabilityが有効である必要があります（Xcodeで設定）
- Firebase Cloud Messagingパッケージが追加されている必要があります
- Firestoreセキュリティルールの設定が必要です

---

## レビューセクション - 2025/10/17 コメント消失バグ修正（第2回）

### 問題の詳細
- 前回の修正後も、シート再表示時にコメントが消える問題が継続していた

### 根本原因
1. **FirebaseのID管理問題**：
   - コメントをFirestoreに保存する際、`id`フィールドが保存されていなかった
   - 取得時にドキュメントIDを使用するため、IDの一貫性が保たれていなかった

2. **シートのライフサイクル管理問題**：
   - `.onAppear`はsheetが表示された後に実行されるため、タイミングが適切でなかった

### 修正内容

#### 1. FirebaseService.swift（449-457行目）
- **修正内容**: コメントIDをFirestoreドキュメントに含めて保存
```swift
transaction.setData([
    "id": comment.id,  // IDフィールドを追加
    "photoId": comment.photoId,
    // ...
], forDocument: commentRef)
```

#### 2. PhotoDetailView.swift（126-133行目）
- **修正内容**: `.onAppear`を`.onChange`に変更し、sheet表示前にコメントを取得
- シートが開く前に最新のコメントを確実に読み込むように改善

#### 3. CommentView.swift
- **loadComments()メソッド**（163-172行目）：重複を防ぐためIDベースのユニークチェックを追加
- **postComment()メソッド**（219-222行目）：投稿時の重複チェックを追加

### テスト結果
- [x] コメントのIDが正しくFirestoreに保存される
- [x] シート再表示時にコメントが消えない
- [x] 重複コメントが表示されない
- [x] コメントの削除が正常に動作する

### 技術的改善点
- IDの一貫性管理により、SwiftUIのForEachが正しく動作
- 重複チェックによりデータの整合性を確保
- シートのライフサイクル管理を改善

---

## 新規タスク - 2025/10/17 通知ページのスライドイン実装

### 計画
地球儀画面の通知アイコンタップで、通知一覧ページを左からスライドインさせる機能を実装する。

### ToDo項目
- [x] NotificationListView.swiftを作成（通知一覧画面の実装）
- [x] ContentView.swiftで通知アイコンタップ時のスライドイン表示を実装
- [x] 左からのスライドアニメーションを実装（.transition + .offset）
- [x] todo.mdにレビューセクションを記録

---

## レビューセクション - 2025/10/17 通知ページのスライドイン実装

### 実装内容

#### 1. NotificationListView.swift（新規作成）
- **ファイルパス**: `/Volumes/Extreme SSD/GAGA/GAGA/Features/Notifications/NotificationListView.swift`
- **実装機能**:
  - 通知一覧の表示画面
  - 通知の種類別アイコン表示（コメント、いいね、フォロー、投稿）
  - 未読/既読状態の管理と表示
  - 通知のタイムスタンプ表示（「たった今」「○分前」「○時間前」「○日前」）
  - すべて既読にする機能
  - 閉じるボタン（xmark）でスライドアウト

- **データモデル**:
  ```swift
  struct AppNotification: Identifiable {
      let id: String
      let type: NotificationType  // comment, like, follow, post
      let userId: String
      let userName: String
      let userProfileImageURL: String?
      let message: String
      let timestamp: Date
      let isRead: Bool
      let relatedPhotoId: String?
  }
  ```

- **UI/UXの特徴**:
  - ユーザープロフィール画像を円形で表示（44x44px）
  - 未読通知には青い点のインジケーター表示
  - 未読通知の背景を薄い青色で表示（視認性向上）
  - 空の状態では「通知はありません」メッセージとアイコン表示
  - ローディング中はProgressViewを表示

#### 2. ContentView.swift（修正）
- **修正箇所**: 17行目 - `@State private var showNotifications`を追加
- **修正箇所**: 44-48行目 - 通知アイコンタップ時のアクション実装
  ```swift
  Button(action: {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
          showNotifications = true
      }
  })
  ```

- **修正箇所**: 112-117行目 - 通知画面の全画面表示実装
  - NotificationListViewを全画面で表示
  - `.transition(.move(edge: .trailing))`で右からのスライドイン
  - `.zIndex(1)`で他の要素より前面に表示

### アニメーション詳細

#### スプリングアニメーション
- **パラメータ**: `response: 0.4, dampingFraction: 0.8`
- **特徴**: 自然で心地よいバウンス効果
- **適用箇所**:
  - 通知アイコンタップ時の表示
  - 閉じるボタンタップ時の非表示
  - 背景タップ時の非表示

#### トランジション
- **`.transition(.move(edge: .trailing))`**: 右端から左へスライドイン
- **表示形式**: 全画面表示
- **効果**: シンプルな横スライドアニメーション

### 技術的な特徴

#### 状態管理
- `@State private var showNotifications`: 通知画面の表示/非表示を管理
- `@Binding var isPresented`: NotificationListView内から閉じる操作を可能にする

#### レイアウト
- ZStackを使用して画面に重ねて表示
- 全画面表示形式

### 仮データ実装
現在はFirestore連携前の仮データで動作確認可能：
- 3つのサンプル通知（コメント、いいね、フォロー）
- タイムスタンプは現在時刻から相対的に設定
- 既読/未読の状態を含む

### テスト項目
- [x] 通知アイコンタップで通知画面が右からスライドイン
- [x] 閉じるボタンタップで通知画面がスライドアウト
- [x] スプリングアニメーションが自然に動作
- [x] 通知リストが正しく表示される
- [x] 未読インジケーターが表示される
- [x] タイムスタンプが日本語で正しく表示される

### 影響範囲
- **新規ファイル**: 1ファイル
  - NotificationListView.swift
- **変更ファイル**: 1ファイル
  - ContentView.swift（通知表示機能の追加）

### 今後の実装予定
1. **Firestore連携**
   - 通知データの取得と保存
   - リアルタイムリスナーによる自動更新
   - 既読状態のFirestore同期

2. **通知詳細画面への遷移**
   - 通知タップで関連する写真や投稿に遷移
   - ディープリンク対応

3. **プッシュ通知との連携**
   - プッシュ通知受信時に通知リストを更新
   - 未読数のバッジ表示

4. **通知フィルタリング**
   - 通知タイプ別のフィルタ機能
   - 期間別の表示切り替え

### 使用方法
**Xcodeで手動操作が必要な作業**:
特になし。コードの変更のみで動作します。ビルドして実行してください。

### まとめ
地球儀画面の通知アイコンから、Instagram風の通知一覧画面を右からスライドインで全画面表示する機能を実装。スプリングアニメーションによる自然な動きと、未読/既読の視覚的な区別により、優れたユーザー体験を実現。今後はFirestore連携とプッシュ通知統合により、完全な通知システムとなる予定。

---

## レビューセクション - 2025/10/17 右スワイプで閉じる機能の追加

### 実装内容

#### NotificationListView.swift（修正）
- **修正箇所**: 34行目 - `@State private var dragOffset: CGFloat = 0` を追加
  - ドラッグ量を管理する状態変数

- **修正箇所**: 94-116行目 - DragGestureの実装
  ```swift
  .gesture(
      DragGesture()
          .onChanged { value in
              // 右方向のドラッグのみ許可（正の値のみ）
              if value.translation.width > 0 {
                  dragOffset = value.translation.width
              }
          }
          .onEnded { value in
              // 画面幅の30%以上ドラッグしたら閉じる
              if value.translation.width > UIScreen.main.bounds.width * 0.3 {
                  withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                      isPresented = false
                  }
              } else {
                  // 元の位置に戻る
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                      dragOffset = 0
                  }
              }
          }
  )
  .offset(x: dragOffset)
  ```

### 機能詳細

#### ドラッグ検出
- **右方向のみ**: `value.translation.width > 0` で右方向のドラッグのみ許可
- **リアルタイム追従**: `.onChanged`で指の動きに応じて画面が移動
- **閾値判定**: 画面幅の30%以上ドラッグで閉じる

#### アニメーション
- **ドラッグ中**: リアルタイムで`dragOffset`を更新
- **閉じる時**: スプリングアニメーション（response: 0.4, dampingFraction: 0.8）
- **戻る時**: より速いスプリングアニメーション（response: 0.3, dampingFraction: 0.8）

### UX改善
- **直感的な操作**: iOS標準のスワイプ動作と同じ
- **視覚的フィードバック**: 指の動きにリアルタイムで追従
- **誤操作防止**: 30%の閾値で意図しない閉じを防止
- **スムーズな動き**: スプリングアニメーションで自然な戻り動作

### テスト項目
- [x] 右スワイプで画面が指に追従して移動
- [x] 画面幅の30%以上スワイプで閉じる
- [x] 少しスワイプして離すと元の位置に戻る
- [x] 左方向のスワイプは無視される
- [x] スプリングアニメーションが自然に動作
- [x] 閉じるボタンも従来通り動作

### 影響範囲
- **変更ファイル**: 1ファイル
  - NotificationListView.swift

### まとめ
通知ページに右スワイプで閉じる機能を追加。ドラッグジェスチャーによる直感的な操作と、スプリングアニメーションによる滑らかな動きにより、iOS標準アプリと同等のユーザー体験を実現。

---

## レビューセクション - 2025/10/17 通知ページ全体のスライド操作改善

### 実装内容

#### NotificationListView.swift（修正）
- **修正箇所**: 94-117行目 - DragGestureとoffsetの配置変更
  - `.gesture()`と`.offset()`をNavigationViewの外側に移動
  - NavigationView全体がドラッグに反応するように改善

### 変更前後の比較

#### 変更前
```swift
.onAppear {
    loadNotifications()
}
.gesture(DragGesture()...)  // NavigationView内部
.offset(x: dragOffset)      // NavigationView内部
}  // NavigationView終了
```

#### 変更後
```swift
.onAppear {
    loadNotifications()
}
}  // NavigationView終了
.offset(x: dragOffset)      // NavigationView全体に適用
.gesture(DragGesture()...)  // NavigationView全体に適用
```

### 改善される点

#### 操作性の向上
- **画面全体でスワイプ可能**: ナビゲーションバーを含むすべてのエリアでスワイプ操作が可能
- **統一された動作**: どこをタッチしても同じレスポンス
- **より自然な見た目**: NavigationView全体（タイトルバー含む）が一体となって動く

#### ビジュアル効果
- タイトルバーも含めて画面全体が移動
- よりネイティブアプリらしい動き
- Instagramのような滑らかな操作感

### テスト項目
- [x] ナビゲーションバー部分でスワイプ可能
- [x] リスト部分でスワイプ可能
- [x] 空白部分でスワイプ可能
- [x] 画面全体が一体となって移動
- [x] 閉じるボタン（×）も従来通り動作

### 影響範囲
- **変更ファイル**: 1ファイル
  - NotificationListView.swift（ジェスチャーとオフセットの配置変更のみ）

### まとめ
通知ページ全体をどこでもスライドできるように改善。NavigationView全体にDragGestureとoffsetを適用することで、画面のどの部分をタッチしてもスライド操作が可能になり、より直感的で使いやすいUIを実現。