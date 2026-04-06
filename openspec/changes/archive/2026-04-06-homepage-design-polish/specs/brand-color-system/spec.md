## MODIFIED Requirements

### Requirement: 全站品牌色採用深紅色系
系統 SHALL 將全站設計 Token 的主色由大地棕色替換為品牌深紅色。
- 主色（brandRed）：`#B82020`
- 次色（brandRedDark）：`#9C1B1B`
- `main.dart` 的 `ColorScheme.fromSeed` 種子色 SHALL 設定為 `#B82020`
- 所有原棕色（`#5C4033`、`#8D6E63`）使用點 SHALL 替換為對應深紅色 Token
- **新增**：所有色彩 Token 的定義來源 SHALL 為 `AppDesignTokens` 集中 Token 檔案，各 widget 內部 Token 類別 SHALL 引用而非硬編碼

#### Scenario: 首頁標題 accent 色顯示
- **WHEN** 使用者造訪首頁
- **THEN** 區塊標題左側 accent 條顯示品牌深紅色（`#B82020`）

#### Scenario: NavBar 圖示色
- **WHEN** 使用者查看頂部導覽列
- **THEN** Chat、購物車、後台、使用者頭像背景均使用品牌深紅色（`#B82020`）

#### Scenario: Avatar 背景色
- **WHEN** 使用者已登入且無大頭照
- **THEN** CircleAvatar 背景色顯示品牌深紅色（`#B82020`）

#### Scenario: Banner 佔位漸層
- **WHEN** Banner 圖片尚未載入或無資料
- **THEN** 佔位元件顯示深紅色系漸層（`#B82020` → `#9C1B1B`）

#### Scenario: Token 來源為集中檔案
- **WHEN** 檢視任何 widget 中的品牌色引用
- **THEN** 色值 SHALL 來自 `AppDesignTokens` 而非各 widget 內部硬編碼
