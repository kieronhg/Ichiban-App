import * as admin from "firebase-admin";
import {
  COL_NOTIFICATION_LOGS,
  CHANNEL_PUSH,
  CHANNEL_EMAIL,
  DELIVERY_SENT,
  DELIVERY_FAILED,
  DELIVERY_SUPPRESSED,
  RECIPIENT_MEMBER,
  RECIPIENT_ADMIN,
} from "../config";

const db = () => admin.firestore();

interface NotificationLogPayload {
  recipientProfileId: string;
  recipientType: typeof RECIPIENT_MEMBER | typeof RECIPIENT_ADMIN;
  channel: typeof CHANNEL_PUSH | typeof CHANNEL_EMAIL;
  type: string;
  deliveryStatus: typeof DELIVERY_SENT | typeof DELIVERY_FAILED | typeof DELIVERY_SUPPRESSED;
  title?: string;
  body?: string;
  failureReason?: string;
  suppressionReason?: string;
  announcementId?: string;
  emailSubject?: string;
  emailTemplateKey?: string;
}

/** Write a notificationLogs document. Fire-and-forget — do not await at call site
 *  if you want non-blocking behaviour, but DO await if you need the ID. */
export async function writeNotificationLog(
  payload: NotificationLogPayload
): Promise<string> {
  const doc = await db()
    .collection(COL_NOTIFICATION_LOGS)
    .add({
      ...payload,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
    });
  return doc.id;
}

/** Send an FCM push to a single token and write a notificationLog.
 *  Returns true if delivered, false if suppressed or failed. */
export async function sendPush(opts: {
  token: string | undefined | null;
  title: string;
  body: string;
  type: string;
  recipientProfileId: string;
  recipientType: typeof RECIPIENT_MEMBER | typeof RECIPIENT_ADMIN;
  data?: Record<string, string>;
  announcementId?: string;
}): Promise<boolean> {
  if (!opts.token) {
    await writeNotificationLog({
      recipientProfileId: opts.recipientProfileId,
      recipientType: opts.recipientType,
      channel: CHANNEL_PUSH,
      type: opts.type,
      deliveryStatus: DELIVERY_FAILED,
      title: opts.title,
      body: opts.body,
      failureReason: "No FCM token registered for recipient",
      announcementId: opts.announcementId,
    });
    return false;
  }

  try {
    await admin.messaging().send({
      token: opts.token,
      notification: { title: opts.title, body: opts.body },
      data: {
        type: opts.type,
        ...(opts.announcementId ? { announcementId: opts.announcementId } : {}),
        ...opts.data,
      },
    });
    await writeNotificationLog({
      recipientProfileId: opts.recipientProfileId,
      recipientType: opts.recipientType,
      channel: CHANNEL_PUSH,
      type: opts.type,
      deliveryStatus: DELIVERY_SENT,
      title: opts.title,
      body: opts.body,
      announcementId: opts.announcementId,
    });
    return true;
  } catch (err) {
    const failureReason =
      err instanceof Error ? err.message : String(err);
    await writeNotificationLog({
      recipientProfileId: opts.recipientProfileId,
      recipientType: opts.recipientType,
      channel: CHANNEL_PUSH,
      type: opts.type,
      deliveryStatus: DELIVERY_FAILED,
      title: opts.title,
      body: opts.body,
      failureReason,
      announcementId: opts.announcementId,
    });
    return false;
  }
}

/** Returns true if the member has opted in to the given preference key. */
export function hasOptedIn(
  communicationPreferences: Record<string, boolean> | undefined,
  prefKey: string
): boolean {
  if (!communicationPreferences) return false;
  return communicationPreferences[prefKey] === true;
}
