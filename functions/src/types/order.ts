/**
 * 訂單相關型別定義
 *
 * Firestore 結構：
 *   /orders/{orderId}
 *
 * 查詢模式：
 *   - 使用者訂單：userId == uid，ORDER BY createdAt DESC
 *   - 後台管理：status + createdAt 複合查詢（T-03 已建立索引）
 *
 * 安全原則：
 * - orders 文件禁止實體刪除（T-03 規則明確設 delete: false，稽核需求）
 * - 金額欄位（subtotal/shippingFee/total）由後端 Function 計算，不信任前端傳入值
 * - items 為陣列快照，記錄下單當下的商品資訊（商品改價不影響歷史訂單）
 */

import { Timestamp } from "firebase-admin/firestore";

/** 訂單狀態流轉：pending → confirmed → processing → shipped → delivered */
export type OrderStatus =
  | "pending" // 待確認（剛建立，等待後台確認）
  | "confirmed" // 已確認（後台人工確認）
  | "processing" // 備貨中
  | "shipped" // 已出貨（含物流追蹤號）
  | "delivered" // 已送達
  | "cancelled"; // 已取消（終態，不可逆）

/**
 * 訂單明細項目（orders.items 陣列元素）
 *
 * 設計原則：
 * - productName / variantName 為下單當下的快照，避免商品改名後歷史訂單資訊錯亂
 * - isPreorder + estimatedShipDate 複製自商品變體，避免商品更新後影響已成立訂單
 */
export interface OrderItem {
  productId: string;
  variantId: string;
  productName: string; // 下單當下商品名稱快照
  variantName: string; // 下單當下變體名稱快照
  price: number; // 下單當下單價快照（TWD）
  quantity: number;
  isPreorder: boolean;
  estimatedShipDate?: Timestamp; // 預購預計出貨日快照
}

/**
 * 主訂單文件（/orders/{orderId}）
 */
export interface Order {
  id: string;
  userId: string; // 下單使用者 UID（對應 Firebase Auth uid）
  items: OrderItem[]; // 訂單明細（最多 50 項，避免文件過大）
  subtotal: number; // 商品小計（不含運費），TWD
  shippingFee: number; // 運費，TWD
  total: number; // 總金額 = subtotal + shippingFee，TWD
  status: OrderStatus;
  shippingAddress: {
    name: string; // 收件人姓名
    phone: string; // 收件人電話
    address: string; // 詳細地址
    city: string; // 縣市
    postalCode: string; // 郵遞區號
  };
  note?: string; // 買家備註
  createdAt: Timestamp;
  updatedAt: Timestamp;
}
