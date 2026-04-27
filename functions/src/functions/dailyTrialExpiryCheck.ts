import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_MEMBERSHIPS,
  COL_MEMBERSHIP_HISTORY,
  COL_PROFILES,
  STATUS_TRIAL,
  STATUS_EXPIRED,
  CHANGE_TYPE_CANCELLED,
  NOTIF_TRIAL_EXPIRING,
  RECIPIENT_MEMBER,
} from "../config";
import { sendPush, hasOptedIn } from "../utils/notifications";
import { getSetting } from "../utils/settings";

const db = () => admin.firestore();

/**
 * Runs daily at 06:15 UTC.
 *
 * 1. Marks trial memberships as expired when trialEndDate < today.
 * 2. Sends trialExpiring push to each newly expired trial member.
 * 3. Sends trialExpiring reminder push to members whose trial ends within
 *    the trialExpiryReminderDays window but hasn't expired yet.
 */
export const dailyTrialExpiryCheck = functions.scheduler.onSchedule(
  { schedule: "15 6 * * *", timeZone: "UTC" },
  async () => {
    const now = new Date();
    const reminderDays = await getSetting("trialExpiryReminderDays", 3);
    const reminderWindowMs = reminderDays * 24 * 60 * 60 * 1000;
    const reminderWindowDate = new Date(now.getTime() + reminderWindowMs);

    // ── 1. Expire overdue trials ─────────────────────────────────────────
    const expired = await db()
      .collection(COL_MEMBERSHIPS)
      .where("status", "==", STATUS_TRIAL)
      .where(
        "trialEndDate",
        "<",
        admin.firestore.Timestamp.fromDate(now)
      )
      .get();

    for (const doc of expired.docs) {
      const membership = doc.data();
      const batch = db().batch();

      batch.update(doc.ref, {
        status: STATUS_EXPIRED,
        isActive: false,
      });

      const historyRef = db().collection(COL_MEMBERSHIP_HISTORY).doc();
      batch.set(historyRef, {
        membershipId: doc.id,
        changeType: CHANGE_TYPE_CANCELLED,
        changedAt: admin.firestore.FieldValue.serverTimestamp(),
        changedByAdminId: "system",
        notes: "Trial expired — set by dailyTrialExpiryCheck",
      });

      await batch.commit();

      // Send expiry notification.
      const memberProfileIds: string[] = membership.memberProfileIds ?? [];
      await sendTrialExpiryNotifications(
        memberProfileIds,
        "Your trial has ended",
        "Your trial period has ended. Contact the dojo to continue training."
      );
    }

    // ── 2. Pre-expiry reminders ──────────────────────────────────────────
    const expiringSoon = await db()
      .collection(COL_MEMBERSHIPS)
      .where("status", "==", STATUS_TRIAL)
      .where(
        "trialEndDate",
        ">=",
        admin.firestore.Timestamp.fromDate(now)
      )
      .where(
        "trialEndDate",
        "<=",
        admin.firestore.Timestamp.fromDate(reminderWindowDate)
      )
      .get();

    for (const doc of expiringSoon.docs) {
      const membership = doc.data();
      const memberProfileIds: string[] = membership.memberProfileIds ?? [];
      await sendTrialExpiryNotifications(
        memberProfileIds,
        "Your trial is ending soon",
        "Your trial period ends in a few days. Speak to your instructor about joining."
      );
    }
  }
);

async function sendTrialExpiryNotifications(
  profileIds: string[],
  title: string,
  body: string
): Promise<void> {
  for (const profileId of profileIds) {
    const profileSnap = await db()
      .collection(COL_PROFILES)
      .doc(profileId)
      .get();
    if (!profileSnap.exists) continue;

    const profile = profileSnap.data()!;
    if (
      !hasOptedIn(profile.communicationPreferences, "trialExpiryReminders")
    ) {
      continue;
    }

    await sendPush({
      token: profile.fcmToken,
      title,
      body,
      type: NOTIF_TRIAL_EXPIRING,
      recipientProfileId: profileId,
      recipientType: RECIPIENT_MEMBER,
    });
  }
}
