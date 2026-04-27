import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_MEMBERSHIPS,
  COL_MEMBERSHIP_HISTORY,
  COL_PROFILES,
  STATUS_ACTIVE,
  STATUS_LAPSED,
  CHANGE_TYPE_LAPSED,
  NOTIF_LAPSE_REMINDER_PRE,
  NOTIF_LAPSE_REMINDER_POST,
  RECIPIENT_MEMBER,
} from "../config";
import { sendPush, hasOptedIn } from "../utils/notifications";
import { getSetting } from "../utils/settings";

const db = () => admin.firestore();

/**
 * Runs daily at 06:00 UTC.
 *
 * 1. Marks active memberships as lapsed when subscriptionRenewalDate < today.
 * 2. Sends lapseReminderPost push to each newly lapsed member.
 * 3. Sends lapseReminderPre push to members whose renewal is within the
 *    lapseReminderPreDueDays window but not yet lapsed.
 */
export const dailyMembershipCheck = functions.scheduler.onSchedule(
  { schedule: "0 6 * * *", timeZone: "UTC" },
  async () => {
    const now = new Date();
    const preDays = await getSetting("lapseReminderPreDueDays", 14);
    const preWindowMs = preDays * 24 * 60 * 60 * 1000;
    const preWindowDate = new Date(now.getTime() + preWindowMs);

    // ── 1. Lapse overdue active memberships ──────────────────────────────
    const overdue = await db()
      .collection(COL_MEMBERSHIPS)
      .where("status", "==", STATUS_ACTIVE)
      .where("subscriptionRenewalDate", "<", admin.firestore.Timestamp.fromDate(now))
      .get();

    for (const doc of overdue.docs) {
      const membership = doc.data();
      const batch = db().batch();

      batch.update(doc.ref, {
        status: STATUS_LAPSED,
        isActive: false,
      });

      const historyRef = db().collection(COL_MEMBERSHIP_HISTORY).doc();
      batch.set(historyRef, {
        membershipId: doc.id,
        changeType: CHANGE_TYPE_LAPSED,
        changedAt: admin.firestore.FieldValue.serverTimestamp(),
        changedByAdminId: "system",
        notes: "Automatically lapsed by dailyMembershipCheck",
      });

      await batch.commit();

      // Send post-lapse notification to each member on this membership.
      const memberProfileIds: string[] = membership.memberProfileIds ?? [];
      await sendLapseNotifications(
        memberProfileIds,
        NOTIF_LAPSE_REMINDER_POST,
        "Your membership has lapsed",
        "Please contact the dojo to renew your membership."
      );
    }

    // ── 2. Pre-lapse reminders ───────────────────────────────────────────
    const expiringSoon = await db()
      .collection(COL_MEMBERSHIPS)
      .where("status", "==", STATUS_ACTIVE)
      .where("subscriptionRenewalDate", ">=", admin.firestore.Timestamp.fromDate(now))
      .where(
        "subscriptionRenewalDate",
        "<=",
        admin.firestore.Timestamp.fromDate(preWindowDate)
      )
      .get();

    for (const doc of expiringSoon.docs) {
      const membership = doc.data();
      const memberProfileIds: string[] = membership.memberProfileIds ?? [];
      await sendLapseNotifications(
        memberProfileIds,
        NOTIF_LAPSE_REMINDER_PRE,
        "Your membership is due for renewal",
        `Your membership expires soon. Please renew to avoid a lapse.`
      );
    }
  }
);

async function sendLapseNotifications(
  profileIds: string[],
  type: string,
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
      !hasOptedIn(
        profile.communicationPreferences,
        "billingAndPaymentReminders"
      )
    ) {
      continue;
    }

    await sendPush({
      token: profile.fcmToken,
      title,
      body,
      type,
      recipientProfileId: profileId,
      recipientType: RECIPIENT_MEMBER,
    });
  }
}
