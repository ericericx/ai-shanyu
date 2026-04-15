## ADDED Requirements

### Requirement: PageViewTracker 自動記錄頁面瀏覽
系統 SHALL 透過 GoRouter 的 NavigatorObserver 機制，在頁面切換時自動記錄瀏覽事件至 Firestore `pageViews` 集合。記錄採用 fire-and-forget 模式，SHALL NOT 阻塞頁面載入或影響使用者操作。

#### Scenario: 使用者導航至新頁面時自動記錄
- **GIVEN** 使用者正在瀏覽任一頁面
- **WHEN** 使用者導航至另一個頁面（例如從首頁前往分類頁）
- **THEN** 系統 SHALL 自動寫入一筆瀏覽記錄至 Firestore `pageViews` 集合
- **AND** 頁面 SHALL 正常載入，不因追蹤邏輯而延遲

#### Scenario: Firestore 寫入失敗時靜默處理
- **GIVEN** Firestore 暫時不可用或發生網路錯誤
- **WHEN** PageViewTracker 嘗試寫入瀏覽記錄
- **THEN** 系統 SHALL 僅在 debug console 輸出錯誤訊息
- **AND** SHALL NOT 拋出例外或顯示錯誤 UI
- **AND** 頁面導航 SHALL 正常運作不受影響

#### Scenario: App 啟動時即開始追蹤
- **GIVEN** 使用者開啟或重新整理網站
- **WHEN** GoRouter 初始化完成並導航至初始頁面
- **THEN** 系統 SHALL 記錄第一個頁面的瀏覽事件

### Requirement: 瀏覽紀錄資料結構
每筆頁面瀏覽記錄 SHALL 包含以下欄位：
- `path`（string）：路由路徑，例如 `"/"`、`"/products/fruit"`、`"/cart"`
- `title`（string）：頁面標題，例如 `"首頁"`、`"水果分類"`、`"購物車"`
- `userId`（string | null）：登入使用者的 UID，匿名時為 null
- `timestamp`（Timestamp）：伺服器時間戳記，使用 `FieldValue.serverTimestamp()`
- `sessionId`（string）：UUID v4 格式，同一次瀏覽 session 內所有記錄共用同一組 sessionId
- `referrer`（string）：前一頁的路由路徑，無前一頁時為空字串 `""`

#### Scenario: 記錄包含完整欄位
- **GIVEN** 已登入使用者從首頁導航至分類頁
- **WHEN** 系統寫入瀏覽記錄
- **THEN** 記錄 SHALL 包含 path 為 `"/products/fruit"`
- **AND** title 為對應的頁面標題
- **AND** userId 為該使用者的 UID
- **AND** timestamp 為伺服器時間戳記
- **AND** sessionId 為本次 session 的 UUID
- **AND** referrer 為 `"/"`

#### Scenario: 同一 Session 共用 sessionId
- **GIVEN** 使用者開啟網站後瀏覽了多個頁面
- **WHEN** 查看該使用者的所有瀏覽記錄
- **THEN** 同一次瀏覽 session 內的所有記錄 SHALL 擁有相同的 sessionId

#### Scenario: 重新整理產生新 sessionId
- **GIVEN** 使用者正在瀏覽網站
- **WHEN** 使用者重新整理頁面（F5 或瀏覽器重新整理）
- **THEN** 重新整理後的瀏覽記錄 SHALL 使用新的 sessionId

### Requirement: 匿名與登入使用者都需追蹤
PageViewTracker SHALL 同時追蹤匿名（未登入）與已登入使用者的頁面瀏覽行為。

#### Scenario: 匿名使用者瀏覽
- **GIVEN** 使用者未登入
- **WHEN** 使用者瀏覽首頁或分類頁等公開頁面
- **THEN** 系統 SHALL 寫入瀏覽記錄
- **AND** 記錄中的 userId 欄位 SHALL 為 null
- **AND** 其餘欄位（path、title、timestamp、sessionId、referrer）SHALL 正常記錄

#### Scenario: 登入使用者瀏覽
- **GIVEN** 使用者已登入（Auth 狀態為已認證）
- **WHEN** 使用者瀏覽任一頁面
- **THEN** 系統 SHALL 寫入瀏覽記錄
- **AND** 記錄中的 userId 欄位 SHALL 為該使用者的 Firebase UID

#### Scenario: 使用者登入後追蹤身份更新
- **GIVEN** 使用者原先為匿名狀態並已產生瀏覽記錄
- **WHEN** 使用者完成登入
- **THEN** 登入後的新瀏覽記錄 SHALL 包含正確的 userId
- **AND** 登入前的匿名記錄 SHALL 保持 userId 為 null（不回溯更新）
