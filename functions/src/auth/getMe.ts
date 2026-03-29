/**
 * Callable Function：取得當前登入使用者的完整資料
 *
 * 用途：客戶端登入後取得 Firestore 使用者文件與 custom claims（如 admin 旗標）
 * 觸發方式：Flutter/Web 客戶端透過 Firebase Callable SDK 呼叫
 *
 * 安全設計：
 *   - 只回傳呼叫者自己的資料（request.auth.uid），不接受任何 uid 參數
 *   - 防止使用者 A 查詢使用者 B 的資料
 *   - custom claims 直接從已驗證的 token 讀取，不需要額外 Admin SDK 呼叫
 *
 * 回傳結構：
 *   {
 *     uid: string
 *     email: string
 *     displayName: string | null
 *     photoURL: string | null
 *     role: string
 *     createdAt: Timestamp（序列化為 { _seconds, _nanoseconds }）
 *     updatedAt: Timestamp
 *     lineLinked: boolean
 *     facebookLinked: boolean
 *     claims: {
 *       admin: boolean
 *     }
 *   }
 *
 * 失敗模式：
 *   - 呼叫者未登入 → unauthenticated
 *   - Firestore 文件不存在（onUserCreated 尚未執行完成） → not-found
 */

import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

/** getMe 回傳的資料結構（客戶端可用於型別推斷） */
interface GetMeResponse {
  uid: string;
  email: string;
  displayName: string | null;
  photoURL: string | null;
  role: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  lineLinked: boolean;
  facebookLinked: boolean;
  /** 從 ID Token custom claims 讀取的權限旗標 */
  claims: {
    admin: boolean;
  };
}

export const getMe = onCall(
  { region: "asia-east1" },
  async (request): Promise<GetMeResponse> => {
    // ── 1. 認證檢查：必須已登入 ──────────────────────────────────────────────
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "請先登入");
    }

    const { uid, token } = request.auth;

    // ── 2. 從 Firestore 讀取使用者文件 ──────────────────────────────────────
    let userDoc: admin.firestore.DocumentData;
    try {
      const snapshot = await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .get();

      if (!snapshot.exists) {
        // 可能發生在：Auth trigger 尚未完成（極低概率），或使用者文件被意外刪除
        logger.warn("getMe：使用者文件不存在", {
          severity: "WARNING",
          uid,
        });
        throw new HttpsError(
          "not-found",
          "使用者資料尚未建立，請稍後再試"
        );
      }

      userDoc = snapshot.data()!;
    } catch (err) {
      // 重新拋出已知的 HttpsError（not-found 等）
      if (err instanceof HttpsError) throw err;

      logger.error("getMe：讀取 Firestore 文件失敗", {
        severity: "ERROR",
        uid,
        error: (err as Error).message,
      });
      throw new HttpsError("internal", "系統發生錯誤，請稍後再試");
    }

    // ── 3. 組合回應（Firestore 資料 + custom claims）─────────────────────────
    // custom claims 直接從已驗證的 ID Token 讀取，不需要額外 Admin SDK 呼叫
    return {
      uid: userDoc.uid as string,
      email: userDoc.email as string,
      displayName: (userDoc.displayName as string | null) ?? null,
      photoURL: (userDoc.photoURL as string | null) ?? null,
      role: (userDoc.role as string) ?? "customer",
      createdAt: userDoc.createdAt as admin.firestore.Timestamp,
      updatedAt: userDoc.updatedAt as admin.firestore.Timestamp,
      lineLinked: (userDoc.lineLinked as boolean) ?? false,
      facebookLinked: (userDoc.facebookLinked as boolean) ?? false,
      claims: {
        // token.admin 為 custom claim，未設定時為 undefined，轉為 boolean
        admin: token.admin === true,
      },
    };
  }
);
