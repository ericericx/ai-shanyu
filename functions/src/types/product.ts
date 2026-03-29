/**
 * 商品相關型別定義
 *
 * Firestore 結構：
 *   /products/{productId}              — 主商品文件
 *   /products/{productId}/variants/{variantId} — 變體子集合
 *
 * 欄位命名與安全規則保持一致（T-03 規則以 status 欄位控制公開/下架）
 */

import { Timestamp } from "firebase-admin/firestore";

/** 商品發布狀態 */
export type ProductStatus = "draft" | "active" | "archived";

/**
 * 商品變體（variants 子集合文件）
 *
 * 設計原則：
 * - 每個商品可有多個變體（規格/重量/包裝形式）
 * - stock 為即時庫存，更新需使用 FieldValue.increment 保持原子性
 * - isPreorder = true 時 estimatedShipDate 必填（前端應驗證）
 */
export interface ProductVariant {
  id: string;
  name: string; // e.g. "上海蜜", "中桃"
  price: number; // TWD，整數（避免浮點誤差）
  comparePrice?: number; // 原價，用於顯示折扣劃線價
  stock: number; // 即時庫存數量
  unit: string; // e.g. "斤", "盒"
  imageUrls: string[]; // 變體商品圖，可為空陣列
  isPreorder: boolean; // 是否為預購商品
  estimatedShipDate?: Timestamp; // 預購預計出貨日（isPreorder=true 時使用）
}

/**
 * 主商品文件（/products/{productId}）
 *
 * 設計原則：
 * - categoryId 反正規化存放，避免每次讀商品都要額外讀分類
 * - growingStart/EndMonth 為季節時間軸，前端用來顯示產季區間圖
 * - scheduledAt 由排程 Function（T-14）讀取，到期後自動將 status 改為 active
 * - 查詢模式：按 categoryId + status + sortOrder 列表；按 status + scheduledAt 排程發布
 */
export interface Product {
  id: string;
  categoryId: string; // 所屬分類 ID，對應 /categories/{categoryId}
  name: string;
  description: string;
  story: string; // 商品故事（富文本，HTML 字串或 Markdown）
  coverImageUrl: string; // 列表頁主圖
  imageUrls: string[]; // 詳情頁輪播圖
  status: ProductStatus; // draft | active | archived
  sortOrder: number; // 分類內排序，數字越小越靠前
  tags: string[]; // 搜尋用標籤，e.g. ["有機", "高山"]
  // 季節時間軸（月份 1–12）
  growingStartMonth: number; // 生長期開始月份
  growingEndMonth: number; // 生長期結束月份
  harvestStartMonth: number; // 採收期開始月份
  harvestEndMonth: number; // 採收期結束月份
  // 上架時間控制
  scheduledAt?: Timestamp; // 預約上架時間（T-14 排程 Function 使用）
  publishedAt?: Timestamp; // 實際發布時間（status 變為 active 時寫入）
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
