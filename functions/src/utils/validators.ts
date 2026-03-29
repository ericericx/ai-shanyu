/**
 * Zod 驗證工具模組
 *
 * 提供共用的 Zod schema 與驗證輔助函式。
 * 所有 Cloud Function 的輸入資料都必須透過 Zod 驗證，
 * 絕不信任客戶端傳入的未驗證資料。
 */

import { z } from "zod";

/**
 * Zod 解析結果的聯合型別
 */
export type ParseResult<T> =
  | { success: true; data: T }
  | { success: false; errors: string[] };

/**
 * 安全解析輸入資料（不拋出例外）
 *
 * @param schema - Zod schema
 * @param input - 待驗證的原始輸入
 * @returns ParseResult：成功時含 data，失敗時含人類可讀的錯誤訊息陣列
 */
export function safeParse<T>(
  schema: z.ZodSchema<T>,
  input: unknown
): ParseResult<T> {
  const result = schema.safeParse(input);
  if (result.success) {
    return { success: true, data: result.data };
  }
  // 將 Zod 錯誤轉為字串陣列，方便回傳給前端
  const errors = result.error.issues.map(
    (issue) => `${issue.path.join(".")}: ${issue.message}`
  );
  return { success: false, errors };
}

// ─── 共用基礎 Schema ─────────────────────────────────────────────────────────

/**
 * Firebase UID：非空字串，最大 128 字元
 */
export const uidSchema = z
  .string()
  .min(1, "UID 不可為空")
  .max(128, "UID 格式錯誤");

/**
 * 電子郵件格式驗證
 */
export const emailSchema = z.string().email("電子郵件格式錯誤");

/**
 * 分頁參數：limit 最大 100，預設 20
 */
export const paginationSchema = z.object({
  limit: z.number().int().min(1).max(100).default(20),
  startAfter: z.string().optional(),
});

/**
 * setAdminClaim callable function 的輸入 schema
 */
export const setAdminClaimInputSchema = z.object({
  uid: uidSchema,
});

export type SetAdminClaimInput = z.infer<typeof setAdminClaimInputSchema>;
