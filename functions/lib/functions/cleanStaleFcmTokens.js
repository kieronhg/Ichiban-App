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
exports.cleanStaleFcmTokens = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const config_1 = require("../config");
const db = () => admin.firestore();
/**
 * Runs daily at 03:00 UTC.
 * Clears fcmToken and fcmTokenUpdatedAt from profile and adminUser documents
 * where the token is older than FCM_STALE_DAYS (default 30) days.
 * This prevents sending to stale tokens after reinstalls or device changes.
 */
exports.cleanStaleFcmTokens = functions.scheduler.onSchedule({ schedule: "0 3 * * *", timeZone: "UTC" }, async () => {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - config_1.FCM_STALE_DAYS);
    const cutoffTimestamp = admin.firestore.Timestamp.fromDate(cutoff);
    await clearStaleTokensFromCollection(config_1.COL_PROFILES, cutoffTimestamp);
    await clearStaleTokensFromCollection(config_1.COL_ADMIN_USERS, cutoffTimestamp);
});
async function clearStaleTokensFromCollection(collectionName, cutoff) {
    const snap = await db()
        .collection(collectionName)
        .where("fcmTokenUpdatedAt", "<", cutoff)
        .get();
    const batches = [];
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
//# sourceMappingURL=cleanStaleFcmTokens.js.map