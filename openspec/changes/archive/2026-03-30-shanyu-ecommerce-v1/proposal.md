# 提案：山裕電商系統 v1（shanyu-ecommerce-v1）

> 狀態：待審閱
> 提案日期：2026-03-29
> 提案人：Team Lead Architect

---

## 一、背景與動機

山裕是一個專營季節性高品質農產品的品牌，現有業務以線下銷售與社群媒體推廣為主，缺乏完整的線上電商通路。客戶需要建立一個能夠：

1. 展示品牌精神與農產品季節性特質的視覺化平台
2. 支援預購機制，讓消費者在採收前下單鎖貨
3. 提供完整的會員系統與訂單管理
4. 讓管理員能夠自主管理網站內容，無需工程師介入

## 二、目標

### 主要目標
- 建立功能完整的電商平台，涵蓋商品展示、購物車、結帳（訂單建立）、會員系統
- 建立 CMS 後台，讓業主可自主管理 Banner、商品、分類內容
- 實作商品季節流水線（Product Timeline），強化品牌差異化

### 次要目標
- 建立行為追蹤基礎，支援未來精準行銷
- 建立即時 Chat 功能，提升客服效率
- 設計 Line / Facebook 社群綁定的資料結構，為通知推播預留擴充空間

## 三、範疇

### 納入（In Scope）

**使用者端**
- 響應式首頁（Banner 輪轉、品牌故事、Product Timeline）
- 商品分類頁（梨山茶、水蜜桃、梨子）
- 商品詳情頁（含預購資訊）
- 購物車（一般商品 + 預購商品混合）
- 訂單建立流程（訂單資料填寫、建立訂單）
- 會員中心（Google / Email 登入、交易記錄）
- 即時 Chat 客服

**管理後台**
- CMS：Banner、品牌故事、Logo、背景圖管理
- 商品管理（新增、編輯、預約上架）
- 分類管理
- 顧客行為瀏覽記錄
- 訂單管理

### 排除（Out of Scope）
- 金流整合（信用卡、ATM、第三方支付）— 待後續版本
- Line / Facebook API 通知推播 — 留 Sprint 3 實作（此版本僅建資料結構）
- Native iOS / Android App
- SEO 優化（Flutter Web 限制）
- 庫存警示 Email 通知

## 四、成功標準

1. 使用者可以完成從瀏覽商品到建立訂單的完整流程
2. 管理員可以在後台新增/編輯商品，且前台即時反映
3. Product Timeline 可以正確顯示當前月份與商品季節狀態
4. Firebase Auth 登入成功率 100%（Google + Email）
5. 所有頁面在 Mobile / Tablet / Desktop 三個斷點下正常顯示

## 五、技術選型決策

| 項目 | 選擇 | 理由 |
|------|------|------|
| 前端 | Flutter Web | 客戶指定，跨裝置一致體驗 |
| 後端 | Firebase | 降低維運成本，Firestore 適合 CMS 場景 |
| 狀態管理 | Riverpod | 與 Firebase Stream 整合佳 |
| 路由 | GoRouter | Flutter Web URL 路由支援 |
| 排程 | Cloud Functions + Cloud Scheduler | 預約上架功能 |

## 六、風險與緩解策略

| 風險 | 可能性 | 影響 | 緩解策略 |
|------|--------|------|---------|
| Flutter Web SEO 不足 | 高 | 中 | 可考慮 Server-Side Rendering 方案，此版本暫不處理 |
| Firestore 寫入頻率過高（行為追蹤） | 中 | 低 | 使用批次寫入，延遲彙整 |
| Cloud Functions 冷啟動影響預約上架準確度 | 低 | 低 | 接受 ±5 分鐘誤差，或升級 min-instances |
| Line/Facebook API 審核時間過長 | 高 | 低 | 此版本不實作 API，僅保留資料欄位 |

## 七、里程碑規劃

| Sprint | 目標 | 預計產出 |
|--------|------|---------|
| Sprint 1 | 基礎架構 + 認證 + 商品展示 | Firebase 設定、Auth、商品列表、Product Timeline |
| Sprint 2 | 購物流程 + CMS 後台 | 購物車、訂單、後台商品/CMS 管理 |
| Sprint 3 | 進階功能 | Chat、CRM 行為追蹤、會員中心完整功能 |

## 八、依賴關係

- Firebase 專案需由 Team Lead 建立並提供設定檔
- Google OAuth 需設定授權網域
- Firebase Storage CORS 規則需配置

---

**審閱狀態**：等待前端 Agent（flutter-artisan）與後端 Agent（firebase-integrator）確認
