import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_PROFILES,
  COL_ADMIN_USERS,
  FCM_STALE_DAYS,
} from "../config";

const db = () => admin.firestore();

/**
 * Runs daily at 03:00 UTC.
 * Clears fcmToken and fcmTokenUpdatedAt from profile and adminUser documents
 * where the token is older than FCM_STALE_DAYS (default 30) days.
 * This prevents sending to stale tokens after reinstalls or device changes.
 */
export const cleanStaleFcmTokens = functions.scheduler.onSchedule(
  { schedule: "0 3 * * *", timeZone: "UTC" },
  async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - FCM_STALE_DAYS);
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoff);

    await clearStaleTokensFromCollection(COL_PROFILES, cutoffTimestamp);
    await clearStaleTokensFromCollection(COL_ADMIN_USERS, cutoffTimestamp);
  }
);

async function clearStaleTokensFromCollection(
  collectionName: string,
  cutoff: admin.firestore.Timestamp
): Promise<void> {
  const snap = await db()
    .collection(collectionName)
    .where("fcmTokenUpdatedAt", "<", cutoff)
    .get();

  const batches: admin.firestore.WriteBatch[] = [];
  let current = db().batch();
  let count = 0;

  for (const doc of snap.docs) {
    current.update(doc.ref, {
      fcmToken: admin.firestore.FieldValue.delete(),
      fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
    });
    count++;
    // Firestore batches are limited to 500 operations.
    if (count % 499 === 0) {
      batches.push(current);
      current = db().batch();
    }
  }
  batches.push(current);

  await Promise.all(batches.map((b) => b.commit()));
}
