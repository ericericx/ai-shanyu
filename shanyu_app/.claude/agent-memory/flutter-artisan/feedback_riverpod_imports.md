---
name: Riverpod Provider 檔案必須雙 import
description: provider 檔案同時需要 flutter_riverpod 和 riverpod_annotation，否則 Ref 編譯錯誤
type: feedback
---

每個使用 `@riverpod` / `@Riverpod` annotation 的 provider 檔案，**必須同時 import** 以下兩個套件：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
```

**Why:** `Ref` 型別定義在 `flutter_riverpod`，不在 `riverpod_annotation`。缺少 `flutter_riverpod` import 時，dart2js 在 release build 時會報 `Type 'Ref' not found`，debug build 下可能因 IDE 補全而不明顯。cms_providers.dart 就因少了這個 import 導致 web release 編譯失敗。

**How to apply:** 每次新增 provider 檔案，先確認兩行 import 都存在，再寫 provider function。
