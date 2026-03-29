/**
 * Firestore Seed Data 腳本
 *
 * 用途：為山裕電商系統建立初始分類、商品與 CMS 首頁資料
 *
 * 執行方式：
 *   cd functions
 *   npx ts-node src/scripts/seed.ts
 *
 * 前置條件：
 *   - 已設定 GOOGLE_APPLICATION_CREDENTIALS 環境變數，或已執行
 *     `gcloud auth application-default login`
 *   - FIRESTORE_PROJECT_ID 環境變數指定目標專案（預設：shayu-staging）
 *
 * 冪等性：
 *   - 已存在的文件不會被覆蓋（使用 create 語意 + skipIfExists 邏輯）
 *   - 重複執行安全，不會建立重複資料
 *
 * 安全原則：
 *   - 不硬編碼任何憑證或金鑰
 *   - 使用 Admin SDK ADC（Application Default Credentials）
 */

import * as admin from "firebase-admin";
import { Firestore, Timestamp } from "firebase-admin/firestore";

// ─── 初始化 ────────────────────────────────────────────────────────────────────

const projectId = process.env.FIRESTORE_PROJECT_ID ?? "shayu-staging";

admin.initializeApp({ projectId });

const db: Firestore = admin.firestore();

// ─── 型別（本地 seed 用，避免與主型別產生循環相依）──────────────────────────────

interface SeedCategory {
  id: string;
  name: string;
  slug: string;
  description: string;
  story: string;
  coverImageUrl: string;
  sortOrder: number;
  isActive: boolean;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

interface SeedProductVariant {
  id: string;
  name: string;
  price: number;
  comparePrice?: number;
  stock: number;
  unit: string;
  imageUrls: string[];
  isPreorder: boolean;
  estimatedShipDate?: Timestamp;
}

interface SeedProduct {
  id: string;
  categoryId: string;
  name: string;
  description: string;
  story: string;
  coverImageUrl: string;
  imageUrls: string[];
  status: "draft" | "active" | "archived";
  sortOrder: number;
  tags: string[];
  growingStartMonth: number;
  growingEndMonth: number;
  harvestStartMonth: number;
  harvestEndMonth: number;
  scheduledAt?: Timestamp;
  publishedAt?: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  variants: SeedProductVariant[];
}

interface SeedCmsHomepage {
  banners: never[]; // 初始為空，待後台上傳
  brandStoryTitle: string;
  brandStoryContent: string;
  brandStoryImageUrl: string;
  updatedAt: Timestamp;
}

// ─── Seed 資料定義 ─────────────────────────────────────────────────────────────

const NOW = Timestamp.now();

/** 分類資料 */
const CATEGORIES: SeedCategory[] = [
  {
    id: "lishan-tea",
    name: "梨山茶",
    slug: "lishan-tea",
    description: "來自台灣梨山高山茶區，海拔 2000 公尺以上的精品茶葉。",
    story:
      "梨山位於台中市和平區，海拔 2000 至 2600 公尺，雲霧繚繞、日夜溫差大，" +
      "造就了茶葉緩慢生長、滋味醇厚的絕佳條件。山裕的梨山茶由在地農民手工採摘，" +
      "每一片茶葉都承載著這片土地的故事。",
    coverImageUrl: "",
    sortOrder: 1,
    isActive: true,
    createdAt: NOW,
    updatedAt: NOW,
  },
  {
    id: "peach",
    name: "水蜜桃",
    slug: "peach",
    description: "梨山高山水蜜桃，果肉細緻、香甜多汁，夏季限定珍品。",
    story:
      "梨山的水蜜桃因高山冷涼氣候，生長期長達三個月，糖度自然積累，" +
      "造就了果肉如絲綢般細緻、香氣飽滿的頂級風味。山裕嚴選在地農戶，" +
      "確保每顆水蜜桃都在最佳熟度採收直送。",
    coverImageUrl: "",
    sortOrder: 2,
    isActive: true,
    createdAt: NOW,
    updatedAt: NOW,
  },
  {
    id: "pear",
    name: "梨子",
    slug: "pear",
    description: "梨山高山梨，清甜爽脆，秋季豐收的山中饋禮。",
    story:
      "梨山的梨子在涼爽山風與充沛日照的雙重滋養下，果肉緊實、水分豐沛，" +
      "入口清脆甘甜，帶著高山的清新氣息。山裕與世代農家合作，" +
      "以傳統農法守護這份山的禮物。",
    coverImageUrl: "",
    sortOrder: 3,
    isActive: true,
    createdAt: NOW,
    updatedAt: NOW,
  },
];

/** 商品資料（含 variants，variants 寫入子集合） */
const PRODUCTS: SeedProduct[] = [
  // ── 梨山茶 ──────────────────────────────────────────────────────────────────
  {
    id: "lishan-tea-spring",
    categoryId: "lishan-tea",
    name: "梨山春茶",
    description: "春季第一批嫩芽採製，茶湯清澈黃綠，花香明顯，回甘持久。",
    story:
      "每年清明前後，梨山茶區迎來一年中最珍貴的春茶季。嫩芽在冬眠後首次甦醒，" +
      "積累了整個冬季的養分，滋味最為鮮活甘甜。山裕春茶採一芯二葉，" +
      "當日採摘當日製作，鎖住最新鮮的山林氣息。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 1,
    tags: ["春茶", "高山茶", "梨山", "烏龍"],
    growingStartMonth: 3,
    growingEndMonth: 4,
    harvestStartMonth: 4,
    harvestEndMonth: 5,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "lishan-tea-spring-75g",
        name: "春茶 75g",
        price: 1200,
        comparePrice: 1500,
        stock: 50,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "lishan-tea-spring-150g",
        name: "春茶 150g",
        price: 2200,
        comparePrice: 2800,
        stock: 30,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },
  {
    id: "lishan-tea-winter",
    categoryId: "lishan-tea",
    name: "梨山冬茶",
    description: "秋冬之交採製，茶湯蜜黃透亮，蜜香濃郁，滋味醇厚耐泡。",
    story:
      "冬茶生長於晝短夜長的低溫季節，生長速度緩慢，養分高度濃縮。" +
      "梨山冬茶以蜜香著稱，茶湯入口後甘甜在喉間久久不散，" +
      "是許多老茶客心中最難忘的梨山記憶。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 2,
    tags: ["冬茶", "高山茶", "梨山", "蜜香"],
    growingStartMonth: 10,
    growingEndMonth: 11,
    harvestStartMonth: 11,
    harvestEndMonth: 12,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "lishan-tea-winter-75g",
        name: "冬茶 75g",
        price: 1400,
        comparePrice: 1800,
        stock: 40,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "lishan-tea-winter-150g",
        name: "冬茶 150g",
        price: 2600,
        comparePrice: 3200,
        stock: 20,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },

  // ── 水蜜桃 ──────────────────────────────────────────────────────────────────
  {
    id: "peach-shanghai-honey",
    categoryId: "peach",
    name: "上海蜜水蜜桃",
    description: "梨山最受歡迎的品種，果大皮薄、蜜汁豐沛，入口即化。",
    story:
      "上海蜜是梨山最具代表性的水蜜桃品種，因果實飽滿、甜度極高而得名。" +
      "每年六月下旬起限量採收，由農民逐顆手工套袋保護，確保果皮完整、色澤均勻。" +
      "山裕嚴格把關糖度，低於標準的果實一律不出貨。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 1,
    tags: ["水蜜桃", "上海蜜", "高山", "夏季限定"],
    growingStartMonth: 4,
    growingEndMonth: 6,
    harvestStartMonth: 6,
    harvestEndMonth: 7,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "peach-shanghai-honey-6pcs",
        name: "上海蜜 6顆裝",
        price: 680,
        stock: 100,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "peach-shanghai-honey-12pcs",
        name: "上海蜜 12顆裝",
        price: 1280,
        stock: 60,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },
  {
    id: "peach-medium",
    categoryId: "peach",
    name: "中桃水蜜桃",
    description: "果肉緊實、酸甜平衡，適合全家享用的經典梨山水蜜桃。",
    story:
      "中桃是梨山農民種植歷史最長的品種，果肉緊實不易損傷，" +
      "更適合常溫運送。相較於上海蜜的嬌貴，中桃以穩定的品質和親民的價格，" +
      "成為許多家庭每年夏天必訂的果品。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 2,
    tags: ["水蜜桃", "中桃", "高山", "夏季"],
    growingStartMonth: 5,
    growingEndMonth: 7,
    harvestStartMonth: 7,
    harvestEndMonth: 8,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "peach-medium-6pcs",
        name: "中桃 6顆裝",
        price: 480,
        stock: 150,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "peach-medium-12pcs",
        name: "中桃 12顆裝",
        price: 880,
        stock: 80,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },

  // ── 梨子 ────────────────────────────────────────────────────────────────────
  {
    id: "pear-new-century",
    categoryId: "pear",
    name: "新世紀梨",
    description: "果大汁多、甜度高，外皮金黃光滑，梨山最受歡迎的夏末秋初品種。",
    story:
      "新世紀梨原產自日本，引進梨山後因得天獨厚的高山氣候，" +
      "品質遠超平地栽培。果肉細緻多汁，咬下去清脆的聲音令人愉悅，" +
      "甜度可達 13 度以上。山裕嚴選每顆重量 500g 以上的大果，" +
      "是送禮自用兩相宜的首選。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 1,
    tags: ["梨子", "新世紀梨", "高山", "秋季"],
    growingStartMonth: 5,
    growingEndMonth: 7,
    harvestStartMonth: 7,
    harvestEndMonth: 9,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "pear-new-century-5pcs",
        name: "新世紀梨 5顆裝",
        price: 580,
        stock: 80,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "pear-new-century-10pcs",
        name: "新世紀梨 10顆裝",
        price: 1080,
        stock: 40,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },
  {
    id: "pear-snow",
    categoryId: "pear",
    name: "雪梨",
    description: "果肉雪白細嫩、水分充足，滋潤爽口，秋季養生首選。",
    story:
      "梨山雪梨果形端正、果皮薄脆，果肉幾乎沒有粗纖維，" +
      "入口即化的細緻感令人難忘。傳統上雪梨常用於煮湯、燉補，" +
      "但直接生食的清甜同樣讓人難以抗拒。山裕的雪梨採收於秋高氣爽的八九月，" +
      "是一整年辛勞後大地給的最甜回報。",
    coverImageUrl: "",
    imageUrls: [],
    status: "active",
    sortOrder: 2,
    tags: ["梨子", "雪梨", "高山", "秋季", "養生"],
    growingStartMonth: 6,
    growingEndMonth: 8,
    harvestStartMonth: 8,
    harvestEndMonth: 10,
    createdAt: NOW,
    updatedAt: NOW,
    variants: [
      {
        id: "pear-snow-5pcs",
        name: "雪梨 5顆裝",
        price: 520,
        stock: 100,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
      {
        id: "pear-snow-10pcs",
        name: "雪梨 10顆裝",
        price: 980,
        stock: 50,
        unit: "盒",
        imageUrls: [],
        isPreorder: false,
      },
    ],
  },
];

/** CMS 首頁初始資料 */
const CMS_HOMEPAGE: SeedCmsHomepage = {
  banners: [], // 待後台上傳圖片後更新
  brandStoryTitle: "來自梨山的誠意",
  brandStoryContent:
    "山裕農產成立於 2010 年，深耕台中梨山農業產區超過十年。\n\n" +
    "我們相信，最好的農產品來自於對土地的尊重與對農民的信任。" +
    "梨山海拔 2000 公尺以上的純淨環境，日夜溫差超過 15 度的自然條件，" +
    "賦予了這裡的茶葉、水果無可取代的風味。\n\n" +
    "山裕直接與在地農家合作，跳過層層中盤，讓消費者以合理的價格，" +
    "品嚐到最新鮮、最真實的梨山味道。每一筆訂單，都是城市與山林之間最直接的連結。",
  brandStoryImageUrl: "",
  updatedAt: NOW,
};

// ─── 輔助函式 ──────────────────────────────────────────────────────────────────

/**
 * 檢查文件是否已存在，若不存在才寫入（冪等）
 * 回傳 true = 新建立，false = 已存在跳過
 */
async function writeIfNotExists(
  ref: FirebaseFirestore.DocumentReference,
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  data: Record<string, any>
): Promise<boolean> {
  const snap = await ref.get();
  if (snap.exists) {
    console.log(`  [跳過] ${ref.path} 已存在`);
    return false;
  }
  await ref.set(data);
  console.log(`  [建立] ${ref.path}`);
  return true;
}

// ─── 主要 Seed 邏輯 ────────────────────────────────────────────────────────────

async function seedCategories(): Promise<number> {
  console.log("\n== 分類（categories）==");
  let created = 0;
  for (const cat of CATEGORIES) {
    const { id, ...data } = cat;
    const ref = db.collection("categories").doc(id);
    const isNew = await writeIfNotExists(ref, data);
    if (isNew) created++;
  }
  return created;
}

async function seedProducts(): Promise<{ products: number; variants: number }> {
  console.log("\n== 商品（products）+ 變體（variants）==");
  let productCount = 0;
  let variantCount = 0;

  for (const product of PRODUCTS) {
    const { id, variants, ...productData } = product;
    const productRef = db.collection("products").doc(id);
    const isNew = await writeIfNotExists(productRef, productData);
    if (isNew) productCount++;

    // 變體寫入子集合，每個變體獨立判斷冪等
    for (const variant of variants) {
      const { id: variantId, ...variantData } = variant;
      const variantRef = productRef.collection("variants").doc(variantId);
      const variantIsNew = await writeIfNotExists(variantRef, variantData);
      if (variantIsNew) variantCount++;
    }
  }

  return { products: productCount, variants: variantCount };
}

async function seedCms(): Promise<number> {
  console.log("\n== CMS（cms/homepage）==");
  const ref = db.collection("cms").doc("homepage");
  const isNew = await writeIfNotExists(ref, CMS_HOMEPAGE);
  return isNew ? 1 : 0;
}

async function checkFirestoreConnection(): Promise<void> {
  // 簡單的連線測試：列出 categories 集合（最多 1 筆）
  await db.collection("categories").limit(1).get();
}

async function main(): Promise<void> {
  console.log(`山裕電商系統 Firestore Seed 腳本`);
  console.log(`目標專案：${projectId}`);
  console.log(`執行時間：${new Date().toISOString()}`);
  console.log("─".repeat(50));

  // 連線驗證
  console.log("\n連線驗證中...");
  try {
    await checkFirestoreConnection();
    console.log("Firestore 連線成功");
  } catch (err) {
    console.error("Firestore 連線失敗，請確認憑證設定：", err);
    process.exit(1);
  }

  // 執行 seed
  const categoryCount = await seedCategories();
  const { products: productCount, variants: variantCount } =
    await seedProducts();
  const cmsCount = await seedCms();

  // 結果摘要
  console.log("\n" + "─".repeat(50));
  console.log("Seed 完成，結果摘要：");
  console.log(`  分類（categories）：新建 ${categoryCount} 筆`);
  console.log(`  商品（products）  ：新建 ${productCount} 筆`);
  console.log(`  變體（variants）  ：新建 ${variantCount} 筆`);
  console.log(`  CMS 首頁          ：新建 ${cmsCount} 筆`);
  console.log(
    `  合計              ：${categoryCount + productCount + variantCount + cmsCount} 筆文件`
  );

  process.exit(0);
}

main().catch((err) => {
  console.error("Seed 執行失敗：", err);
  process.exit(1);
});
