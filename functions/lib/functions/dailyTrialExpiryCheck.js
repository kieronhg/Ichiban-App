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
exports.dailyTrialExpiryCheck = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const config_1 = require("../config");
const notifications_1 = require("../utils/notifications");
const settings_1 = require("../utils/settings");
const db = () => admin.firestore();
/**
 * Runs daily at 06:15 UTC.
 *
 * 1. Marks trial memberships as expired when trialEndDate < today.
 * 2. Sends trialExpiring push to each newly expired trial member.
 * 3. Sends trialExpiring reminder push to members whose trial ends within
 *    the trialExpiryReminderDays window but hasn't expired yet.
 */
exports.dailyTrialExpiryCheck = functions.scheduler.onSchedule({ schedule: "15 6 * * *", timeZone: "UTC" }, async () => {
    var _a, _b;
    const now = new Date();
    const reminderDays = await (0, settings_1.getSetting)("trialExpiryReminderDays", 3);
    const reminderWindowMs = reminderDays * 24 * 60 * 60 * 1000;
    const reminderWindowDate = new Date(now.getTime() + reminderWindowMs);
    // ── 1. Expire overdue trials ─────────────────────────────────────────
    const expired = await db()
        .collection(config_1.COL_MEMBERSHIPS)
        .where("status", "==", config_1.STATUS_TRIAL)
        .where("trialEndDate", "<", admin.firestore.Timestamp.fromDate(now))
        .get();
    for (const doc of expired.docs) {
        const membership = doc.data();
        const batch = db().batch();
        batch.update(doc.ref, {
            status: config_1.STATUS_EXPIRED,
            isActive: false,
        });
        const historyRef = db().collection(config_1.COL_MEMBERSHIP_HISTORY).doc();
        batch.set(historyRef, {
            membershipId: doc.id,
            changeType: config_1.CHANGE_TYPE_CANCELLED,
            changedAt: admin.firestore.FieldValue.serverTimestamp(),
            changedByAdminId: "system",
            notes: "Trial expired — set by dailyTrialExpiryCheck",
        });
        await batch.commit();
        // Send expiry notification.
        const memberProfileIds = (_a = membership.memberProfileIds) !== null && _a !== void 0 ? _a : [];
        await sendTrialExpiryNotifications(memberProfileIds, "Your trial has ended", "Your trial period has ended. Contact the dojo to continue training.");
    }
    // ── 2. Pre-expiry reminders ──────────────────────────────────────────
    const expiringSoon = await db()
        .collection(config_1.COL_MEMBERSHIPS)
        .where("status", "==", config_1.STATUS_TRIAL)
        .where("trialEndDate", ">=", admin.firestore.Timestamp.fromDate(now))
        .where("trialEndDate", "<=", admin.firestore.Timestamp.fromDate(reminderWindowDate))
        .get();
    for (const doc of expiringSoon.docs) {
        const membership = doc.data();
        const memberProfileIds = (_b = membership.memberProfileIds) !== null && _b !== void 0 ? _b : [];
        await sendTrialExpiryNotifications(memberProfileIds, "Your trial is ending soon", "Your trial period ends in a few days. Speak to your instructor about joining.");
    }
});
async function sendTrialExpiryNotifications(profileIds, title, body) {
    for (const profileId of profileIds) {
        const profileSnap = await db()
            .collection(config_1.COL_PROFILES)
            .doc(profileId)
            .get();
        if (!profileSnap.exists)
            continue;
        const profile = profileSnap.data();
        if (!(0, notifications_1.hasOptedIn)(profile.communicationPreferences, "trialExpiryReminders")) {
            continue;
        }
        await (0, notifications_1.sendPush)({
            token: profile.fcmToken,
            title,
            body,
            type: config_1.NOTIF_TRIAL_EXPIRING,
            recipientProfileId: profileId,
            recipientType: config_1.RECIPIENT_MEMBER,
        });
    }
}
//# sourceMappingURL=dailyTrialExpiryCheck.js.map