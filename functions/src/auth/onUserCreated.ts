/**
 * Auth Trigger：新使用者建立後初始化 Firestore 文件
 *
 * 觸發時機：Firebase Auth 建立新使用者帳號時（Email/Password、Google、LINE OAuth 等）
 * 功能：在 users/{uid} 建立預設使用者文件，包含角色、OAuth 連結狀態等欄位
 *
 * 安全注意：
 *   - 此 function 由 Firebase Auth 系統觸發，無客戶端直接呼叫入口，無需額外認證
 *   - 使用 Admin SDK 寫入，不受 Security Rules 限制（符合預期）
 *   - 不在文件中存放密碼或敏感 token
 *
 * 冪等性：若文件已存在（例如重新觸發），使用 create() 避免覆蓋已有資料
 */

import * as admin from "firebase-admin";
import { auth } from "firebase-functions/v1";
import { logger } from "firebase-functions/v2";

/**
 * Firestore users/{uid} 文件的型別定義
 */
interface UserDocument {
  uid: string;
  email: string;
  displayName: string | null;
  photoURL: string | null;
  /** Default role on first signup; promote to admin via Firestore + onRoleUpdated */
  role: string;
  createdAt: admin.firestore.Timestamp;
  updatedAt: admin.firestore.Timestamp;
  lineLinked: boolean;
  facebookLinked: boolean;
}

export const onUserCreated = auth
  .user()
  .onCreate(async (user: admin.auth.UserRecord): Promise<void> => {
    const { uid, email, displayName, photoURL } = user;

    // 安全防護：確保 uid 存在（Auth 觸發器保證此欄位，但防禦性檢查）
    if (!uid) {
      logger.error("onUserCreated：收到無效的 uid，略過處理", {
        severity: "ERROR",
      });
      return;
    }

    const now = admin.firestore.Timestamp.now();

    const userDoc: UserDocument = {
      uid,
      email: email ?? "",       // 部分 OAuth 提供者可能無 email
      displayName: displayName ?? null,
      photoURL: photoURL ?? null,
      role: "customer",
      createdAt: now,
      updatedAt: now,
      lineLinked: false,
      facebookLinked: false,
    };

    try {
      // 使用 create() 而非 set()：若文件已存在則拋出例外，防止覆蓋現有資料
      // （重新觸發或競態條件下的保護）
      await admin
        .firestore()
        .collection("users")
        .doc(uid)
        .create(userDoc);

      logger.info("使用者文件建立成功", {
        severity: "INFO",
        uid,
        email: email ?? "(無 email)",
      });
    } catch (err) {
      const error = err as admin.FirebaseError;

      // ALREADY_EXISTS 表示文件已存在（冪等性保護），視為正常情況
      if (error.code === "6" || error.message?.includes("ALREADY_EXISTS")) {
        logger.warn("使用者文件已存在，略過建立", {
          severity: "WARNING",
          uid,
        });
        return;
      }

      // 其他錯誤：記錄並重新拋出，讓 Functions 框架處理重試
      logger.error("建立使用者文件失敗", {
        severity: "ERROR",
        uid,
        errorCode: error.code ?? "unknown",
        errorMessage: error.message,
      });
      throw err;
    }
  });
