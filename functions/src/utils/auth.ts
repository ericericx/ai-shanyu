/**
 * 認證工具模組
 *
 * 提供 Firebase Auth token 驗證與 custom claims 讀取的共用工具。
 * 所有需要認證的 Cloud Function 均應透過此模組驗證身份，
 * 避免在各 function 中重複實作驗證邏輯。
 */

import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

/**
 * 解碼後的 token 資訊（含 custom claims）
 */
export interface DecodedToken extends admin.auth.DecodedIdToken {
  admin?: boolean;
  role?: string;
}

/**
 * 從 Authorization header 中解析並驗證 Bearer token
 *
 * @param authorizationHeader - request.headers.authorization 的值
 * @returns 解碼後的 token（含 custom claims），驗證失敗則回傳 null
 *
 * 安全注意：verifyIdToken 會驗證 token 的簽章與有效期，
 * 不可改用 decodeIdToken（不驗證簽章，僅解碼）。
 */
export async function verifyBearerToken(
  authorizationHeader: string | undefined
): Promise<DecodedToken | null> {
  if (!authorizationHeader || !authorizationHeader.startsWith("Bearer ")) {
    return null;
  }

  const idToken = authorizationHeader.split("Bearer ")[1];
  if (!idToken) {
    return null;
  }

  try {
    const decoded = await admin.auth().verifyIdToken(idToken);
    return decoded as DecodedToken;
  } catch (err) {
    // 記錄驗證失敗，但不暴露 token 內容
    logger.warn("Token 驗證失敗", {
      severity: "WARNING",
      errorCode: (err as admin.FirebaseError).code ?? "unknown",
    });
    return null;
  }
}

/**
 * 從 Firestore 讀取使用者文件（包含角色資訊）
 *
 * @param uid - Firebase Auth UID
 * @returns Firestore 使用者文件資料，不存在則回傳 null
 */
export async function getUserDoc(
  uid: string
): Promise<admin.firestore.DocumentData | null> {
  try {
    const doc = await admin.firestore().collection("users").doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return doc.data() ?? null;
  } catch (err) {
    logger.error("讀取使用者文件失敗", {
      severity: "ERROR",
      uid,
      error: (err as Error).message,
    });
    return null;
  }
}

/**
 * 確認使用者是否擁有 admin custom claim
 *
 * @param token - 已解碼的 token（含 custom claims）
 * @returns true 表示為 admin，否則 false
 */
export function isAdmin(token: DecodedToken): boolean {
  return token.admin === true;
}
