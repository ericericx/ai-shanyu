# Specs: navbar-dynamic-categories

## 功能規格

### S-01：動態分類連結

**描述**：`AppNavBar` 桌機版中段的分類連結必須從 `categoriesProvider` 動態載入，不得使用任何硬編碼分類資料。

**行為規格**：

| 狀態 | NavBar 中段顯示 |
|------|----------------|
| 載入中（AsyncLoading） | 隱藏（`SizedBox.shrink()`），不顯示 skeleton 或舊資料 |
| 載入失敗（AsyncError） | 隱藏（`SizedBox.shrink()`），不顯示錯誤訊息 |
| 無分類（空列表） | 隱藏，不顯示任何連結 |
| 有分類（有資料） | 依照 `CategoryModel.sortOrder` 升冪排序後，逐一渲染分類連結 |

**連結行為**：
- 每個分類連結點擊後導航至 `/products/{CategoryModel.id}`。
- 連結文字使用 `CategoryModel.name`。
- 連結的 hover 動畫行為與原 `_NavCategoryLink` 一致（顏色漸變、字重加粗）。

### S-02：移除硬編碼常數

**描述**：移除 `_NavCategory` 類別與 `_kNavCategories` 常數，不得在程式碼中遺留任何硬編碼分類資料。

### S-03：不影響現有功能

**描述**：以下元件的行為在此次變更後必須完全不變：

- `_BrandLogo`
- `_ChatButton`
- `_CartButton`
- `_AdminEntryButton`
- `_UserAction`（`_LoginTextButton`、`_UserAvatar`）
- 手機版 Layout（`isDesktop == false` 時不渲染分類連結，維持現狀）

## 非功能規格

- **即時性**：分類連結在 Firestore Stream 推送後 < 1 秒內更新，無需手動刷新。
- **無閃爍**：載入中不顯示舊的硬編碼資料，避免「先顯示錯誤分類、再替換」的視覺跳動。
