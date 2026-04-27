import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_PROFILES,
  COL_ANNOUNCEMENTS,
  NOTIF_ANNOUNCEMENT,
  CHANNEL_PUSH,
  DELIVERY_SENT,
  DELIVERY_FAILED,
  DELIVERY_SUPPRESSED,
  RECIPIENT_MEMBER,
} from "../config";
import { writeNotificationLog } from "../utils/notifications";

// Enrollments collection name — keep in sync with AppConstants.colEnrollments if renamed.
const COL_ENROLLMENTS = "enrollments";

const db = () => admin.firestore();

interface SendAnnouncementRequest {
  title: string;
  body: string;
  channel: "push" | "email" | "both";
  audience: "all" | "discipline";
  disciplineId?: string;
}

/**
 * HTTP callable invoked by Flutter's SendAnnouncementUseCase.
 * Resolves recipient list, sends FCM push to each registered token,
 * writes an announcements document, and returns delivery counts.
 *
 * Email delivery is gated on EMAIL_ENABLED=true environment variable
 * (requires Firebase Blaze plan for outbound network calls).
 */
export const sendAnnouncement = functions.https.onCall(
  async (request: functions.https.CallableRequest<SendAnnouncementRequest>) => {
    // Auth guard — must be a signed-in admin.
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be signed in."
      );
    }

    const { title, body, channel, audience, disciplineId } = request.data;

    if (!title?.trim() || !body?.trim()) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "title and body are required."
      );
    }

    if (audience === "discipline" && !disciplineId) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "disciplineId is required when audience is 'discipline'."
      );
    }

    // Resolve recipient profileIds.
    let profileIds: string[];

    if (audience === "all") {
      const snap = await db().collection(COL_PROFILES).get();
      profileIds = snap.docs.map((d) => d.id);
    } else {
      // Query enrollments for the given disciplineId.
      const enrollSnap = await db()
        .collection(COL_ENROLLMENTS)
        .where("disciplineId", "==", disciplineId)
        .where("isActive", "==", true)
        .get();
      profileIds = enrollSnap.docs.map((d) => d.data().profileId as string);
    }

    const recipientCount = profileIds.length;
    let deliveredCount = 0;
    let failedCount = 0;

    // Write announcement document first to get its ID.
    const announcementRef = await db().collection(COL_ANNOUNCEMENTS).add({
      title,
      body,
      sentByAdminId: request.auth.uid,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      channel,
      audience,
      disciplineId: disciplineId ?? null,
      recipientCount,
      deliveredCount: 0,
      failedCount: 0,
    });

    const announcementId = announcementRef.id;

    if (channel === "push" || channel === "both") {
      // Fetch all profiles in a single batched read (chunks of 30 for Firestore in() limit).
      const tokens = await resolveTokens(profileIds);

      for (const { profileId, token, communicationPreferences } of tokens) {
        // Respect opt-out preference.
        if (
          !hasOptedIn(communicationPreferences, "generalDojoAnnouncements")
        ) {
          await writeNotificationLog({
            recipientProfileId: profileId,
            recipientType: RECIPIENT_MEMBER,
            channel: CHANNEL_PUSH,
            type: NOTIF_ANNOUNCEMENT,
            deliveryStatus: DELIVERY_SUPPRESSED,
            title,
            body,
            suppressionReason: "generalDojoAnnouncements opted out",
            announcementId,
          });
          continue;
        }

        if (!token) {
          await writeNotificationLog({
            recipientProfileId: profileId,
            recipientType: RECIPIENT_MEMBER,
            channel: CHANNEL_PUSH,
            type: NOTIF_ANNOUNCEMENT,
            deliveryStatus: DELIVERY_FAILED,
            title,
            body,
            failureReason: "No FCM token registered",
            announcementId,
          });
          failedCount++;
          continue;
        }

        try {
          await admin.messaging().send({
            token,
            notification: { title, body },
            data: { type: NOTIF_ANNOUNCEMENT, announcementId },
          });
          await writeNotificationLog({
            recipientProfileId: profileId,
            recipientType: RECIPIENT_MEMBER,
            channel: CHANNEL_PUSH,
            type: NOTIF_ANNOUNCEMENT,
            deliveryStatus: DELIVERY_SENT,
            title,
            body,
            announcementId,
          });
          deliveredCount++;
        } catch (err) {
          const failureReason =
            err instanceof Error ? err.message : String(err);
          await writeNotificationLog({
            recipientProfileId: profileId,
            recipientType: RECIPIENT_MEMBER,
            channel: CHANNEL_PUSH,
            type: NOTIF_ANNOUNCEMENT,
            deliveryStatus: DELIVERY_FAILED,
            title,
            body,
            failureReason,
            announcementId,
          });
          failedCount++;
        }
      }
    }

    if (
      (channel === "email" || channel === "both") &&
      process.env.EMAIL_ENABLED === "true"
    ) {
      // TODO(blaze): implement email delivery via Nodemailer once Blaze plan is active.
      // See deferred features item 23.
    }

    // Update announcement with final counts.
    await announcementRef.update({ deliveredCount, failedCount });

    return { announcementId, recipientCount, deliveredCount, failedCount };
  }
);

// ── Helpers ────────────────────────────────────────────────────────────────

interface ProfileTokenResult {
  profileId: string;
  token: string | undefined;
  communicationPreferences: Record<string, boolean> | undefined;
}

/** Fetch FCM tokens for a list of profile IDs in batches of 30. */
async function resolveTokens(
  profileIds: string[]
): Promise<ProfileTokenResult[]> {
  const results: ProfileTokenResult[] = [];
  // Firestore 'in' operator supports up to 30 values.
  for (let i = 0; i < profileIds.length; i += 30) {
    const chunk = profileIds.slice(i, i + 30);
    const snap = await db()
      .collection(COL_PROFILES)
      .where(admin.firestore.FieldPath.documentId(), "in", chunk)
      .get();
    for (const doc of snap.docs) {
      const data = doc.data();
      results.push({
        profileId: doc.id,
        token: data.fcmToken as string | undefined,
        communicationPreferences: data.communicationPreferences as
          | Record<string, boolean>
          | undefined,
      });
    }
  }
  return results;
}

function hasOptedIn(
  prefs: Record<string, boolean> | undefined,
  key: string
): boolean {
  return prefs?.[key] === true;
}

