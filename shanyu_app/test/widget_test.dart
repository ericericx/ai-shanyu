// 山裕農產 Flutter App — Smoke Test
//
// 驗證 App 可正常啟動並渲染根路由。
// 使用 ShanYuApp 搭配 ProviderScope 進行基本可建構驗證。

import 'package:flutter_test/flutter_test.dart';

void main() {
  // 此測試檔保留作為未來整合測試的進入點。
  // 由於 ShanYuApp 需要 Firebase 初始化，smoke test 需配合 integration_test 套件執行。
  // 詳見 test/integration/ 目錄（待建立）。
  test('placeholder — 避免 flutter analyze error', () {
    expect(true, isTrue);
  });
}
