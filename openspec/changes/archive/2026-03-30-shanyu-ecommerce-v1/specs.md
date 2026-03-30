# 功能規格：山裕電商系統 v1

> 狀態：待審閱
> 版本：1.0.0
> 日期：2026-03-29

---

## 模組索引

| 編號 | 模組 | 類型 |
|------|------|------|
| SPEC-01 | Firebase 專案基礎架構 | 後端 |
| SPEC-02 | 使用者認證 | 前後端 |
| SPEC-03 | 商品資料模型與分類系統 | 後端 |
| SPEC-04 | 首頁 CMS（Banner、品牌故事） | 前後端 |
| SPEC-05 | Product Timeline 元件 | 前端 |
| SPEC-06 | 商品列表頁 | 前端 |
| SPEC-07 | 商品詳情頁 | 前端 |
| SPEC-08 | 購物車（含預購） | 前後端 |
| SPEC-09 | 訂單建立流程 | 前後端 |
| SPEC-10 | 會員中心 | 前後端 |
| SPEC-11 | CMS 後台 — 視覺與內容管理 | 前後端 |
| SPEC-12 | CMS 後台 — 商品與分類管理 | 前後端 |
| SPEC-13 | 行為追蹤 | 後端 |
| SPEC-14 | 即時 Chat 客服 | 前後端 |

---

## SPEC-01：Firebase 專案基礎架構

### 目標
建立 Firebase 專案，完成所有服務的初始設定，確保前後端 Agent 可以在 development 環境下開發。

### 功能需求

**FR-01-1** — 建立 Firebase 專案（development 與 production 兩個環境）
**FR-01-2** — 啟用 Firestore Database，設定 security rules 初始版本
**FR-01-3** — 啟用 Firebase Authentication（Google Provider + Email/Password Provider）
**FR-01-4** — 啟用 Firebase Storage，設定 CORS 與 security rules
**FR-01-5** — 啟用 Cloud Functions（Node.js 18 runtime）
**FR-01-6** — 設定 Flutter Web 專案，加入 Firebase 設定檔（development flavor）
**FR-01-7** — 建立 Firestore indexes 設定檔（firestore.indexes.json）

### 驗收條件
- [ ] Flutter Web 可成功連接 Firebase development 環境
- [ ] Firestore 讀寫測試通過
- [ ] Firebase Storage 上傳測試通過
- [ ] Cloud Functions 部署成功

---

## SPEC-02：使用者認證

### 目標
實作完整的使用者認證流程，支援 Google OAuth 與 Email/Password 兩種登入方式；登入或註冊成功後，確保 Firestore 存在對應使用者文件（含預設 `role`），以利購物車、會員資料與後續功能。

### 功能需求

**FR-02-1** — Google Sign-In：使用者點擊「以 Google 帳號登入」後，完成 OAuth 流程；成功後若 `users/{uid}` 尚不存在，由 **客戶端**（`AuthRepository`）寫入 Firestore 使用者文件（見下方資料結構與規則）
**FR-02-2** — Email 註冊：使用者填寫 Email + 密碼，驗證 Email 格式，建立帳號；成功後同 **FR-02-9** 確保 Firestore 使用者文件
**FR-02-3** — Email 登入：已註冊使用者以 Email + 密碼登入；成功後同 **FR-02-9**（補齊舊帳號或觸發器未部署時缺件之文件）
**FR-02-4** — 忘記密碼：發送密碼重設 Email
**FR-02-5** — 登出：清除本地 Auth 狀態
**FR-02-6** — 導覽列狀態同步：登入後右上角顯示用戶頭像/名稱，登出後顯示「登入」按鈕
**FR-02-7** — 購物車同步：登入後自動載入 Firestore 中該用戶的購物車
**FR-02-8** — 社群帳號綁定欄位：在 Firestore 用戶資料中保留 `lineLinked`、`facebookLinked`（boolean，預設 `false`）；長期可與 `socialBindings` 設計對齊，此版本不實作綁定 UI
**FR-02-9** — Firestore 使用者文件（客戶端 lazy create）：實作於 `AuthRepository.ensureUserFirestoreProfile` — 於 Google 登入、Email 登入、Email 註冊 **成功且 `User` 非 null** 後執行；先 `get` `users/{uid}`，**僅在文件不存在時** `set` 一筆（欄位見下方）；寫入失敗僅記錄 log，**不阻斷**登入流程

### 資料結構（Firestore `users/{uid}`）

與 `ensureUserFirestoreProfile` 寫入欄位一致：

```
uid: string              // 必須等於文件 ID
email: string
displayName: string | null
photoURL: string | null
role: string             // 註冊／首次建立時固定為 'customer'；晉升 admin 由後台流程與 custom claims 處理
createdAt: Timestamp
updatedAt: Timestamp
lineLinked: boolean
facebookLinked: boolean
```

### 安全規則（摘要）

- `users/{userId}`：**本人**可 `create` 自己的文件，且需符合 `request.resource.data.uid == userId`、`request.resource.data.role == 'customer'`，避免客戶端自建 admin。
- 其餘讀寫規則維持原設計（本人讀寫、admin 可讀寫他人等）。

### 使用者故事
- 作為訪客，我可以點擊「以 Google 帳號登入」，完成 Google OAuth 後進入已登入狀態，且 Firestore 會有我的使用者文件（若先前沒有）
- 作為訪客，我可以以 Email 和密碼完成新帳號註冊，並寫入預設 `role: customer` 之使用者文件
- 作為已登入用戶，我可以在右上角看到我的頭像，點擊後進入會員中心

### 驗收條件
- [ ] Google Sign-In 流程可在 Flutter Web 上完成
- [ ] Email 註冊並收到驗證信
- [ ] 登入後導覽列即時更新
- [ ] 登入後購物車資料自動同步
- [ ] 首次註冊或首次登入後，Firestore `users` 底下可見對應 `uid` 文件，且 `role` 為 `customer`
- [ ] 已存在之 `users/{uid}` 不會被登入流程覆寫

---

## SPEC-03：商品資料模型與分類系統

### 目標
定義商品（Product）與分類（Category）的完整資料模型，並實作 Firestore 讀寫邏輯。

### 功能需求

**FR-03-1** — 分類（Category）CRUD：後台可新增/編輯/刪除分類，設定名稱、排序權重、封面圖、是否顯示
**FR-03-2** — 商品（Product）CRUD：後台可新增/編輯/刪除商品，包含名稱、描述、分類、子分類、價格、庫存、圖片、季節資訊
**FR-03-3** — 預約上架：商品可設定 `scheduledPublishAt` 欄位，Cloud Functions 排程檢查並自動設定 `isPublished: true`
**FR-03-4** — 預購標記：商品可設定 `isPreorder: true` 與 `estimatedShipDate`
**FR-03-5** — 商品季節資訊：每個商品有 `season` 物件，包含生長期開始/結束、採收期開始/結束（月份）
**FR-03-6** — Firestore 安全規則：前台只能讀取 `isPublished: true` 的商品

### 資料結構（Firestore）
```
/categories/{categoryId}
  name: string
  description: string
  coverImage: string (Storage URL)
  sortOrder: number
  isVisible: boolean
  createdAt: Timestamp
  updatedAt: Timestamp

/products/{productId}
  name: string
  description: string
  categoryId: string
  subcategory: string
  price: number
  preorderPrice?: number
  isPreorder: boolean
  estimatedShipDate?: Timestamp
  scheduledPublishAt?: Timestamp
  isPublished: boolean
  stock?: number
  images: string[] (Storage URLs)
  season: {
    growthStart: number  // 月份 1-12
    growthEnd: number
    harvestStart: number
    harvestEnd: number
  }
  sortOrder: number
  createdAt: Timestamp
  updatedAt: Timestamp
```

### 驗收條件
- [ ] 後台新增商品後，前台可查詢到（isPublished: true）
- [ ] 預約上架：設定未來時間後，時間到自動 isPublished 改為 true
- [ ] 分類排序正確反映在前台

---

## SPEC-04：首頁 CMS（Banner、品牌故事）

### 目標
實作首頁視覺元素的 CMS 管理與前台展示。

### 功能需求

**FR-04-1** — Banner 輪轉：前台首頁展示多張 Banner 圖片，支援自動輪播與手動切換
**FR-04-2** — Banner 管理：後台可上傳/刪除 Banner 圖片，設定排序與連結 URL
**FR-04-3** — 品牌故事：前台展示圖文品牌故事內容
**FR-04-4** — 品牌故事管理：後台可編輯品牌故事標題、內文、圖片
**FR-04-5** — Logo 管理：後台可更換網站 Logo
**FR-04-6** — 背景圖管理：後台可設定特定頁面的背景圖

### CMS 資料結構（Firestore）
```
/cms/banners
  items: [{ id, imageUrl, linkUrl, sortOrder, isVisible }]
  updatedAt: Timestamp
  updatedBy: string (userId)

/cms/brand-story
  title: string
  content: string (支援 HTML 或 Markdown)
  imageUrl: string
  updatedAt: Timestamp

/cms/assets
  logo: string (Storage URL)
  backgroundImages: { home?: string, product?: string }
  updatedAt: Timestamp
```

### 驗收條件
- [ ] 後台上傳 Banner 後，前台 3 秒內可看到更新
- [ ] Banner 輪播動畫流暢（60fps）
- [ ] 品牌故事圖文在三個斷點下排版正確

---

## SPEC-05：Product Timeline 元件

### 目標
實作商品季節流水線元件，視覺化展示各農產品的生長期與採收期，並標註當前月份狀態。

### 功能需求

**FR-05-1** — 時間軸佈局：橫向時間軸（手機版改為縱向），顯示 1-12 月
**FR-05-2** — 商品季節條：每個商品（或商品子分類）對應一條橫向進度條，標示生長期（綠色）與採收期（橙色）
**FR-05-3** — 當前月份標示：用垂直線標示今天所在月份，幫助使用者快速定位
**FR-05-4** — 商品狀態標籤：根據當前月份判斷每個商品的狀態：
  - `可預購`（生長期中、未到採收期）
  - `採購中`（採收期中）
  - `即將上架`（距採收期 < 1 個月）
  - `季節結束`（採收期已過）
**FR-05-5** — 點擊商品名稱：導向對應的商品分類頁或商品詳情頁
**FR-05-6** — 資料來源：從 Firestore /products 讀取有 season 欄位的商品

### UI 規格
- 桌面版：橫向時間軸，商品名稱在左側固定欄
- 手機版：縱向捲動，月份在橫軸，可左右滑動
- 顏色規範：生長期 #4CAF50（綠）、採收期 #FF9800（橙）、今日線 #E53935（紅）

### 驗收條件
- [ ] 12 個月份正確顯示
- [ ] 當前月份紅線位置準確
- [ ] 商品狀態標籤根據今日日期動態計算正確
- [ ] 手機版可左右滑動月份軸
- [ ] 點擊商品名稱正確導向

---

## SPEC-06：商品列表頁

### 目標
實作商品分類頁，依分類（梨山茶、水蜜桃、梨子）展示商品卡片。

### 功能需求

**FR-06-1** — 分類導覽：頂部顯示分類 Tab 或側邊欄，點擊切換分類
**FR-06-2** — 商品卡片：展示商品主圖、名稱、價格、預購標籤、季節限定標籤
**FR-06-3** — 子分類篩選：可依子分類篩選（如梨山茶下的春茶/秋茶/冬茶）
**FR-06-4** — 排序：依照 `sortOrder` 欄位排序展示
**FR-06-5** — 空狀態：分類下無商品時顯示「本季商品即將上架」提示
**FR-06-6** — 響應式格局：桌面 3 欄、平板 2 欄、手機 1 欄（或 2 欄）

### 驗收條件
- [ ] 分類切換流暢
- [ ] 預購商品顯示預購標籤
- [ ] 已售完商品顯示售完狀態（若有 stock 欄位 = 0）

---

## SPEC-07：商品詳情頁

### 目標
實作商品詳情頁，展示完整商品資訊，並提供加入購物車功能。

### 功能需求

**FR-07-1** — 商品圖片輪播：多張圖片可左右切換
**FR-07-2** — 商品資訊：名稱、描述、價格、預購資訊（預計出貨日）、季節說明
**FR-07-3** — 加入購物車按鈕：點擊後顯示數量選擇，確認後加入購物車
**FR-07-4** — 預購說明：若 isPreorder 為 true，顯示預計出貨日與預購說明
**FR-07-5** — 麵包屑導覽：首頁 > 分類 > 商品名稱
**FR-07-6** — 未登入保護：點擊加入購物車時若未登入，導向登入頁

### 驗收條件
- [ ] 加入購物車後，購物車 icon 數量即時更新
- [ ] 預購商品顯示預計出貨日
- [ ] 未登入點擊加入購物車導向登入

---

## SPEC-08：購物車（含預購）

### 目標
實作購物車功能，支援一般商品與預購商品混合，購物車資料存於 Firestore。

### 功能需求

**FR-08-1** — 購物車側滑面板：點擊右上角購物車 icon，從右側滑出購物車
**FR-08-2** — 商品列表：顯示商品圖、名稱、數量、單價、小計
**FR-08-3** — 數量調整：增減按鈕，最低 1，超過庫存上限時 disable
**FR-08-4** — 移除商品：每個品項有刪除按鈕
**FR-08-5** — 預購商品標示：預購商品在購物車中顯示特殊標籤與預計出貨日
**FR-08-6** — 購物車分組顯示：若有預購商品，分組顯示「一般商品」與「預購商品」
**FR-08-7** — 總計計算：分別顯示一般商品小計、預購商品小計、總計
**FR-08-8** — Firestore 同步：購物車資料即時寫入 /carts/{userId}，換裝置後資料不遺失
**FR-08-9** — 結帳按鈕：跳轉到結帳頁面

### 資料結構
```
/carts/{userId}
  items: [
    {
      productId: string
      productName: string
      productImage: string
      price: number
      qty: number
      isPreorder: boolean
      estimatedShipDate?: Timestamp
    }
  ]
  updatedAt: Timestamp
```

### 驗收條件
- [ ] 加入商品後購物車立即顯示
- [ ] 預購商品與一般商品分組展示
- [ ] 換裝置登入後購物車資料同步

---

## SPEC-09：訂單建立流程

### 目標
實作從購物車到建立訂單的結帳流程（不含金流付款，此版本僅建立訂單記錄）。

### 功能需求

**FR-09-1** — 訂單確認頁：顯示購物車商品清單、總金額
**FR-09-2** — 收件資訊填寫：收件人姓名、電話、地址、備註
**FR-09-3** — 建立訂單：點擊「確認訂單」後，在 Firestore 建立訂單文件，清空購物車
**FR-09-4** — 訂單確認頁面：顯示訂單編號與感謝訊息
**FR-09-5** — 訂單狀態：初始狀態為 `pending`
**FR-09-6** — 訂單通知（預留）：建立訂單後觸發 Cloud Functions，預留 Line/Email 通知邏輯（此版本僅 log）

### 資料結構
```
/orders/{orderId}
  userId: string
  userEmail: string
  items: [
    {
      productId: string
      productName: string
      price: number
      qty: number
      isPreorder: boolean
      estimatedShipDate?: Timestamp
    }
  ]
  shippingInfo: {
    name: string
    phone: string
    address: string
    note?: string
  }
  totalAmount: number
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled'
  createdAt: Timestamp
  updatedAt: Timestamp
```

### 驗收條件
- [ ] 填寫收件資訊後可成功建立訂單
- [ ] 訂單建立後購物車清空
- [ ] Firestore 訂單資料結構完整

---

## SPEC-10：會員中心

### 目標
實作會員中心頁面，顯示用戶資訊與歷史訂單。

### 功能需求

**FR-10-1** — 會員資訊：顯示頭像、名稱、Email、登入方式
**FR-10-2** — 訂單記錄：完整歷史訂單清單，顯示訂單編號、日期、商品數、總金額、狀態
**FR-10-3** — 訂單詳情：點擊訂單可展開查看商品清單與出貨資訊
**FR-10-4** — 登出按鈕

### 驗收條件
- [ ] 訂單記錄按建立時間降序排列
- [ ] 訂單狀態以不同顏色 Badge 顯示

---

## SPEC-11：CMS 後台 — 視覺與內容管理

### 目標
實作後台視覺管理頁面，讓管理員可以管理 Banner、品牌故事、Logo。

### 功能需求

**FR-11-1** — 後台路由保護：只有 admin role（Firebase Custom Claims）的用戶可訪問 /admin
**FR-11-2** — Banner 管理：上傳 Banner 圖片（至 Firebase Storage），設定排序、連結 URL、是否顯示
**FR-11-3** — Banner 拖拉排序：支援拖拉調整 Banner 順序
**FR-11-4** — 品牌故事編輯：WYSIWYG 或 Markdown 編輯器，可上傳圖片
**FR-11-5** — Logo 更換：上傳新 Logo 圖片
**FR-11-6** — 背景圖設定：為不同頁面設定背景圖

### 驗收條件
- [ ] 非 admin 用戶訪問 /admin 自動導向首頁
- [ ] 上傳 Banner 後前台即時反映
- [ ] 圖片上傳支援 JPG/PNG/WebP，大小限制 5MB

---

## SPEC-12：CMS 後台 — 商品與分類管理

### 目標
實作後台商品與分類的 CRUD 管理介面。

### 功能需求

**FR-12-1** — 分類管理：新增/編輯/刪除分類，設定名稱、排序、封面圖、是否顯示
**FR-12-2** — 商品列表：顯示所有商品（含已下架），支援依分類篩選、依關鍵字搜尋
**FR-12-3** — 商品新增/編輯表單：
  - 基本資訊：名稱、描述、分類、子分類
  - 價格設定：定價、預購價（選填）
  - 庫存（選填）
  - 季節設定：生長期月份範圍、採收期月份範圍
  - 圖片上傳（多圖支援）
  - 上架設定：立即上架 / 預約上架（選擇日期時間）/ 下架
  - 預購設定：是否為預購商品、預計出貨日
**FR-12-4** — 商品刪除：軟刪除（設 isPublished: false）
**FR-12-5** — 商品排序：拖拉調整排序

### 驗收條件
- [ ] 新增商品表單所有欄位可正確儲存
- [ ] 預約上架設定後，Cloud Functions 在時間到時自動上架
- [ ] 圖片上傳至 Firebase Storage，URL 正確儲存

---

## SPEC-13：行為追蹤

### 目標
記錄使用者的商品瀏覽行為，供後台 CRM 查詢。

### 功能需求

**FR-13-1** — 瀏覽事件記錄：使用者進入商品詳情頁時，記錄一筆 behavior 事件到 Firestore
**FR-13-2** — 行為資料結構：包含 userId（未登入則為 anonymous + sessionId）、productId、timestamp
**FR-13-3** — 去重邏輯：同一用戶同一商品同一天只記錄一次
**FR-13-4** — 後台 CRM 查詢：管理員可查詢特定商品被哪些用戶瀏覽過（含瀏覽次數與時間）

### 資料結構
```
/behaviors/{behaviorId}
  userId: string  // 已登入用戶 ID 或 'anon_{sessionId}'
  productId: string
  productName: string
  type: 'view'
  timestamp: Timestamp
  date: string  // 'YYYY-MM-DD'，用於去重查詢
```

### 驗收條件
- [ ] 進入商品詳情頁自動記錄事件
- [ ] 後台可按商品查詢瀏覽記錄
- [ ] 同用戶同商品同天不重複記錄

---

## SPEC-14：即時 Chat 客服

### 目標
實作使用者與管理員之間的即時文字客服系統。

### 功能需求

**FR-14-1** — 使用者端 Chat Widget：右下角懸浮 Chat 按鈕，點擊開啟對話視窗
**FR-14-2** — 發送訊息：使用者輸入文字並送出
**FR-14-3** — 即時接收訊息：使用 Firestore 實時監聽，管理員回覆後立即顯示
**FR-14-4** — 後台 Chat 管理：管理員可查看所有進行中的對話，點擊回覆
**FR-14-5** — 對話狀態：open / closed
**FR-14-6** — 未讀提示：使用者端與管理員端各自顯示未讀訊息 badge

### 資料結構
```
/chats/{chatId}
  userId: string
  userName: string
  status: 'open' | 'closed'
  lastMessage: string
  lastMessageAt: Timestamp
  unreadByAdmin: number
  unreadByUser: number
  createdAt: Timestamp

/chats/{chatId}/messages/{messageId}
  senderId: string
  senderName: string
  senderRole: 'user' | 'admin'
  content: string
  timestamp: Timestamp
  isRead: boolean
```

### 驗收條件
- [ ] 使用者送出訊息後管理員端立即顯示
- [ ] 訊息以時間排序顯示
- [ ] 未讀 badge 數量正確

---

## 非功能性需求

| 項目 | 需求 |
|------|------|
| 響應式 | 支援 Mobile (320px+)、Tablet (768px+)、Desktop (1200px+) |
| 效能 | 首頁首屏載入 < 3 秒（Firebase CDN） |
| 安全性 | Firestore Security Rules 防止未授權讀寫 |
| 環境隔離 | Development / Production 使用不同 Firebase 專案 |
| 圖片格式 | 上傳支援 JPG/PNG/WebP，建議壓縮至 < 1MB |
