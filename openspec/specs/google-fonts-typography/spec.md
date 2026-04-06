# google-fonts-typography Specification

## Purpose
定義全站字型系統，使用 Google Fonts 提升視覺質感。

## Requirements

### Requirement: 新增 google_fonts 套件依賴
系統 SHALL 在 `pubspec.yaml` 新增 `google_fonts` 套件依賴。

#### Scenario: 套件可正常匯入
- **WHEN** 執行 `flutter pub get`
- **THEN** `google_fonts` 套件 SHALL 成功安裝且可在程式碼中 import

### Requirement: 全站標題字型使用 Playfair Display
ThemeData 的 `textTheme` 中，displayLarge、displayMedium、displaySmall、headlineLarge、headlineMedium SHALL 使用 Playfair Display 字型。

#### Scenario: 首頁區塊標題顯示 Playfair Display
- **WHEN** 使用者造訪首頁
- **THEN** 「季節農產時程」等區塊標題 SHALL 以 Playfair Display 字型渲染

### Requirement: 全站內文字型使用 Inter
ThemeData 的 `textTheme` 中，bodyLarge、bodyMedium、bodySmall、labelLarge、labelMedium、labelSmall SHALL 使用 Inter 字型。

#### Scenario: 品牌故事內文顯示 Inter
- **WHEN** 使用者查看品牌故事區塊的說明文字
- **THEN** 內文 SHALL 以 Inter 字型渲染

### Requirement: 中文回退字型為 Noto Sans TC
ThemeData SHALL 設定 `fontFamilyFallback` 包含 Noto Sans TC，確保中文字元正確顯示。

#### Scenario: 中文字元正確渲染
- **WHEN** 頁面顯示中文內容
- **THEN** 中文字元 SHALL 使用 Noto Sans TC 字型渲染
