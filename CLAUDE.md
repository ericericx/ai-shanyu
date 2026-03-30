# 開發守則

## 語言規範

所有文件與對話一律以**繁體中文**書寫。

## 溝通守則

1. **OpenSpec 優先** — 任何功能開發（例如：新增水蜜桃分類），Team Lead 必須先更新 `specs.md`，前端與後端才能開始動工。
2. **Task 驅動** — 所有工作必須掛在 TaskCreate 下，完成後標註為完成。
3. **環境隔離** — 所有 Agent 在開發時必須使用 development flavor，直到 Team Lead 進行 RemoteTrigger 佈署到生產環境。

## Agent 團隊

| Agent | 角色 | 負責範疇 |
|-------|------|---------|
| **team-lead-architect** | Team Lead | 需求拆解、任務分派、整合審閱、佈署決策 |
| **flutter-artisan** | 前端 | Flutter Web UI、狀態管理、路由 |
| **firebase-integrator** | 後端 | Cloud Functions、Firestore、Auth、部署 |
| **the-shield-qa** | QA | 整合測試、連結完整性、邊界案例、佈署前把關 |

## Agent 團隊功能開發 SOP

Team Lead 負責帶領前端、後端與 QA Agent 完成每一個功能，流程如下：

### 階段一：需求確認（Team Lead）
1. 收到功能需求後，執行 `/opsx:explore` 釐清範疇與目標。
2. 執行 `/opsx:propose <change-name>` 產出提案、規格、設計與任務產出物。
3. 將產出物同步給前端與後端 Agent 確認，取得同意後進入下一階段。

### 階段二：任務分派（Team Lead）
1. 依據 `tasks.md` 拆分工作，使用 `TaskCreate` 為每位 Agent 建立對應任務。
2. 明確標註每個任務的負責角色（前端 / 後端 / QA）與相依關係。
3. 確認所有 Agent 皆使用 **development flavor** 環境。

### 階段三：平行實作（前端 Agent / 後端 Agent）
1. 各自依照分配的任務執行 `/opsx:apply`，逐一完成實作。
2. 每完成一個 spec，執行 `/opsx:verify` 驗證，再執行 `/opsx:archive` 歸檔，最後立即 git commit。
3. 完成後將對應 TaskCreate 任務標註為完成，並通知 Team Lead。

### 階段四：QA 驗證（the-shield-qa）
1. Team Lead 通知 QA Agent 所有實作任務已完成。
2. QA Agent 執行以下檢查：
   - Flutter Integration Test（happy path + edge cases）
   - 路由與連結完整性掃描（所有頁面跳轉、按鈕）
   - 邊界案例壓測（空值、網路中斷、重複提交）
   - Firebase Logs 檢查（Crashlytics、異常事件）
   - 環境隔離確認（development flavor，無生產環境污染）
3. QA Agent 產出驗證報告：
   - ✅ 通過項目
   - ❌ 失效項目（含 Bug Report）
   - ⚠️ 需觀察項目
4. 若有失敗項目，Team Lead 重新開立 Task 指派給對應 Agent 修正，修正後 QA 重新驗證。

### 階段五：整合審閱（Team Lead）
1. 確認所有任務皆已完成並標註，QA 驗證通過。
2. 審閱各 commit，確保實作符合原始規格。
3. 若有問題，重新開立 Task 指派給對應 Agent 修正。

### 階段六：佈署（Team Lead）
1. 所有變更確認無誤、QA 簽核後，執行 `RemoteTrigger` 佈署到生產環境。
2. 佈署後通知 QA Agent 執行生產環境 smoke test。
3. 確認生產環境運作正常後，本次功能開發結束。

---

## 實作前必須遵循 OpenSpec 流程

**任何新功能、修復或重大變更，開始撰寫程式碼前，必須先完成 OpenSpec 流程。**

### 流程步驟

1. **提案** — 執行 `/opsx:propose <change-name>`，建立包含提案、規格、設計與任務的變更資料夾。
2. **審閱** — 將產生的產出物提交給 agent team members / 執行 agent 同意後才能繼續。
3. **實作** — 執行 `/opsx:apply`，依照核准計畫逐一完成任務。
4. **驗證** — 執行 `/opsx:verify`，確認實作符合變更產出物。
5. **歸檔與提交** — 執行 `/opsx:archive` 完成歸檔，接著立即建立 git commit。

### 規則

- 未在 `openspec/changes/` 下建立對應變更前，禁止開始開發功能。
- 需求不明確時，先執行 `/opsx:explore` 釐清問題。
- 不可跳過或合併步驟，實作前必須備齊所有產出物（提案、規格、設計、任務）。
- 實作過程中如範疇有變動，需先更新對應產出物再繼續。
- 小型獨立 bug 修復（typo、單行修正）可由開發者自行決定是否跳過 OpenSpec，但功能開發與重構不可跳過。
- 每個 spec 實作並歸檔後，**立即建立 git commit**，範疇對應該次變更，不可將多個 spec 合併為單一 commit。

### 指令速查

| 情境 | 指令 |
|------|------|
| 開始新功能 | `/opsx:propose <name>` |
| 釐清問題 | `/opsx:explore` |
| 一次產出所有產出物 | `/opsx:ff` |
| 執行實作任務 | `/opsx:apply` |
| 繼續進行中的變更 | `/opsx:continue` |
| 驗證完成度 | `/opsx:verify` |
| 歸檔完成的變更 | `/opsx:archive` |
| 批次歸檔多個變更 | `/opsx:bulk-archive` |
