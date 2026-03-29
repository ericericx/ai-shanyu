/**
 * CMS 內容管理型別定義
 *
 * Firestore 結構：
 *   /cms/homepage   — 首頁設定（單一文件，固定 ID）
 *
 * 設計原則：
 * - cms 集合為固定文件（不新增/刪除），只更新現有文件
 * - banners 為陣列，最多建議 5 張（前端輪播效能考量）
 * - 整個 homepage 文件一次性讀取，避免多次往返
 * - 安全規則（T-03）：cms 為公開讀取，僅 admin 可寫
 */

import { Timestamp } from "firebase-admin/firestore";

/**
 * 首頁 Banner 項目
 *
 * sortOrder 控制輪播順序，數字越小越先顯示
 * isActive = false 可暫時隱藏某張 banner，無需刪除
 */
export interface BannerItem {
  id: string; // 唯一識別碼（uuid 或自動產生）
  imageUrl: string; // 圖片 URL（Firebase Storage）
  linkUrl?: string; // 點擊跳轉連結（選填）
  title?: string; // Banner 標題文字（選填，可疊加在圖片上）
  sortOrder: number; // 顯示順序
  isActive: boolean; // false = 暫時隱藏
}

/**
 * 首頁 CMS 設定文件（/cms/homepage）
 *
 * 此為單一文件，不使用集合查詢，直接 getDoc
 */
export interface CmsHomepage {
  banners: BannerItem[]; // 首頁輪播 banner 列表
  brandStoryTitle: string; // 品牌故事標題
  brandStoryContent: string; // 品牌故事正文（富文本）
  brandStoryImageUrl: string; // 品牌故事配圖
  updatedAt: Timestamp;
}
