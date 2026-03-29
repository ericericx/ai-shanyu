# 任務清單：山裕電商系統 v1

> 狀態：待分派
> 日期：2026-03-29
> Change：shanyu-ecommerce-v1

---

## 任務分派總覽

| 任務 ID | 任務名稱 | 負責角色 | 相依任務 | 優先序 | Sprint |
|---------|---------|---------|---------|--------|--------|
| T-01 | Firebase 專案基礎架構設定 | firebase-integrator | 無 | P0 | S1 |
| T-02 | Flutter Web 專案初始化 | flutter-artisan | T-01 | P0 | S1 |
| T-03 | Firestore 安全規則與 Indexes | firebase-integrator | T-01 | P0 | S1 |
| T-04 | Cloud Functions 初始設定 | firebase-integrator | T-01 | P0 | S1 |
| T-05 | 使用者認證（後端邏輯） | firebase-integrator | T-01 | P0 | S1 |
| T-06 | 使用者認證（前端 UI） | flutter-artisan | T-02, T-05 | P0 | S1 |
| T-07 | 商品與分類資料模型（Firestore） | firebase-integrator | T-03 | P0 | S1 |
| T-08 | 首頁 CMS Banner（前後端） | flutter-artisan + firebase-integrator | T-02, T-03 | P1 | S1 |
| T-09 | Product Timeline 元件 | flutter-artisan | T-02, T-07 | P1 | S1 |
| T-10 | 商品列表頁 | flutter-artisan | T-02, T-07 | P1 | S1 |
| T-11 | 商品詳情頁 | flutter-artisan | T-02, T-07 | P1 | S1 |
| T-12 | 購物車（前後端） | flutter-artisan + firebase-integrator | T-06, T-07 | P1 | S2 |
| T-13 | 訂單建立流程（前後端） | flutter-artisan + firebase-integrator | T-12 | P1 | S2 |
| T-14 | Cloud Functions - scheduledPublish | firebase-integrator | T-04, T-07 | P1 | S2 |
| T-15 | CMS 後台 — 視覺管理（Banner/品牌故事） | flutter-artisan | T-06, T-07 | P2 | S2 |
| T-16 | CMS 後台 — 商品與分類管理 | flutter-artisan | T-15 | P2 | S2 |
| T-17 | 後台路由保護與 Admin Custom Claims | firebase-integrator | T-05 | P1 | S2 |
| T-18 | 會員中心頁面 | flutter-artisan | T-06, T-13 | P2 | S2 |
| T-19 | 行為追蹤（前後端） | flutter-artisan + firebase-integrator | T-11 | P2 | S3 |
| T-20 | 即時 Chat 客服（前後端） | flutter-artisan + firebase-integrator | T-06 | P2 | S3 |
| T-21 | 後台 CRM 瀏覽記錄查詢 | flutter-artisan | T-19 | P3 | S3 |
| T-22 | 後台 Chat 管理介面 | flutter-artisan | T-20 | P2 | S3 |
| T-23 | 品牌故事區塊（首頁） | flutter-artisan | T-02, T-08 | P2 | S1 |
| T-24 | 響應式 NavBar | flutter-artisan | T-02, T-06 | P0 | S1 |

---

## Sprint 1：基礎架構 + 認證 + 商品展示

### T-01：Firebase 專案基礎架構設定
**負責**：firebase-integrator
**相依**：無
**優先序**：P0（阻塞所有後續任務）

**工作內容**：
1. 建立 Firebase 專案（development 環境）
2. 啟用 Firestore Database（Native mode）
3. 啟用 Firebase Authentication（Google + Email/Password）
4. 啟用 Firebase Storage
5. 建立 `.firebaserc` 與 `firebase.json` 設定檔
6. 產生並提供 Flutter Web 使用的 Firebase 設定（`firebaseConfig`）

**產出物**：
- `firebase.json`
- `.firebaserc`
- `firebase_options_development.dart`（提供給 flutter-artisan）

**驗收條件**：
- [ ] Firebase Console 中可看到 development 專案
- [ ] 所有服務（Firestore、Auth、Storage）已啟用
- [ ] `firebase_options_development.dart` 設定檔已輸出

---

### T-02：Flutter Web 專案初始化
**負責**：flutter-artisan
**相依**：T-01（需要 Firebase 設定檔）
**優先序**：P0

**工作內容**：
1. 建立 Flutter Web 專案（`flutter create`）
2. 設定 development flavor（`main_development.dart`）
3. 加入 `pubspec.yaml` 依賴套件（參考 design.md 依賴清單）
4. 建立專案目錄結構（參考 design.md Section 2.1）
5. 設定 GoRouter 路由（`app_router.dart`，路由表參考 design.md Section 2.2）
6. 建立 `ResponsiveLayout` 元件（三個斷點邏輯）
7. 設定 `ProviderScope`（Riverpod）

**產出物**：
- 完整 Flutter 專案骨架
- `pubspec.yaml`
- `app_router.dart`
- `responsive_layout.dart`

**驗收條件**：
- [ ] `flutter run -d chrome` 可成功啟動
- [ ] Firebase 連接測試通過（能讀取 Firestore）
- [ ] 路由可正確導向各頁面（空頁面 placeholder 即可）

---

### T-03：Firestore 安全規則與 Indexes
**負責**：firebase-integrator
**相依**：T-01
**優先序**：P0

**工作內容**：
1. 撰寫 `firestore.rules`（參考 design.md Section 3.2）
2. 撰寫 `firestore.indexes.json`（參考 design.md Section 3.3）
3. 部署安全規則至 development 環境

**產出物**：
- `firestore.rules`
- `firestore.indexes.json`

**驗收條件**：
- [ ] 未登入用戶無法寫入 products
- [ ] 已登入用戶可讀取 isPublished = true 的商品
- [ ] admin 用戶可讀寫所有 collection
- [ ] Indexes 部署成功

---

### T-04：Cloud Functions 初始設定
**負責**：firebase-integrator
**相依**：T-01
**優先序**：P0

**工作內容**：
1. 初始化 `functions/` 目錄（TypeScript）
2. 設定 `package.json`（依賴 firebase-admin, firebase-functions）
3. 建立 `index.ts` 入口，預留 function 骨架
4. 設定 eslint 與 tsconfig

**產出物**：
- `functions/package.json`
- `functions/tsconfig.json`
- `functions/src/index.ts`（骨架）

**驗收條件**：
- [ ] `firebase deploy --only functions` 成功部署空 functions

---

### T-05：使用者認證（後端邏輯）
**負責**：firebase-integrator
**相依**：T-01
**優先序**：P0

**工作內容**：
1. 撰寫 Cloud Functions `onUserCreated` trigger：新用戶建立時，在 `/users/{uid}` 建立初始文件
2. 確認 Google Sign-In 在 Firebase Console 中已設定授權網域
3. 設計 `/users/{uid}` 文件結構（參考 design.md Section 3.1）

**Cloud Function 內容**：
```typescript
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  await admin.firestore().collection('users').doc(user.uid).set({
    uid: user.uid,
    email: user.email || '',
    displayName: user.displayName || '',
    photoURL: user.photoURL || '',
    provider: user.providerData[0]?.providerId === 'google.com' ? 'google' : 'email',
    isAdmin: false,
    socialBindings: {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
});
```

**產出物**：
- `functions/src/auth.ts`

**驗收條件**：
- [ ] 新用戶 Google 登入後，Firestore `/users/{uid}` 自動建立

---

### T-06：使用者認證（前端 UI）
**負責**：flutter-artisan
**相依**：T-02, T-05
**優先序**：P0

**工作內容**：
1. 實作 `AuthRepository`（Google Sign-In、Email 登入/註冊、登出）
2. 實作 `authStateProvider`（Riverpod StreamProvider）
3. 建立 `LoginPage`（Google 登入按鈕、Email 表單）
4. 實作忘記密碼功能（`sendPasswordResetEmail`）
5. GoRouter 路由保護（未登入導向 /login）

**驗收條件**：
- [ ] Google Sign-In 可在 Flutter Web 完成
- [ ] Email 登入/註冊流程完整
- [ ] 登出後導向首頁

---

### T-07：商品與分類資料模型（Firestore）
**負責**：firebase-integrator
**相依**：T-03
**優先序**：P0

**工作內容**：
1. 在 Firestore 建立測試用分類資料（梨山茶、水蜜桃、梨子各一筆）
2. 在 Firestore 建立測試用商品資料（每個分類至少 2 筆，含 season 欄位）
3. 確認商品資料結構符合 design.md Section 3.1 定義
4. 在 Flutter 端撰寫 `ProductModel` 與 `CategoryModel`（Dart class，含 `fromFirestore` 工廠方法）
5. 撰寫 `ProductsRepository`（讀取已上架商品、依分類篩選）
6. 撰寫 `CategoriesRepository`（讀取可見分類）

**產出物**：
- `lib/features/products/domain/product_model.dart`
- `lib/features/products/domain/category_model.dart`
- `lib/features/products/data/products_repository.dart`
- Firestore 測試資料

**驗收條件**：
- [ ] Flutter 端可成功讀取 Firestore 商品資料
- [ ] 依 categoryId 篩選商品功能正常
- [ ] season 欄位正確解析

---

### T-08：首頁 CMS Banner
**負責**：flutter-artisan（前端）+ firebase-integrator（後端）
**相依**：T-02, T-03
**優先序**：P1

**firebase-integrator 工作**：
1. 在 Firestore `/cms/banners` 建立初始測試資料
2. 建立 Firebase Storage `banners/` bucket 測試上傳

**flutter-artisan 工作**：
1. 實作 `BannersRepository`（讀取 `/cms/banners`）
2. 實作 `BannerWidget`（PageView 輪播、自動播放、dot indicators）
3. 整合至 `HomePage`

**驗收條件**：
- [ ] Banner 輪播動畫正常
- [ ] 每 4 秒自動切換
- [ ] 手動滑動切換正常

---

### T-09：Product Timeline 元件
**負責**：flutter-artisan
**相依**：T-02, T-07
**優先序**：P1

**工作內容**：
1. 實作 `ProductTimelineWidget`（月份軸 + 商品季節條）
2. 實作季節狀態計算邏輯（參考 design.md Section 4）
3. 桌面版橫向、手機版可左右滑動
4. 標示當前月份紅線
5. 商品狀態標籤（可預購/採購中/即將上架/季節結束）
6. 商品名稱點擊導向商品頁

**驗收條件**：
- [ ] 月份軸顯示正確（1-12）
- [ ] 今日月份紅線位置準確
- [ ] 商品狀態標籤根據今日日期動態計算
- [ ] 手機版橫向滑動正常

---

### T-10：商品列表頁
**負責**：flutter-artisan
**相依**：T-02, T-07
**優先序**：P1

**工作內容**：
1. 實作 `ProductListPage`（分類 Tab + 商品卡片格）
2. 實作 `ProductCard` 元件（主圖、名稱、價格、預購/限定標籤）
3. 子分類篩選（Chip 篩選列）
4. 響應式格局（桌面 3 欄、平板 2 欄、手機 1-2 欄）
5. 空狀態顯示

**驗收條件**：
- [ ] 分類切換正常
- [ ] 預購商品顯示標籤
- [ ] 三個斷點格局正確

---

### T-11：商品詳情頁
**負責**：flutter-artisan
**相依**：T-02, T-07
**優先序**：P1

**工作內容**：
1. 實作 `ProductDetailPage`（多圖輪播、商品資訊、加入購物車）
2. 麵包屑導覽
3. 預購資訊顯示（預計出貨日）
4. 未登入保護（彈出登入提示或導向登入頁）

**驗收條件**：
- [ ] 多圖輪播正常
- [ ] 預購商品顯示預計出貨日
- [ ] 未登入點擊加入購物車正確處理

---

### T-24：響應式 NavBar
**負責**：flutter-artisan
**相依**：T-02, T-06
**優先序**：P0

**工作內容**：
1. 實作 `NavBar` 元件（Logo、分類導覽、購物車 icon + badge、登入/頭像）
2. 手機版漢堡選單（Drawer）
3. 購物車 badge 使用 Riverpod 監聽 cart 商品數量
4. 登入狀態同步顯示

**驗收條件**：
- [ ] 登入後頭像正確顯示
- [ ] 購物車 badge 即時更新
- [ ] 手機版 Drawer 正常

---

### T-23：品牌故事區塊（首頁）
**負責**：flutter-artisan
**相依**：T-02, T-08
**優先序**：P2

**工作內容**：
1. 實作 `BrandStoryWidget`（圖文排版）
2. 讀取 `/cms/brand-story` 內容
3. 使用 `flutter_html` 渲染 HTML 內容

**驗收條件**：
- [ ] 圖文在三個斷點排版正確
- [ ] HTML 內容正確渲染

---

## Sprint 2：購物流程 + CMS 後台

### T-12：購物車（前後端）
**負責**：flutter-artisan（前端）+ firebase-integrator（後端 Firestore 規則）
**相依**：T-06, T-07
**優先序**：P1

**firebase-integrator 工作**：
1. 確認 `/carts/{userId}` 安全規則正確（只有本人可讀寫）

**flutter-artisan 工作**：
1. 實作 `CartRepository`（讀取/更新/清空購物車）
2. 實作 `CartPanel`（右側滑出面板）
3. 分組顯示一般商品與預購商品
4. 數量調整與移除功能
5. 總計計算（含預購小計）
6. 結帳按鈕

**驗收條件**：
- [ ] 加入商品後 badge 即時更新
- [ ] 購物車資料 Firestore 同步
- [ ] 預購商品分組顯示
- [ ] 換裝置後資料同步

---

### T-13：訂單建立流程（前後端）
**負責**：flutter-artisan（前端）+ firebase-integrator（後端）
**相依**：T-12
**優先序**：P1

**firebase-integrator 工作**：
1. 實作 `onOrderCreated` Cloud Function（log + 預留通知邏輯）
2. 確認訂單 Firestore 安全規則

**flutter-artisan 工作**：
1. 實作 `CheckoutPage`（訂單確認 + 收件資訊表單）
2. 實作 `OrdersRepository`（建立訂單、讀取用戶訂單）
3. 訂單確認頁面（顯示訂單編號）
4. 建立訂單後清空購物車

**驗收條件**：
- [ ] 成功建立訂單並在 Firestore 可查詢
- [ ] 訂單建立後購物車清空
- [ ] 訂單確認頁顯示訂單編號

---

### T-14：Cloud Functions - scheduledPublish
**負責**：firebase-integrator
**相依**：T-04, T-07
**優先序**：P1

**工作內容**：
1. 實作 `scheduledPublishProducts` function（參考 design.md Section 3.4）
2. 設定 Cloud Scheduler（每 5 分鐘）
3. 測試：新增一筆商品設定 2 分鐘後上架，確認自動上架

**驗收條件**：
- [ ] 設定預約上架時間後，時間到自動 isPublished: true
- [ ] Cloud Scheduler 設定正確

---

### T-15：CMS 後台 — 視覺管理
**負責**：flutter-artisan
**相依**：T-06, T-17（需要 admin 保護）
**優先序**：P2

**工作內容**：
1. 實作後台佈局骨架（側邊導覽 + 主內容區）
2. 實作 `CmsBannerPage`（Banner 列表、上傳、刪除、排序）
3. 實作 `CmsBrandStoryPage`（富文字編輯器或 HTML 輸入）
4. Firebase Storage 圖片上傳封裝（`StorageRepository`）
5. Logo 與背景圖更換

**驗收條件**：
- [ ] 上傳 Banner 圖片成功
- [ ] 前台即時反映 Banner 更新
- [ ] 品牌故事內容可儲存

---

### T-16：CMS 後台 — 商品與分類管理
**負責**：flutter-artisan
**相依**：T-15
**優先序**：P2

**工作內容**：
1. 實作 `AdminCategoriesPage`（分類 CRUD）
2. 實作 `AdminProductsPage`（商品列表 + 篩選搜尋）
3. 實作 `AdminProductFormPage`（商品新增/編輯表單，含所有欄位）
4. 圖片多圖上傳
5. 預約上架日期選擇器
6. 季節設定（月份選擇）

**驗收條件**：
- [ ] 新增商品表單所有欄位可儲存
- [ ] 季節設定月份正確儲存
- [ ] 預約上架欄位正確儲存

---

### T-17：後台路由保護與 Admin Custom Claims
**負責**：firebase-integrator
**相依**：T-05
**優先序**：P1

**工作內容**：
1. 撰寫 Cloud Function 設定 admin custom claim：
   ```typescript
   export const setAdminClaim = functions.https.onCall(async (data, context) => {
     // 只有已是 admin 的用戶可以設定其他用戶為 admin（bootstrap 例外）
     await admin.auth().setCustomUserClaims(data.uid, { admin: true });
   });
   ```
2. 提供初始化腳本：設定第一個 admin 用戶
3. GoRouter redirect 邏輯（確認 token 中有 admin: true）

**驗收條件**：
- [ ] 非 admin 用戶訪問 /admin 自動導向首頁
- [ ] admin 用戶可正常訪問所有後台頁面

---

### T-18：會員中心頁面
**負責**：flutter-artisan
**相依**：T-06, T-13
**優先序**：P2

**工作內容**：
1. 實作 `MemberCenterPage`（用戶資訊 + 訂單記錄）
2. 訂單列表（按時間降序）
3. 訂單詳情展開
4. 訂單狀態 Badge（不同顏色）

**驗收條件**：
- [ ] 訂單記錄正確顯示
- [ ] 訂單狀態 Badge 顏色正確
- [ ] 訂單詳情可展開查看商品

---

## Sprint 3：進階功能

### T-19：行為追蹤（前後端）
**負責**：flutter-artisan（前端）+ firebase-integrator（後端）
**相依**：T-11
**優先序**：P2

**firebase-integrator 工作**：
1. 確認 `/behaviors` 安全規則（允許新增，admin 可讀）
2. 設計去重查詢邏輯

**flutter-artisan 工作**：
1. 在 `ProductDetailPage` 進入時觸發行為記錄
2. 去重邏輯（同用戶、同商品、同天只記錄一次）

**驗收條件**：
- [ ] 進入商品詳情頁記錄事件
- [ ] 同天重複進入不重複記錄

---

### T-20：即時 Chat 客服（前後端）
**負責**：flutter-artisan（前端）+ firebase-integrator（後端）
**相依**：T-06
**優先序**：P2

**firebase-integrator 工作**：
1. 確認 `/chats` 與 `/chats/{chatId}/messages` 安全規則

**flutter-artisan 工作**：
1. 實作 `ChatWidget`（右下角懸浮按鈕 + 對話視窗）
2. 實作 `ChatRepository`（建立對話、發送訊息、監聽新訊息）
3. 訊息實時顯示（Firestore Stream）
4. 未讀 badge

**驗收條件**：
- [ ] 發送訊息後即時顯示
- [ ] Firestore 實時監聽新訊息
- [ ] 未讀 badge 正確更新

---

### T-21：後台 CRM 瀏覽記錄查詢
**負責**：flutter-artisan
**相依**：T-19
**優先序**：P3

**工作內容**：
1. 實作 `AdminCrmPage`
2. 依商品查詢瀏覽記錄（哪些用戶瀏覽過）
3. 顯示瀏覽次數、最近瀏覽時間

**驗收條件**：
- [ ] 可按商品篩選瀏覽記錄
- [ ] 顯示用戶 Email 與瀏覽時間

---

### T-22：後台 Chat 管理介面
**負責**：flutter-artisan
**相依**：T-20
**優先序**：P2

**工作內容**：
1. 實作 `AdminChatPage`（所有進行中對話列表）
2. 點擊對話進入回覆介面
3. 未讀數量顯示

**驗收條件**：
- [ ] 管理員可查看所有對話
- [ ] 回覆訊息用戶端即時顯示
- [ ] 關閉對話功能

---

## 任務依賴圖（簡化）

```
T-01 (Firebase 基礎)
├── T-02 (Flutter 初始化)
│   ├── T-06 (Auth 前端)
│   │   ├── T-12 (購物車前端)
│   │   │   └── T-13 (訂單前端)
│   │   │       └── T-18 (會員中心)
│   │   └── T-17 → T-15 → T-16
│   ├── T-08 (Banner)
│   │   └── T-23 (品牌故事)
│   ├── T-09 (Timeline) ─── 需 T-07
│   ├── T-10 (商品列表) ─── 需 T-07
│   ├── T-11 (商品詳情) ─── 需 T-07
│   │   └── T-19 (行為追蹤)
│   │       └── T-21 (CRM)
│   ├── T-20 (Chat 前端)
│   │   └── T-22 (後台 Chat)
│   └── T-24 (NavBar)
├── T-03 (Firestore 規則)
│   └── T-07 (商品資料模型)
├── T-04 (Functions 骨架)
│   └── T-14 (scheduledPublish)
└── T-05 (Auth 後端)
    └── T-17 (Admin Claims)
```

---

## 前端 Agent（flutter-artisan）任務清單

優先依序執行：T-02 → T-24 → T-06 → T-08 → T-09 → T-10 → T-11 → T-23 → T-12 → T-13 → T-15 → T-16 → T-18 → T-19 → T-20 → T-21 → T-22

## 後端 Agent（firebase-integrator）任務清單

優先依序執行：T-01 → T-03 → T-04 → T-05 → T-07 → T-08（後端部分）→ T-14 → T-17 → T-12（後端部分）→ T-13（後端部分）→ T-19（後端部分）→ T-20（後端部分）
