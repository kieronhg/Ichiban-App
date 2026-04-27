"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendAnnouncement = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const config_1 = require("../config");
const notifications_1 = require("../utils/notifications");
// Enrollments collection name — keep in sync with AppConstants.colEnrollments if renamed.
const COL_ENROLLMENTS = "enrollments";
const db = () => admin.firestore();
/**
 * HTTP callable invoked by Flutter's SendAnnouncementUseCase.
 * Resolves recipient list, sends FCM push to each registered token,
 * writes an announcements document, and returns delivery counts.
 *
 * Email delivery is gated on EMAIL_ENABLED=true environment variable
 * (requires Firebase Blaze plan for outbound network calls).
 */
exports.sendAnnouncement = functions.https.onCall(async (request) => {
    // Auth guard — must be a signed-in admin.
    if (!request.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
    }
    const { title, body, channel, audience, disciplineId } = request.data;
    if (!(title === null || title === void 0 ? void 0 : title.trim()) || !(body === null || body === void 0 ? void 0 : body.trim())) {
        throw new functions.https.HttpsError("invalid-argument", "title and body are required.");
    }
    if (audience === "discipline" && !disciplineId) {
        throw new functions.https.HttpsError("invalid-argument", "disciplineId is required when audience is 'discipline'.");
    }
    // Resolve recipient profileIds.
    let profileIds;
    if (audience === "all") {
        const snap = await db().collection(config_1.COL_PROFILES).get();
        profileIds = snap.docs.map((d) => d.id);
    }
    else {
        // Query enrollments for the given disciplineId.
        const enrollSnap = await db()
            .collection(COL_ENROLLMENTS)
            .where("disciplineId", "==", disciplineId)
            .where("isActive", "==", true)
            .get();
        profileIds = enrollSnap.docs.map((d) => d.data().profileId);
    }
    const recipientCount = profileIds.length;
    let deliveredCount = 0;
    let failedCount = 0;
    // Write announcement document first to get its ID.
    const announcementRef = await db().collection(config_1.COL_ANNOUNCEMENTS).add({
        title,
        body,
        sentByAdminId: request.auth.uid,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        channel,
        audience,
        disciplineId: disciplineId !== null && disciplineId !== void 0 ? disciplineId : null,
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
            if (!hasOptedIn(communicationPreferences, "generalDojoAnnouncements")) {
                await (0, notifications_1.writeNotificationLog)({
                    recipientProfileId: profileId,
                    recipientType: config_1.RECIPIENT_MEMBER,
                    channel: config_1.CHANNEL_PUSH,
                    type: config_1.NOTIF_ANNOUNCEMENT,
                    deliveryStatus: config_1.DELIVERY_SUPPRESSED,
                    title,
                    body,
                    suppressionReason: "generalDojoAnnouncements opted out",
                    announcementId,
                });
                continue;
            }
            if (!token) {
                await (0, notifications_1.writeNotificationLog)({
                    recipientProfileId: profileId,
                    recipientType: config_1.RECIPIENT_MEMBER,
                    channel: config_1.CHANNEL_PUSH,
                    type: config_1.NOTIF_ANNOUNCEMENT,
                    deliveryStatus: config_1.DELIVERY_FAILED,
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
                    data: { type: config_1.NOTIF_ANNOUNCEMENT, announcementId },
                });
                await (0, notifications_1.writeNotificationLog)({
                    recipientProfileId: profileId,
                    recipientType: config_1.RECIPIENT_MEMBER,
                    channel: config_1.CHANNEL_PUSH,
                    type: config_1.NOTIF_ANNOUNCEMENT,
                    deliveryStatus: config_1.DELIVERY_SENT,
                    title,
                    body,
                    announcementId,
                });
                deliveredCount++;
            }
            catch (err) {
                const failureReason = err instanceof Error ? err.message : String(err);
                await (0, notifications_1.writeNotificationLog)({
                    recipientProfileId: profileId,
                    recipientType: config_1.RECIPIENT_MEMBER,
                    channel: config_1.CHANNEL_PUSH,
                    type: config_1.NOTIF_ANNOUNCEMENT,
                    deliveryStatus: config_1.DELIVERY_FAILED,
                    title,
                    body,
                    failureReason,
                    announcementId,
                });
                failedCount++;
            }
        }
    }
    if ((channel === "email" || channel === "both") &&
        process.env.EMAIL_ENABLED === "true") {
        // TODO(blaze): implement email delivery via Nodemailer once Blaze plan is active.
        // See deferred features item 23.
    }
    // Update announcement with final counts.
    await announcementRef.update({ deliveredCount, failedCount });
    return { announcementId, recipientCount, deliveredCount, failedCount };
});
/** Fetch FCM tokens for a list of profile IDs in batches of 30. */
async function resolveTokens(profileIds) {
    const results = [];
    // Firestore 'in' operator supports up to 30 values.
    for (let i = 0; i < profileIds.length; i += 30) {
        const chunk = profileIds.slice(i, i + 30);
        const snap = await db()
            .collection(config_1.COL_PROFILES)
            .where(admin.firestore.FieldPath.documentId(), "in", chunk)
            .get();
        for (const doc of snap.docs) {
            const data = doc.data();
            results.push({
                profileId: doc.id,
                token: data.fcmToken,
                communicationPreferences: data.communicationPreferences,
            });
        }
    }
    return results;
}
function hasOptedIn(prefs, key) {
    return (prefs === null || prefs === void 0 ? void 0 : prefs[key]) === true;
}
//# sourceMappingURL=sendAnnouncement.js.map