/**
 * HTTP Response 格式化工具
 *
 * 統一所有 Cloud Function 的回應結構，確保前端可預期的 API 形狀。
 * 所有 onRequest function 均應使用此模組回傳資料，不可直接呼叫 res.json()。
 *
 * 成功回應：{ success: true, data: T }
 * 錯誤回應：{ success: false, error: { code: string, message: string } }
 */

import { Response } from "express";

/**
 * 成功回應的資料結構
 */
export interface SuccessResponse<T = unknown> {
  success: true;
  data: T;
}

/**
 * 錯誤回應的資料結構
 */
export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
  };
}

/**
 * 回傳標準成功回應
 *
 * @param res - Express Response 物件
 * @param data - 回傳給客戶端的資料
 * @param statusCode - HTTP 狀態碼，預設 200
 */
export function sendSuccess<T = unknown>(
  res: Response,
  data: T,
  statusCode = 200
): void {
  const body: SuccessResponse<T> = { success: true, data };
  res.status(statusCode).json(body);
}

/**
 * 回傳標準錯誤回應
 *
 * @param res - Express Response 物件
 * @param statusCode - HTTP 狀態碼（400、401、403、404、500 等）
 * @param code - 機器可讀的錯誤代碼（例如 "UNAUTHORIZED"、"INVALID_INPUT"）
 * @param message - 人類可讀的錯誤說明（不可包含敏感資訊）
 */
export function sendError(
  res: Response,
  statusCode: number,
  code: string,
  message: string
): void {
  const body: ErrorResponse = {
    success: false,
    error: { code, message },
  };
  res.status(statusCode).json(body);
}

/**
 * 常用錯誤的快捷函式
 */

export const sendUnauthorized = (res: Response): void =>
  sendError(res, 401, "UNAUTHORIZED", "請先登入");

export const sendForbidden = (res: Response): void =>
  sendError(res, 403, "FORBIDDEN", "權限不足");

export const sendNotFound = (res: Response, resource = "資源"): void =>
  sendError(res, 404, "NOT_FOUND", `${resource}不存在`);

export const sendBadRequest = (res: Response, message: string): void =>
  sendError(res, 400, "BAD_REQUEST", message);

export const sendInternalError = (res: Response): void =>
  sendError(res, 500, "INTERNAL_ERROR", "系統發生錯誤，請稍後再試");
