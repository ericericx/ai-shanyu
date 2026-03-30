/**
 * One-off bootstrap: set Firebase Auth custom claim { admin: true } for a UID.
 * Firebase Console does not let you edit custom claims in the Auth user UI.
 *
 * Prerequisites:
 *   cd functions
 *   gcloud auth application-default login
 *   # or export GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccount.json
 *
 * Usage:
 *   FIRESTORE_PROJECT_ID=shayu-staging npx ts-node src/scripts/setBootstrapAdmin.ts <UID>
 *
 * Also merges Firestore users/{uid} role to "admin" when the doc exists (keeps claims + Firestore aligned).
 */

import * as admin from "firebase-admin";

async function main(): Promise<void> {
  const uid = process.argv[2]?.trim();
  if (!uid) {
    console.error("Usage: npx ts-node src/scripts/setBootstrapAdmin.ts <UID>");
    process.exit(1);
  }

  const projectId =
    process.env.FIRESTORE_PROJECT_ID ??
    process.env.GCLOUD_PROJECT ??
    "shayu-staging";

  if (!admin.apps.length) {
    admin.initializeApp({ projectId });
  }

  try {
    await admin.auth().getUser(uid);
  } catch (e) {
    console.error(`No Auth user for uid=${uid}:`, (e as Error).message);
    process.exit(1);
  }

  await admin.auth().setCustomUserClaims(uid, { admin: true });
  console.log(`OK: setCustomUserClaims admin=true for uid=${uid}`);

  const userRef = admin.firestore().collection("users").doc(uid);
  const snap = await userRef.get();
  if (snap.exists) {
    await userRef.update({
      role: "admin",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`OK: Firestore users/${uid} role set to admin`);
  } else {
    console.warn(
      `Skip Firestore: users/${uid} missing (create by signing in to the app first).`
    );
  }

  console.log(
    "Client must call getIdToken(true) or sign out and sign in again."
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
