/**
 * 商品分類型別定義
 *
 * Firestore 結構：
 *   /categories/{categoryId}
 *
 * 查詢模式：
 *   - 前台列表：isActive == true，ORDER BY sortOrder ASC
 *   - 後台管理：不限 isActive，ORDER BY sortOrder ASC
 *
 * 設計原則：
 * - slug 用於 URL routing（e.g. /categories/peach），需保證唯一性
 * - story 為分類故事頁的長文內容，與商品的 description 分開存放
 * - isActive = false 等同軟刪除，不會出現在前台但不實體刪除（稽核需求）
 */

import { Timestamp } from "firebase-admin/firestore";

export interface Category {
  id: string;
  name: string; // e.g. "梨山茶", "水蜜桃"
  slug: string; // e.g. "lishan-tea", "peach"（URL 友善格式）
  description: string; // 簡短描述，用於列表頁卡片
  story: string; // 分類故事頁完整內容（富文本）
  coverImageUrl: string; // 列表頁封面圖
  sortOrder: number; // 全域排序，數字越小越靠前
  isActive: boolean; // false = 軟刪除，前台隱藏
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
