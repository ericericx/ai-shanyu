# 技術設計：山裕電商系統 v1

> 狀態：待審閱
> 版本：1.0.0
> 日期：2026-03-29

---

## 一、系統架構概覽

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter Web (前端)                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │  使用者端  │  │  CMS後台  │  │  會員中心  │  │  Chat介面  │  │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬──────┘  │
│       └──────────────┴─────────────┴──────────────┘         │
│                       Riverpod State                         │
│                       GoRouter Routes                        │
└─────────────────────┬───────────────────────────────────────┘
                      │  Firebase SDK (Web)
┌─────────────────────▼───────────────────────────────────────┐
│                    Firebase Platform                          │
│  ┌──────────────┐  ┌──────────┐  ┌──────────────────────┐   │
│  │  Firestore   │  │  Auth    │  │  Cloud Storage       │   │
│  │  (Database)  │  │  (OAuth) │  │  (Images/Assets)     │   │
│  └──────────────┘  └──────────┘  └──────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Cloud Functions                                      │    │
│  │  - scheduledPublish (Cloud Scheduler)                 │    │
│  │  - onOrderCreated (Firestore trigger)                 │    │
│  └──────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## 二、前端架構設計（Flutter Web）

### 2.1 專案結構

```
lib/
├── main.dart
├── main_development.dart       # development flavor entry
├── main_production.dart        # production flavor entry
├── app/
│   ├── app.dart                # MaterialApp + GoRouter 設定
│   └── router/
│       └── app_router.dart     # 路由定義
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── breakpoints.dart    # 響應式斷點
│   ├── extensions/
│   └── utils/
│       └── date_utils.dart     # 季節計算邏輯
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── domain/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── login_page.dart
│   │       └── auth_controller.dart  # Riverpod provider
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── home_page.dart
│   │   │   ├── banner_widget.dart
│   │   │   ├── brand_story_widget.dart
│   │   │   └── product_timeline_widget.dart
│   ├── products/
│   │   ├── data/
│   │   │   └── products_repository.dart
│   │   ├── domain/
│   │   │   ├── product_model.dart
│   │   │   └── category_model.dart
│   │   └── presentation/
│   │       ├── product_list_page.dart
│   │       ├── product_detail_page.dart
│   │       └── products_controller.dart
│   ├── cart/
│   │   ├── data/
│   │   │   └── cart_repository.dart
│   │   ├── domain/
│   │   │   └── cart_model.dart
│   │   └── presentation/
│   │       ├── cart_panel.dart
│   │       └── cart_controller.dart
│   ├── orders/
│   │   ├── data/
│   │   │   └── orders_repository.dart
│   │   ├── domain/
│   │   │   └── order_model.dart
│   │   └── presentation/
│   │       ├── checkout_page.dart
│   │       ├── order_confirmation_page.dart
│   │       └── orders_controller.dart
│   ├── member/
│   │   └── presentation/
│   │       └── member_center_page.dart
│   ├── chat/
│   │   ├── data/
│   │   │   └── chat_repository.dart
│   │   ├── domain/
│   │   │   └── chat_model.dart
│   │   └── presentation/
│   │       ├── chat_widget.dart
│   │       └── chat_controller.dart
│   └── admin/
│       ├── cms/
│       │   └── presentation/
│       │       ├── cms_banner_page.dart
│       │       └── cms_brand_story_page.dart
│       ├── products/
│       │   └── presentation/
│       │       ├── admin_products_page.dart
│       │       └── admin_product_form_page.dart
│       ├── categories/
│       │   └── presentation/
│       │       └── admin_categories_page.dart
│       ├── orders/
│       │   └── presentation/
│       │       └── admin_orders_page.dart
│       ├── crm/
│       │   └── presentation/
│       │       └── admin_crm_page.dart
│       └── chat/
│           └── presentation/
│               └── admin_chat_page.dart
└── shared/
    ├── widgets/
    │   ├── nav_bar.dart
    │   ├── responsive_layout.dart
    │   └── loading_widget.dart
    └── providers/
        └── firebase_providers.dart
```

### 2.2 路由設計（GoRouter）

| 路徑 | 頁面 | 保護 |
|------|------|------|
| `/` | 首頁 | 無 |
| `/login` | 登入頁 | 無（已登入導向 /） |
| `/products/:categoryId` | 商品分類頁 | 無 |
| `/products/:categoryId/:productId` | 商品詳情頁 | 無 |
| `/checkout` | 結帳頁 | 需登入 |
| `/order-confirmation/:orderId` | 訂單確認頁 | 需登入 |
| `/member` | 會員中心 | 需登入 |
| `/admin` | 後台首頁 | 需 admin role |
| `/admin/cms` | CMS 管理 | 需 admin role |
| `/admin/products` | 商品管理 | 需 admin role |
| `/admin/categories` | 分類管理 | 需 admin role |
| `/admin/orders` | 訂單管理 | 需 admin role |
| `/admin/crm` | 行為追蹤 | 需 admin role |
| `/admin/chat` | 客服 Chat | 需 admin role |

### 2.3 響應式斷點

```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}
```

### 2.4 Riverpod Provider 設計

```dart
// 認證狀態
final authStateProvider = StreamProvider<User?>

// 當前用戶資料
final userProvider = StreamProvider.autoDispose<UserModel?>

// 購物車
final cartProvider = StreamProvider.autoDispose<CartModel?>

// 商品列表（依分類）
final productsProvider = StreamProvider.autoDispose.family<List<ProductModel>, String>

// CMS 內容
final bannersProvider = StreamProvider.autoDispose<List<BannerItem>>
final brandStoryProvider = StreamProvider.autoDispose<BrandStory>

// 季節流水線商品（有 season 欄位的商品）
final timelineProductsProvider = FutureProvider<List<ProductModel>>

// Chat（用戶端）
final userChatProvider = StreamProvider.autoDispose<ChatModel?>
```

---

## 三、後端架構設計（Firebase）

### 3.1 Firestore 資料模型（完整定義）

#### Collection: users
```typescript
interface UserDocument {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  provider: 'google' | 'email';
  isAdmin: boolean;  // 冗餘欄位，Custom Claims 為主
  socialBindings: {
    line?: string;    // Line User ID（預留）
    facebook?: string; // Facebook User ID（預留）
  };
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### Collection: categories
```typescript
interface CategoryDocument {
  id: string;
  name: string;           // e.g. "梨山茶"
  description: string;
  coverImage: string;     // Firebase Storage URL
  sortOrder: number;      // 數字越小越靠前
  isVisible: boolean;
  subcategories: string[]; // e.g. ["春茶", "秋茶", "冬茶", "茶包"]
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### Collection: products
```typescript
interface ProductDocument {
  id: string;
  name: string;
  description: string;
  categoryId: string;
  subcategory: string;
  price: number;
  preorderPrice?: number;
  isPreorder: boolean;
  estimatedShipDate?: Timestamp;
  scheduledPublishAt?: Timestamp;  // null 表示立即上架
  isPublished: boolean;
  stock?: number;                  // null 表示不限庫存
  images: string[];                // Firebase Storage URLs
  season: {
    growthStart: number;   // 1-12 月份
    growthEnd: number;
    harvestStart: number;
    harvestEnd: number;
  };
  sortOrder: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
```

#### Collection: orders
```typescript
interface OrderDocument {
  id: string;
  userId: string;
  userEmail: string;
  items: OrderItem[];
  shippingInfo: {
    name: string;
    phone: string;
    address: string;
    note?: string;
  };
  normalItemsTotal: number;
  preorderItemsTotal: number;
  totalAmount: number;
  status: 'pending' | 'confirmed' | 'shipped' | 'delivered' | 'cancelled';
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface OrderItem {
  productId: string;
  productName: string;
  price: number;
  qty: number;
  isPreorder: boolean;
  estimatedShipDate?: Timestamp;
}
```

#### Collection: carts
```typescript
interface CartDocument {
  userId: string;
  items: CartItem[];
  updatedAt: Timestamp;
}

interface CartItem {
  productId: string;
  productName: string;
  productImage: string;
  price: number;
  qty: number;
  isPreorder: boolean;
  estimatedShipDate?: Timestamp;
}
```

#### Collection: cms
```typescript
// /cms/banners
interface BannersDocument {
  items: BannerItem[];
  updatedAt: Timestamp;
  updatedBy: string;
}

interface BannerItem {
  id: string;
  imageUrl: string;
  linkUrl?: string;
  sortOrder: number;
  isVisible: boolean;
}

// /cms/brand-story
interface BrandStoryDocument {
  title: string;
  content: string;  // HTML string
  imageUrl?: string;
  updatedAt: Timestamp;
  updatedBy: string;
}

// /cms/assets
interface AssetsDocument {
  logoUrl: string;
  backgroundImages: {
    home?: string;
    product?: string;
  };
  updatedAt: Timestamp;
  updatedBy: string;
}
```

#### Collection: chats / messages subcollection
```typescript
interface ChatDocument {
  id: string;
  userId: string;
  userName: string;
  status: 'open' | 'closed';
  lastMessage: string;
  lastMessageAt: Timestamp;
  unreadByAdmin: number;
  unreadByUser: number;
  createdAt: Timestamp;
}

interface MessageDocument {
  id: string;
  senderId: string;
  senderName: string;
  senderRole: 'user' | 'admin';
  content: string;
  timestamp: Timestamp;
  isRead: boolean;
}
```

#### Collection: behaviors
```typescript
interface BehaviorDocument {
  id: string;
  userId: string;        // 已登入用戶 ID 或 'anon_{sessionId}'
  productId: string;
  productName: string;
  type: 'view';
  timestamp: Timestamp;
  date: string;          // 'YYYY-MM-DD'，用於去重
}
```

### 3.2 Firestore 安全規則設計

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // 輔助函數
    function isAuthenticated() {
      return request.auth != null;
    }

    function isAdmin() {
      return isAuthenticated() &&
             request.auth.token.admin == true;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) || isAdmin();
    }

    // products collection（前台只讀已上架商品）
    match /products/{productId} {
      allow read: if resource.data.isPublished == true || isAdmin();
      allow write: if isAdmin();
    }

    // categories collection
    match /categories/{categoryId} {
      allow read: if resource.data.isVisible == true || isAdmin();
      allow write: if isAdmin();
    }

    // orders collection
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid;
      allow update: if isAdmin();
    }

    // carts collection（只有本人可讀寫）
    match /carts/{userId} {
      allow read, write: if isOwner(userId);
    }

    // cms collection（前台只讀，後台可寫）
    match /cms/{docId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // chats collection
    match /chats/{chatId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow create: if isAuthenticated() &&
                       request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId) || isAdmin();

      match /messages/{messageId} {
        allow read: if isOwner(get(/databases/$(database)/documents/chats/$(chatId)).data.userId) || isAdmin();
        allow create: if isAuthenticated();
      }
    }

    // behaviors（只能新增，不能修改）
    match /behaviors/{behaviorId} {
      allow create: if true;  // 允許匿名記錄
      allow read: if isAdmin();
    }
  }
}
```

### 3.3 Firestore Indexes

```json
{
  "indexes": [
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryId", "order": "ASCENDING" },
        { "fieldPath": "isPublished", "order": "ASCENDING" },
        { "fieldPath": "sortOrder", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "isPublished", "order": "ASCENDING" },
        { "fieldPath": "season.harvestStart", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "orders",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "behaviors",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "productId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "behaviors",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "productId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "chats",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "lastMessageAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### 3.4 Cloud Functions 設計

#### Function 1：scheduledPublishProducts
```typescript
// 觸發方式：Cloud Scheduler，每 5 分鐘執行一次
// 功能：查詢 scheduledPublishAt <= now 且 isPublished = false 的商品，批次設定 isPublished = true

export const scheduledPublishProducts = functions.pubsub
  .schedule('every 5 minutes')
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const snapshot = await admin.firestore()
      .collection('products')
      .where('isPublished', '==', false)
      .where('scheduledPublishAt', '<=', now)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => {
      batch.update(doc.ref, { isPublished: true, updatedAt: now });
    });
    await batch.commit();
  });
```

#### Function 2：onOrderCreated
```typescript
// 觸發方式：Firestore trigger，/orders/{orderId} 新增時觸發
// 功能：發送訂單確認通知（此版本僅 log，預留通知邏輯）

export const onOrderCreated = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snap, context) => {
    const order = snap.data();
    // TODO: 發送 Email / Line 通知（Sprint 3 實作）
    functions.logger.info('新訂單建立', {
      orderId: context.params.orderId,
      userId: order.userId,
      totalAmount: order.totalAmount
    });
  });
```

### 3.5 Firebase Storage 結構

```
/banners/{filename}          # Banner 圖片
/products/{productId}/{filename}  # 商品圖片
/categories/{categoryId}/{filename}  # 分類封面圖
/brand-story/{filename}      # 品牌故事圖片
/assets/logo/{filename}      # Logo
/assets/backgrounds/{page}/{filename}  # 背景圖
```

### 3.6 Firebase Authentication 設定

- 啟用 Google Sign-In Provider
- 啟用 Email/Password Provider
- Admin Custom Claims 設定方式：透過 Firebase Admin SDK 手動設定（`admin.auth().setCustomUserClaims(uid, { admin: true })`）
- 未來可在後台提供 UI 設定 admin 帳號

---

## 四、Product Timeline 算法設計

```dart
enum ProductSeasonStatus {
  canPreorder,    // 可預購：生長期中，未到採收期
  harvesting,     // 採購中：採收期中
  comingSoon,     // 即將上架：距採收期 < 1 個月
  seasonEnded,    // 季節結束：採收期已過
}

ProductSeasonStatus getSeasonStatus(ProductSeason season, DateTime now) {
  final currentMonth = now.month;

  // 判斷是否在採收期
  if (isMonthInRange(currentMonth, season.harvestStart, season.harvestEnd)) {
    return ProductSeasonStatus.harvesting;
  }

  // 判斷是否即將進入採收期（< 1 個月）
  final monthsUntilHarvest = monthDiff(currentMonth, season.harvestStart);
  if (monthsUntilHarvest <= 1 && monthsUntilHarvest > 0) {
    return ProductSeasonStatus.comingSoon;
  }

  // 判斷是否在生長期
  if (isMonthInRange(currentMonth, season.growthStart, season.growthEnd)) {
    return ProductSeasonStatus.canPreorder;
  }

  return ProductSeasonStatus.seasonEnded;
}

// 跨年處理（e.g. 生長期 11月 ~ 2月）
bool isMonthInRange(int month, int start, int end) {
  if (start <= end) {
    return month >= start && month <= end;
  } else {
    // 跨年
    return month >= start || month <= end;
  }
}
```

---

## 五、前端關鍵 UI 元件規格

### 5.1 NavBar
- 左側：Logo（點擊回首頁）
- 右側：購物車 icon（badge 顯示商品數）、登入按鈕 / 用戶頭像
- 桌面版：完整導覽選單
- 手機版：漢堡選單（Drawer）

### 5.2 BannerWidget
- 使用 `PageView.builder` 實作輪播
- `Timer.periodic` 控制自動播放（每 4 秒）
- 底部 dot indicators

### 5.3 ProductTimelineWidget
- 使用 `CustomPainter` 繪製時間軸
- 或使用 `Row` + `Container` 實作進度條
- 月份軸使用 `SingleChildScrollView` 橫向捲動（手機版）

### 5.4 CartPanel
- 使用 `Scaffold.endDrawer` 或 `Overlay` 實作右側滑入面板
- 分組顯示：一般商品 / 預購商品

---

## 六、環境設定

### 6.1 Flutter Flavor 設定

```dart
// lib/main_development.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,  // google-services (dev)
  );
  runApp(const ProviderScope(child: App()));
}
```

### 6.2 環境檔案
- `lib/firebase_options_development.dart` — development Firebase 設定
- `lib/firebase_options_production.dart` — production Firebase 設定（部署時使用）

---

## 七、依賴套件清單（pubspec.yaml）

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Firebase
  firebase_core: ^3.x.x
  firebase_auth: ^5.x.x
  cloud_firestore: ^5.x.x
  firebase_storage: ^12.x.x
  cloud_functions: ^5.x.x

  # State Management
  flutter_riverpod: ^2.x.x
  riverpod_annotation: ^2.x.x

  # Routing
  go_router: ^14.x.x

  # UI
  cached_network_image: ^3.x.x
  flutter_html: ^3.x.x        # 品牌故事 HTML 內容渲染
  image_picker: ^1.x.x
  file_picker: ^8.x.x

  # Utility
  intl: ^0.19.x
  uuid: ^4.x.x
  equatable: ^2.x.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.x.x
  build_runner: ^2.x.x
  flutter_lints: ^4.x.x
```

---

## 八、Cloud Functions 依賴（package.json）

```json
{
  "dependencies": {
    "firebase-admin": "^12.x.x",
    "firebase-functions": "^6.x.x"
  },
  "engines": {
    "node": "18"
  }
}
```
