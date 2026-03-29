# /opsx:explore — 山裕電商系統範疇分析

> 建立日期：2026-03-29
> 負責人：Team Lead Architect

---

## 一、核心問題釐清

### 1.1 這是什麼系統？
山裕電商系統是一個以 **Firebase 為核心後端**的響應式網頁電商平台，主要銷售季節性高品質農產品（梨山茶、水蜜桃、梨子）。系統的差異化特點在於：
- **季節性商品流水線**：依照月份展示農產品的生長期與採收期，讓消費者預先了解哪些商品即將可以預購或採收
- **預購機制**：支援未到貨商品下單，混合一般商品與預購商品的購物車
- **CMS 後台**：管理員可直接控制首頁 Banner、品牌故事、商品上架時間

### 1.2 關鍵範疇邊界

| 範疇項目 | 包含 | 不包含 |
|---------|------|--------|
| 前端 | Flutter Web（響應式） | Native iOS/Android App |
| 後端 | Firebase (Firestore, Auth, Storage, Functions) | 自建伺服器 |
| 金流 | 待釐清（需求書未提及） | 第三方金流整合（此版本範疇外） |
| 即時客服 | Chat 功能 | 客服工單系統 |
| 社群綁定 | Line / Facebook 通知 | 社群媒體廣告整合 |
| 分析 | 商品瀏覽行為追蹤 | Google Analytics 完整 BI |

### 1.3 需求書未明確定義的項目（需後續確認）
1. **金流整合**：需求書提到完整購物流程但未提及付款方式（信用卡、ATM 轉帳、LINE Pay？）
2. **預購出貨邏輯**：混合購物車中，預購商品與一般商品是否分開出貨？
3. **Line / Facebook 綁定實作方式**：是 OAuth 登入還是僅用於通知推播？
4. **後台管理者身份驗證**：CMS 後台使用獨立帳號還是 Firebase Admin SDK？
5. **商品庫存管理**：是否需要庫存上限與售罄狀態？

---

## 二、技術選型分析

### 2.1 前端技術棧
- **框架**：Flutter Web（響應式網頁）
- **狀態管理**：Riverpod（適合 Firebase 串接的響應式架構）
- **路由**：GoRouter（支援 Web URL 路由）
- **UI 元件**：自訂元件為主，搭配 Material 3
- **複雜度評估**：
  - Product Timeline（時間軸）是高度客製化 UI 元件，開發成本較高
  - 響應式佈局需要 Mobile / Tablet / Desktop 三個斷點

### 2.2 後端技術棧
- **資料庫**：Cloud Firestore（NoSQL，適合動態 CMS 內容）
- **認證**：Firebase Authentication（Google OAuth + Email/Password）
- **檔案儲存**：Firebase Storage（Banner 圖、商品圖、品牌 Logo）
- **後端邏輯**：Cloud Functions for Firebase（預約上架排程、訂單狀態更新）
- **即時通訊**：Firestore 實時監聽（Chat 功能）或 Firebase Realtime Database

### 2.3 技術風險
1. **Cloud Functions 冷啟動**：預約上架若使用 Cloud Scheduler + Functions，冷啟動可能導致延遲
2. **Flutter Web SEO**：Flutter Web 的 SEO 能力有限，若未來有搜尋引擎曝光需求需額外處理
3. **Line / Facebook 通知整合**：需要 Line Messaging API 和 Facebook Messenger API，各有審核流程
4. **Firestore 安全規則**：CMS 後台寫入權限必須嚴格控制，避免未授權修改

---

## 三、資料模型初步分析

### 3.1 核心 Collections（Firestore）

```
/users/{userId}
  - email, displayName, photoURL
  - provider: 'google' | 'email'
  - socialBindings: { line?: string, facebook?: string }
  - createdAt, updatedAt

/products/{productId}
  - name, description, category
  - subcategory (e.g. 春茶、上海蜜)
  - price, preorderPrice
  - isPreorder: boolean
  - estimatedShipDate?: Timestamp
  - scheduledPublishAt?: Timestamp  // 預約上架
  - isPublished: boolean
  - stock?: number
  - images: string[]
  - season: { growthStart, growthEnd, harvestStart, harvestEnd }
  - weight, sortOrder

/categories/{categoryId}
  - name, description, coverImage
  - sortOrder, isVisible

/orders/{orderId}
  - userId, items: [{ productId, qty, price, isPreorder }]
  - status: 'pending' | 'paid' | 'shipped' | 'delivered' | 'cancelled'
  - totalAmount, shippingAddress
  - createdAt, updatedAt

/carts/{userId}
  - items: [{ productId, qty }]
  - updatedAt

/cms/{docId}
  - type: 'banner' | 'brand-story' | 'background' | 'logo'
  - content: any
  - updatedAt, updatedBy

/chats/{chatId}
  - userId, adminId
  - messages: subcollection
  - status: 'open' | 'closed'
  - createdAt

/behaviors/{behaviorId}
  - userId, productId
  - type: 'view'
  - timestamp
```

### 3.2 資料模型複雜度評估
- **Product Timeline** 需要每個商品的季節資訊（生長期、採收期），這個欄位設計需要謹慎
- **預購混合購物車** 需要 cart items 標記 isPreorder，結帳時分組處理
- **行為追蹤** 可能產生大量寫入，需評估 Firestore 寫入頻率與成本

---

## 四、系統複雜度評估

| 模組 | 複雜度 | 主要挑戰 |
|------|--------|---------|
| Product Timeline UI | 高 | 客製化時間軸元件，跨裝置響應式 |
| 預購混合購物車 | 高 | 狀態管理、出貨邏輯、預計日期顯示 |
| CMS 後台 | 中 | Firebase Storage 上傳、即時預覽 |
| 預約上架排程 | 中 | Cloud Functions + Scheduler |
| 行為追蹤 CRM | 中 | Firestore 批次寫入優化 |
| 會員認證 | 中 | Multi-provider Auth 整合 |
| 即時 Chat | 中 | Firestore 實時監聽 |
| 社群通知綁定 | 高 | Line/Facebook API 審核流程 |

**整體評估**：這是一個中大型電商專案，建議分 3 個 Sprint 完成：
- Sprint 1：基礎架構 + 認證 + 商品展示
- Sprint 2：購物流程 + CMS 後台
- Sprint 3：進階功能（Timeline、Chat、CRM、社群綁定）

---

## 五、決策紀錄

1. **Flutter Web 作為前端框架**：客戶需求，遵從執行
2. **Firebase 全棧**：降低後端維護成本，適合中小型電商
3. **金流暫不納入此版本範疇**：需求書未定義，待客戶確認後開立新的 change
4. **Line/Facebook 綁定僅設計資料結構**：API 整合留待 Sprint 3
5. **後台管理以 Firestore 安全規則 + Custom Claims 實作**：避免建立獨立後台服務

---

## 六、結論

範疇已釐清，可進入 `/opsx:ff` 產出完整產出物。此系統將拆分為以下 OpenSpec change：

**`shanyu-ecommerce-v1`**（本次 change）包含：
- Firebase 專案基礎架構
- 使用者認證（Google + Email）
- 商品資料模型與分類系統
- 首頁 CMS（Banner、品牌故事）
- 商品列表與商品詳情頁
- Product Timeline 元件
- 購物車（含預購）
- 訂單建立流程
- CMS 後台（Banner、商品、分類管理）
- 會員中心
- 行為追蹤
- Chat 功能
