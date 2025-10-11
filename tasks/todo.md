# ユーザー名システムの実装

## 📋 実装計画

### 目的
ユーザー情報を以下の2つのフィールドで管理する:
- **名前（displayName）**: 重複可能、任意の言語OK、表示用
- **ユーザーネーム（username）**: 重複不可、英数字と記号（._-）のみ、一意識別子（@usernameスタイル）

### 設計方針
1. `username`は一意性を保証（Firestoreで重複チェック）
2. `username`は3-20文字、英数字と記号（._-）のみ
3. `displayName`は任意の言語で自由に設定可能
4. 新規登録時に両方を設定
5. プロフィール編集で両方とも変更可能

---

## タスクリスト

### 1. Userモデルの更新
- [x] `User.swift`に`username: String`フィールドを追加
- [x] initメソッドにusernameパラメータを追加

### 2. FirebaseServiceの拡張
- [x] `checkUsernameAvailability(username: String) -> Bool`メソッドを追加
- [x] `reserveUsername(username: String, userId: String)`メソッドを追加
- [x] `updateUsername(oldUsername: String, newUsername: String, userId: String)`メソッドを追加
- [x] ユーザー検索を拡張（displayNameとusername両方で検索）

### 3. 新規登録画面（LoginView.swift）の修正
- [x] usernameフィールドを追加
- [x] usernameのバリデーション追加（英数字と._-のみ、3-20文字）
- [x] リアルタイム重複チェック機能を実装
- [x] サインアップ処理にusername追加

### 4. プロフィール編集画面（ProfileEditView.swift）の修正
- [x] usernameフィールドを追加
- [x] usernameのバリデーションと重複チェック
- [x] 保存処理でusernameを更新

### 5. AuthManagerの更新
- [x] signUpメソッドにusernameパラメータを追加
- [x] Apple Sign In時のusername自動生成ロジック追加

### 6. 表示系の更新
- [x] UserSearchViewで@username表示
- [x] ProfileViewで@username表示
- [x] PhotoDetailViewで@username表示

---

## 実装メモ

### Firestoreデータ構造

#### usernamesコレクション（一意性保証用）
```
/usernames/{username}
  - userId: String
  - createdAt: Timestamp
```

#### usersコレクション
```
/users/{userId}
  - displayName: String (任意の言語OK)
  - username: String (英数字と._-のみ、一意)
  - email: String?
  - ...
```

### Usernameバリデーションルール
- 3-20文字
- 英小文字、数字、ピリオド(.)、アンダースコア(_)、ハイフン(-)のみ
- 連続するピリオド不可
- 先頭・末尾がピリオド不可
- 正規表現: `^[a-z0-9][a-z0-9._-]{1,18}[a-z0-9]$`

---

## レビュー

### 実装完了の概要

ユーザー名システムを完全に実装しました。これにより、ユーザーは以下の2つの識別子を持つようになりました:

1. **名前（displayName）**: 重複可能、任意の言語OK、表示用
2. **ユーザーネーム（username）**: 重複不可、英数字と記号（._-）のみ、一意識別子（@usernameスタイル）

---

### 変更・追加したファイル

#### 1. GAGA/Models/User.swift
**変更内容**:
- `username: String`フィールドを追加（13行目）
- `init`メソッドに`username`パラメータを追加（22行目）

#### 2. GAGA/Services/FirebaseService.swift
**変更内容**:
- `checkUsernameAvailability(_:)`メソッドを追加（40-44行目）
  - Firestoreの`usernames`コレクションで重複チェック
  - 小文字に正規化して検索
- `reserveUsername(_:userId:)`メソッドを追加（47-63行目）
  - ユーザーネームを予約してFirestoreに保存
  - 重複チェックを実施
- `updateUsername(oldUsername:newUsername:userId:)`メソッドを追加（66-89行目）
  - 古いユーザーネームを削除して新しいユーザーネームを予約
  - 重複チェックを実施
- `searchUsers(query:)`メソッドを拡張（92-131行目）
  - displayNameとusernameの両方で検索可能
  - @から始まるクエリに対応
  - 重複を除外してマージ

#### 3. GAGA/Features/Auth/LoginView.swift
**変更内容**:
- `username`、`isCheckingUsername`、`usernameError`の状態変数を追加（16、20-21行目）
- ユーザーネーム入力フィールドを追加（69-103行目）
  - リアルタイムバリデーション
  - 重複チェックのProgressView表示
  - チェックマークとエラーメッセージ表示
  - ヒントテキスト表示
- `validateUsername(_:)`メソッドを追加（218-260行目）
  - フォーマットバリデーション（正規表現）
  - 連続するピリオドのチェック
  - Firebase重複チェック
- `emailSignUp()`メソッドを更新（178-216行目）
  - usernameバリデーションを追加
  - `signUp`呼び出しにusernameを追加

#### 4. GAGA/Features/Auth/AuthManager.swift
**変更内容**:
- `checkAuthState()`メソッドを更新（45-56行目）
  - 新規ユーザー作成時に自動でusernameを生成（uidの最初の8文字）
  - ユーザーネームを予約
- `signInWithApple(_:)`メソッドを更新（110-130行目）
  - Apple Sign In時にdisplayNameとともにusernameを処理
- `signUp(email:password:displayName:username:)`メソッドを更新（140-167行目）
  - usernameパラメータを追加
  - ユーザーネーム予約処理を追加

#### 5. GAGA/Features/Profile/ProfileEditView.swift
**変更内容**:
- `username`、`isCheckingUsername`、`usernameError`、`originalUsername`の状態変数を追加（16、23-25行目）
- ユーザーネーム編集フィールドを追加（74-110行目）
  - リアルタイムバリデーション
  - 元のusernameと異なる場合のみチェック
  - チェックマークとエラーメッセージ表示
- 保存ボタンの無効化条件を更新（157行目）
  - usernameが空またはエラーがある場合は無効化
- `loadCurrentProfile()`メソッドを更新（188-200行目）
  - usernameを読み込み
  - originalUsernameを保存
- `saveProfile()`メソッドを更新（236-284行目）
  - usernameが変更された場合はFirebaseServiceで更新
  - ユーザー情報にusernameを含めて保存
- `validateUsername(_:)`メソッドを追加（286-334行目）
  - 元のusernameと同じ場合はスキップ
  - フォーマットバリデーション
  - 重複チェック

#### 6. GAGA/Features/Profile/ProfileView.swift
**変更内容**:
- displayNameの下に`@username`を表示（35-37行目）
- メールアドレスを小さく表示（39-43行目）

#### 7. GAGA/Features/Social/UserSearchView.swift
**変更内容**:
- 検索結果リストに`@username`を表示（69-71行目）
- UserDetailViewに`@username`を表示（138-140行目）

#### 8. GAGA/Features/Photo/PhotoDetailView.swift
**変更内容**:
- ユーザー情報に`@username`を表示（139-141行目）

---

### 主な機能

#### 1. ユーザーネームのバリデーション
```swift
// 正規表現パターン
let pattern = "^[a-z0-9][a-z0-9._-]{1,18}[a-z0-9]$"

// ルール:
// - 3-20文字
// - 英小文字、数字、ピリオド(.)、アンダースコア(_)、ハイフン(-)のみ
// - 連続するピリオド不可
// - 先頭・末尾は英数字のみ
```

#### 2. リアルタイム重複チェック
- ユーザーネーム入力時に自動でバリデーション
- Firestoreの`usernames`コレクションで重複チェック
- チェック中はProgressView表示
- 使用可能な場合はチェックマーク表示
- エラーがある場合はエラーメッセージ表示

#### 3. ユーザーネーム予約システム
Firestoreの`usernames`コレクションでユーザーネームを管理:
```
/usernames/{username}
  - userId: String
  - createdAt: Timestamp
```

#### 4. 検索機能の拡張
- displayNameとusernameの両方で検索可能
- `@username`形式での検索に対応
- 重複を除外してマージ

#### 5. Apple Sign In対応
- 初回ログイン時に自動でusernameを生成（uidの最初の8文字）
- ユーザーは後でプロフィール編集から変更可能

---

### テスト手順（Xcodeで手動テスト必要）

#### 1. 新規登録
1. LoginViewで「アカウントをお持ちでない方」をタップ
2. 表示名、ユーザーネーム、メールアドレス、パスワードを入力
3. ユーザーネームのバリデーションが動作することを確認
   - 無効な文字を入力するとエラーメッセージが表示される
   - 既存のユーザーネームを入力すると「既に使用されています」と表示される
   - 使用可能なユーザーネームを入力するとチェックマークが表示される
4. 新規登録ボタンをタップして登録完了

#### 2. プロフィール編集
1. ProfileViewで「プロフィールを編集」をタップ
2. ユーザーネームを変更
3. バリデーションと重複チェックが動作することを確認
4. 保存してプロフィールが更新されることを確認

#### 3. ユーザー検索
1. ユーザー検索タブを開く
2. 名前で検索してユーザーが表示されることを確認
3. @usernameで検索してユーザーが表示されることを確認
4. 検索結果に@usernameが表示されることを確認

#### 4. 表示確認
1. ProfileViewで@usernameが表示されることを確認
2. UserSearchViewのリストで@usernameが表示されることを確認
3. PhotoDetailViewで投稿者情報に@usernameが表示されることを確認

---

### 今後の改善点

#### 1. ユーザーネームの変更制限
- 現在は無制限に変更可能
- 変更回数制限（例: 30日に1回）を実装するとよい

#### 2. ユーザーネームの予約解除
- 現在は古いユーザーネームを即座に削除
- 一定期間保持してから削除するとよい（他のユーザーの即座の取得を防ぐ）

#### 3. プロフィール画像の対応
- 現在はデフォルトのアイコンのみ
- ユーザーがアップロードした画像を表示する対応が必要

#### 4. エラーハンドリングの強化
- ネットワークエラー時の適切な処理
- リトライ機能の実装

#### 5. Firestoreセキュリティルールの追加
- usernamesコレクションの書き込み制限
- ユーザー情報の読み取り制限

#### 6. パフォーマンス最適化
- ユーザーネームの検索インデックス最適化
- キャッシュ機能の実装

---

### Firestore セキュリティルール（推奨）

```javascript
// Firestoreセキュリティルールの例
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // usernamesコレクション
    match /usernames/{username} {
      // 認証済みユーザーのみ読み取り可能
      allow read: if request.auth != null;

      // 自分のユーザーIDでのみ作成・更新可能
      allow create: if request.auth != null
                    && request.resource.data.userId == request.auth.uid;

      // 自分のユーザーネームのみ削除可能
      allow delete: if request.auth != null
                    && resource.data.userId == request.auth.uid;
    }

    // usersコレクション
    match /users/{userId} {
      // 認証済みユーザーのみ読み取り可能
      allow read: if request.auth != null;

      // 自分のユーザー情報のみ作成・更新可能
      allow create, update: if request.auth != null
                            && request.auth.uid == userId;
    }
  }
}
```

---

### 完了！

ユーザー名システムの実装が完了しました。これにより、ユーザーは表示名（任意の言語、重複可能）とユーザーネーム（英数字と記号のみ、一意）の両方を持つようになりました。

**重要**: Xcodeでビルドとテストを実施してください。特に、既存のユーザーデータがある場合は、マイグレーション処理が必要になる可能性があります。

---

# Instagram風UI実装タスク

## 📋 実装計画

### 目的
PhotoDetailViewをInstagram風のUIに変更する

### デザイン要件
- ヘッダー: プロフィール画像（36x36）+ ユーザー名 + 3点メニュー
- 写真: エッジtoエッジ表示（padding/cornerRadius削除）
- アクションボタン: いいね、コメント、シェア、保存
- いいね数表示
- キャプション: ユーザー名（太字） + テキスト
- 位置情報: 国情報（小さいフォント）
- 投稿日時: 相対時間表示

---

## タスクリスト

- [x] PhotoDetailViewのbodyをVStackベースのレイアウトに変更
- [x] headerView（プロフィール画像 + ユーザー名 + メニュー）を作成
- [x] photoViewから余白と角丸を削除（エッジtoエッジ表示）
- [x] actionButtonsView（いいね・コメント・シェア・保存ボタン）を作成
- [x] captionView（ユーザー名 + キャプション）をInstagram風に変更
- [x] locationView（国情報）を簡略化
- [x] timestampView（投稿日時）を相対時間表示に変更
- [x] ナビゲーションバーを非表示に変更
- [x] 削除確認アラートの配置調整（headerの3点メニューに統合）
- [x] formatRelativeDateメソッドを追加（○時間前形式）

---

## レイアウト構造

```
VStack(spacing: 0) {
  - headerView (padding: 12)
  - photoView (padding削除, cornerRadius削除)
  - VStack(alignment: .leading, spacing: 8) {
      - actionButtonsView
      - likeCountView
      - captionView
      - locationView
      - timestampView
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
}
```

---

## レビュー

### 実装完了の概要

PhotoDetailViewをInstagram風のUIに完全に変更しました。これにより、写真詳細画面がモダンでクリーンなInstagram風のデザインになりました。

---

### 変更・追加したファイル

#### 1. GAGA/Features/Photo/PhotoDetailView.swift

**変更内容**:

1. **bodyの再構築（21-51行目）**
   - ScrollViewの中にVStack(spacing: 0)を配置
   - headerView、photoView、アクションボタンエリアを順に配置
   - ナビゲーションバーを非表示（`.navigationBarHidden(true)`）
   - 削除アラートはそのまま保持

2. **headerViewの作成（55-99行目）**
   - 36x36のプロフィール画像（Circle）
   - displayNameとusernameを縦並びで表示
   - 3点メニューボタン（ellipsisアイコンを90度回転）
   - 自分の投稿の場合のみメニューボタンを表示
   - padding: 12（水平・垂直）

3. **photoViewの変更（101-128行目）**
   - `.padding(.horizontal)`を削除
   - `.cornerRadius(12)`を削除
   - エッジtoエッジ表示に変更
   - `.aspectRatio(contentMode: .fit)`でアスペクト比を維持
   - ローディング時とエラー時の背景を追加

4. **actionButtonsViewの作成（130-172行目）**
   - いいねボタン（heart）
   - コメントボタン（bubble.left）
   - シェアボタン（paperplane）
   - 保存ボタン（bookmark、右端）
   - 各ボタンは24pxのアイコン、黒色
   - TODO: 各機能は未実装（将来の拡張用）

5. **captionViewの作成（174-194行目）**
   - usernameを太字で表示
   - captionを通常フォントで表示
   - HStackで横並びに配置
   - フォントサイズ: 14px

6. **locationViewの作成（196-208行目）**
   - mappinアイコン + 国名を表示
   - フォントサイズ: 12px
   - 国旗は削除（シンプル化）

7. **timestampViewの作成（210-215行目）**
   - 相対時間表示（○時間前）
   - フォントサイズ: 12px
   - セカンダリカラー

8. **formatRelativeDateメソッドの追加（293-311行目）**
   - 年、月、日、時間、分単位で相対時間を計算
   - 日本語形式で表示（"○時間前"、"○日前"など）
   - たった今の場合は"たった今"と表示

---

### 主な機能

#### 1. Instagram風のヘッダー
- プロフィール画像とユーザー名を左に配置
- 3点メニューを右に配置（自分の投稿の場合のみ）
- コンパクトなデザイン（36x36のアイコン）

#### 2. エッジtoエッジの写真表示
- 画面幅いっぱいに写真を表示
- 角丸なし、paddingなし
- 3:4のアスペクト比を維持

#### 3. アクションボタン
- Instagram風のアイコン配置
- いいね、コメント、シェアを左に並べる
- 保存ボタンを右端に配置
- 将来の機能拡張に対応（TODO付き）

#### 4. キャプション表示
- ユーザー名とキャプションを一行に表示
- ユーザー名は太字、キャプションは通常フォント
- Instagramと同じスタイル

#### 5. 位置情報の簡略化
- mappinアイコン + 国名のみ
- 小さいフォントでコンパクトに表示

#### 6. 相対時間表示
- "○時間前"、"○日前"、"○ヶ月前"形式
- 日本語対応
- より直感的な時間表示

---

### UI変更の詳細

#### Before（旧UI）
```
NavigationView {
  ScrollView {
    - 写真（padding + cornerRadius）
    - 国情報（大きい）
    - Divider
    - ユーザー情報（NavigationLink）
    - Divider
    - キャプション（見出し付き）
    - 位置情報（緯度経度）
  }
}
.navigationTitle("写真の詳細")
.toolbar { 削除ボタン }
```

#### After（新UI）
```
VStack(spacing: 0) {
  - headerView（プロフィール + メニュー）
  - photoView（エッジtoエッジ）
  - VStack {
      - actionButtonsView（いいね・コメント・シェア・保存）
      - captionView（username + キャプション）
      - locationView（国名のみ）
      - timestampView（○時間前）
    }
}
.navigationBarHidden(true)
```

---

### 削除された機能

以下の機能は新UIに合わせて削除されました:

1. **NavigationTitle** - ナビゲーションバーを非表示にしたため削除
2. **Toolbarの削除ボタン** - headerの3点メニューに統合
3. **Divider** - Instagram風のクリーンなデザインに不要
4. **countryInfoViewの大きい表示** - locationViewに簡略化
5. **userInfoViewのNavigationLink** - ヘッダーに統合（NavigationLinkは削除）
6. **緯度経度の詳細表示** - シンプル化のため削除

---

### 今後の改善点

#### 1. アクションボタンの実装
現在はTODOとして残されている機能:
- いいね機能（Firestoreでlikeを管理）
- コメント機能（コメントビューの実装）
- シェア機能（UIActivityViewControllerの使用）
- 保存機能（ローカル保存またはブックマーク）

#### 2. いいね数の表示
- `photo.likeCount`は既にモデルに存在
- likeCountViewを追加して「○人がいいねしました」を表示

#### 3. キャプションの展開機能
- 長いキャプションは「...more」で省略
- タップで全文表示

#### 4. プロフィール画像のタップ機能
- headerのプロフィール画像またはユーザー名をタップしてUserDetailViewに遷移

#### 5. ダブルタップでいいね
- 写真をダブルタップしていいねをつける機能

#### 6. スワイプでの画面遷移
- 左スワイプで前の画面に戻る

---

### テスト手順（Xcodeで手動テスト必要）

#### 1. 写真詳細画面の表示
1. 地球儀から写真をタップして詳細画面を開く
2. ヘッダー、写真、アクションボタン、キャプション、位置情報、投稿日時が表示されることを確認

#### 2. ヘッダーの確認
1. プロフィール画像が36x36で表示されることを確認
2. displayNameとusernameが表示されることを確認
3. 自分の投稿の場合、3点メニューボタンが表示されることを確認

#### 3. 写真の表示
1. 写真が画面幅いっぱいに表示されることを確認
2. 角丸がないことを確認
3. 3:4のアスペクト比が維持されることを確認

#### 4. アクションボタンの表示
1. いいね、コメント、シェアボタンが左に並んでいることを確認
2. 保存ボタンが右端に表示されることを確認
3. 各ボタンをタップしても何も起こらないことを確認（TODO）

#### 5. キャプションの表示
1. usernameが太字で表示されることを確認
2. キャプションが通常フォントで表示されることを確認
3. キャプションがない場合は空文字が表示されることを確認

#### 6. 位置情報と投稿日時
1. mappinアイコン + 国名が小さいフォントで表示されることを確認
2. 相対時間（○時間前）が表示されることを確認

#### 7. 削除機能
1. 自分の投稿の3点メニューをタップ
2. 削除確認アラートが表示されることを確認
3. 削除ボタンをタップして写真が削除されることを確認
4. 前の画面に戻り、地球儀から写真が消えることを確認

---

### 完了！

PhotoDetailViewのInstagram風UI実装が完了しました。これにより、写真詳細画面がモダンでクリーンなデザインになり、ユーザー体験が向上しました。

**重要**: Xcodeでビルドとテストを実施してください。特に、アクションボタンの機能は未実装のため、将来の拡張として実装する必要があります。

---

# 画像キャッシュ最適化（レベル1.5）

## 📋 実装計画

### 目的
画像のダウンロードとキャッシュを最適化し、パフォーマンスとユーザー体験を向上させる

### 実装方針
- NetworkManagerでURLSessionをカスタマイズ（メモリ50MB、ディスク200MB）
- PhotoCacheと統合してメモリ→ディスク→ネットワークの順でチェック
- GlobeViewのテクスチャ生成でキャッシュを活用
- PhotoDetailViewでCachedAsyncImageを使用

---

## タスクリスト

- [x] NetworkManager.swiftを作成
- [x] CachedAsyncImage.swiftを作成
- [x] GlobeMaterial.swiftでNetworkManagerを使用
- [x] GlobeView.swiftでNetworkManagerを使用
- [x] PhotoDetailView.swiftでCachedAsyncImageを使用

---

## レビュー

### 実装完了の概要

画像キャッシュ最適化（レベル1.5）を実装しました。これにより、画像のダウンロードが大幅に効率化され、パフォーマンスとユーザー体験が向上しました。

---

### 変更・追加したファイル

#### 1. GAGA/Services/NetworkManager.swift（新規作成）

**主な機能**:
- **URLSessionのカスタマイズ**
  - メモリキャッシュ: 50MB
  - ディスクキャッシュ: 200MB
  - キャッシュポリシー: `.returnCacheDataElseLoad`

- **downloadImageメソッド**
  - メモリキャッシュをチェック（PhotoCache）
  - ディスクキャッシュをチェック（PhotoCache）
  - ネットワークからダウンロード
  - ダウンロード後にキャッシュに保存

- **NetworkError列挙型**
  - invalidURL: 無効なURL
  - invalidResponse: サーバーからの応答が無効
  - invalidImageData: 画像データが無効

- **String拡張**
  - `safeCacheKey`: URLを安全なキャッシュキーに変換
  - `lastPathComponent`: ログ用にファイル名を取得

**キャッシュ戦略**:
```
1. メモリキャッシュをチェック（高速）
   ↓ なし
2. ディスクキャッシュをチェック（中速）
   ↓ なし
3. ネットワークからダウンロード（低速）
   ↓
4. メモリとディスクに保存
```

#### 2. GAGA/Core/UI/CachedAsyncImage.swift（新規作成）

**主な機能**:
- **NetworkManagerを使用したAsyncImageラッパー**
  - 既存のAsyncImageと同じインターフェース
  - AsyncImagePhaseを使用（empty, success, failure）
  - Task管理とキャンセル対応

- **Convenience Initializer**
  - デフォルトの表示（ProgressView → Image → Error Icon）

- **AsyncImagePhase Extension**
  - `image`プロパティでImageを簡単に取得

**使用例**:
```swift
CachedAsyncImage(url: photo.imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure:
        Image(systemName: "photo")
    }
}
```

#### 3. GAGA/Core/Globe/GlobeMaterial.swift（変更）

**変更箇所**: `createPhotoAtlas`メソッド（55-59行目）

**変更前**:
```swift
guard let imageURL = URL(string: photo.imageURL),
      let (data, _) = try? await URLSession.shared.data(from: imageURL),
      let image = UIImage(data: data) else {
```

**変更後**:
```swift
guard let image = try? await NetworkManager.shared.downloadImage(from: photo.imageURL) else {
```

**効果**:
- 地球儀のテクスチャ生成が高速化
- 複数の写真を同時にダウンロードする際もキャッシュが効く

#### 4. GAGA/Core/Globe/GlobeView.swift（変更）

**変更箇所**: `updateTextureIncrementally`メソッド（288-292行目）

**変更前**:
```swift
guard let imageURL = URL(string: photo.imageURL),
      let (data, _) = try? await URLSession.shared.data(from: imageURL),
      let image = UIImage(data: data) else {
```

**変更後**:
```swift
guard let image = try? await NetworkManager.shared.downloadImage(from: photo.imageURL) else {
```

**効果**:
- 差分更新時のダウンロードも高速化
- 写真追加時の地球儀更新がスムーズ

#### 5. GAGA/Features/Photo/PhotoDetailView.swift（変更）

**変更箇所**: `photoView`プロパティ（110-137行目）

**変更前**:
```swift
AsyncImage(url: URL(string: photo.imageURL)) { phase in
```

**変更後**:
```swift
CachedAsyncImage(url: photo.imageURL) { phase in
```

**効果**:
- 写真詳細画面の読み込みが高速化
- 一度見た写真は即座に表示

---

### キャッシュ戦略の詳細

#### メモリキャッシュ（NSCache）
- **容量**: 50MB（約50-100枚の写真）
- **速度**: ミリ秒レベル
- **寿命**: アプリ起動中のみ
- **管理**: PhotoCache.shared

#### ディスクキャッシュ（FileManager）
- **容量**: 200MB（約200-400枚の写真）
- **速度**: 数十ミリ秒
- **寿命**: アプリ削除まで永続
- **管理**: PhotoCache.shared

#### URLCache（URLSession）
- **容量**: メモリ50MB、ディスク200MB
- **速度**: 中速
- **寿命**: システム管理
- **管理**: NetworkManager.session

---

### パフォーマンス向上の見込み

#### 地球儀のテクスチャ生成
- **初回**: 変更なし（ダウンロード必要）
- **2回目以降**:
  - メモリキャッシュヒット時: **95%以上高速化**
  - ディスクキャッシュヒット時: **80-90%高速化**

#### PhotoDetailView
- **初回**: 変更なし
- **2回目以降**: **即座に表示**（体感的に一瞬）

#### データ通信量
- **初回**: 変更なし
- **2回目以降**: **0バイト**（完全にキャッシュから読み込み）

---

### ログ出力

実装により、以下のログが出力されます:

```
✅ Cache hit (memory): photo_12345.jpg
✅ Cache hit (disk): photo_67890.jpg
📥 Downloading: photo_abcde.jpg
💾 Cached: photo_abcde.jpg
```

これにより、キャッシュの動作状況を確認できます。

---

### 今後の改善点

#### 1. キャッシュクリア機能
現在は手動でクリアする必要があります。将来的に追加すべき機能:
- 設定画面に「キャッシュをクリア」ボタンを追加
- アプリ起動時に古いキャッシュを自動削除（7日以上など）

```swift
// 設定画面に追加する例
Button("キャッシュをクリア") {
    PhotoCache.shared.clearCache()
    // URLCacheもクリア
    URLCache.shared.removeAllCachedResponses()
}
```

#### 2. プリフェッチング（レベル2への拡張）
現在は表示時にダウンロードしています。将来的に:
- ユーザーがスクロールする前に先読み
- 地球儀の回転方向を予測して先読み

#### 3. サムネイル優先読み込み
現在は`imageURL`を直接使用しています。将来的に:
- まず`thumbnailURL`を表示（軽量）
- その後`imageURL`をダウンロード（高画質）

#### 4. キャッシュサイズの動的調整
現在は固定値（50MB、200MB）です。将来的に:
- デバイスの空き容量に応じて調整
- ユーザーが設定で変更可能

#### 5. オフライン対応の強化
現在はネットワークエラー時にエラー表示されます。将来的に:
- キャッシュがある場合は古いデータでも表示
- オフラインインジケーターを表示

---

### テスト手順（Xcodeで手動テスト必要）

#### 1. 初回ダウンロードのテスト
1. アプリを起動（キャッシュなし）
2. 地球儀で写真がある国をタップ
3. コンソールに「📥 Downloading」が表示されることを確認
4. 写真が表示されることを確認
5. コンソールに「💾 Cached」が表示されることを確認

#### 2. メモリキャッシュのテスト
1. 写真詳細画面を開く
2. 戻るボタンで戻る
3. もう一度同じ写真を開く
4. コンソールに「✅ Cache hit (memory)」が表示されることを確認
5. 写真が即座に表示されることを確認

#### 3. ディスクキャッシュのテスト
1. アプリを終了
2. アプリを再起動
3. 写真詳細画面を開く
4. コンソールに「✅ Cache hit (disk)」が表示されることを確認
5. 写真が高速に表示されることを確認

#### 4. 地球儀のテクスチャ生成のテスト
1. 複数の国に写真を投稿
2. 地球儀を回転させる
3. コンソールでキャッシュヒット率を確認
4. テクスチャの更新が高速になることを確認

#### 5. エラーハンドリングのテスト
1. ネットワークをオフにする
2. キャッシュされていない写真を開く
3. エラーアイコンが表示されることを確認
4. ネットワークをオンにする
5. 再度開くと正常に表示されることを確認

---

### 完了！

画像キャッシュ最適化（レベル1.5）の実装が完了しました。これにより、画像のダウンロードが大幅に効率化され、パフォーマンスとユーザー体験が向上しました。

**重要**: Xcodeでビルドとテストを実施してください。特に、キャッシュの動作状況をコンソールログで確認することをお勧めします。
