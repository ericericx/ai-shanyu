/**
 * Default Firestore users/{uid} shape; used by onUserCreated and getMe backfill.
 */

import * as admin from "firebase-admin";
import { logger } from "firebase-functions/v2";

export function buildDefaultUserFirestoreData(
  user: admin.auth.UserRecord
): admin.firestore.DocumentData {
  const now = admin.firestore.Timestamp.now();
  return {
    uid: user.uid,
    email: user.email ?? "",
    displayName: user.displayName ?? null,
    photoURL: user.photoURL ?? null,
    role: "customer",
    createdAt: now,
    updatedAt: now,
    lineLinked: false,
    facebookLinked: false,
  };
}

/**
 * Creates users/{uid} via Admin SDK when missing (e.g. legacy Auth user, trigger not deployed).
 */
export async function ensureUserFirestoreDocument(uid: string): Promise<void> {
  const ref = admin.firestore().collection("users").doc(uid);
  const existing = await ref.get();
  if (existing.exists) {
    return;
  }
  const userRecord = await admin.auth().getUser(uid);
  const data = buildDefaultUserFirestoreData(userRecord);
  try {
    await ref.create(data);
    logger.info("ensureUserFirestoreDocument: profile created", {
      severity: "INFO",
      uid,
    });
  } catch (err) {
    const error = err as admin.FirebaseError;
    if (error.code === "6" || error.message?.includes("ALREADY_EXISTS")) {
      return;
    }
    logger.error("ensureUserFirestoreDocument: create failed", {
      severity: "ERROR",
      uid,
      errorCode: error.code ?? "unknown",
      errorMessage: error.message,
    });
    throw err;
  }
}
