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
exports.writeNotificationLog = writeNotificationLog;
exports.sendPush = sendPush;
exports.hasOptedIn = hasOptedIn;
const admin = __importStar(require("firebase-admin"));
const config_1 = require("../config");
const db = () => admin.firestore();
/** Write a notificationLogs document. Fire-and-forget — do not await at call site
 *  if you want non-blocking behaviour, but DO await if you need the ID. */
async function writeNotificationLog(payload) {
    const doc = await db()
        .collection(config_1.COL_NOTIFICATION_LOGS)
        .add(Object.assign(Object.assign({}, payload), { sentAt: admin.firestore.FieldValue.serverTimestamp(), isRead: false }));
    return doc.id;
}
/** Send an FCM push to a single token and write a notificationLog.
 *  Returns true if delivered, false if suppressed or failed. */
async function sendPush(opts) {
    if (!opts.token) {
        await writeNotificationLog({
            recipientProfileId: opts.recipientProfileId,
            recipientType: opts.recipientType,
            channel: config_1.CHANNEL_PUSH,
            type: opts.type,
            deliveryStatus: config_1.DELIVERY_FAILED,
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
            data: Object.assign(Object.assign({ type: opts.type }, (opts.announcementId ? { announcementId: opts.announcementId } : {})), opts.data),
        });
        await writeNotificationLog({
            recipientProfileId: opts.recipientProfileId,
            recipientType: opts.recipientType,
            channel: config_1.CHANNEL_PUSH,
            type: opts.type,
            deliveryStatus: config_1.DELIVERY_SENT,
            title: opts.title,
            body: opts.body,
            announcementId: opts.announcementId,
        });
        return true;
    }
    catch (err) {
        const failureReason = err instanceof Error ? err.message : String(err);
        await writeNotificationLog({
            recipientProfileId: opts.recipientProfileId,
            recipientType: opts.recipientType,
            channel: config_1.CHANNEL_PUSH,
            type: opts.type,
            deliveryStatus: config_1.DELIVERY_FAILED,
            title: opts.title,
            body: opts.body,
            failureReason,
            announcementId: opts.announcementId,
        });
        return false;
    }
}
/** Returns true if the member has opted in to the given preference key. */
function hasOptedIn(communicationPreferences, prefKey) {
    if (!communicationPreferences)
        return false;
    return communicationPreferences[prefKey] === true;
}
//# sourceMappingURL=notifications.js.map