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
exports.onGradingPromotionRecorded = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const config_1 = require("../config");
const notifications_1 = require("../utils/notifications");
const db = () => admin.firestore();
/**
 * Fires when a gradingEventStudents document is updated.
 * Sends a "grading promotion" push if outcome just changed to 'promoted'.
 */
exports.onGradingPromotionRecorded = functions.firestore.onDocumentUpdated(`${config_1.COL_GRADING_EVENT_STUDENTS}/{docId}`, async (event) => {
    var _a, _b, _c, _d;
    const before = (_a = event.data) === null || _a === void 0 ? void 0 : _a.before.data();
    const after = (_b = event.data) === null || _b === void 0 ? void 0 : _b.after.data();
    if (!before || !after)
        return;
    // Only fire when outcome newly becomes 'promoted'
    if (before.outcome === config_1.OUTCOME_PROMOTED ||
        after.outcome !== config_1.OUTCOME_PROMOTED) {
        return;
    }
    const studentId = after.studentId;
    if (!studentId)
        return;
    const profileSnap = await db()
        .collection(config_1.COL_PROFILES)
        .doc(studentId)
        .get();
    if (!profileSnap.exists)
        return;
    const profile = profileSnap.data();
    if (!(0, notifications_1.hasOptedIn)(profile.communicationPreferences, "gradingNotifications")) {
        return;
    }
    const token = profile.fcmToken;
    const disciplineId = (_c = after.disciplineId) !== null && _c !== void 0 ? _c : "";
    const rankAchievedId = (_d = after.rankAchievedId) !== null && _d !== void 0 ? _d : "";
    const gradingScore = after.gradingScore != null ? String(after.gradingScore) : "";
    await (0, notifications_1.sendPush)({
        token,
        title: "Congratulations — you've been promoted! 🎉",
        body: "Your instructor has recorded your grading results. Well done!",
        type: config_1.NOTIF_GRADING_PROMOTION,
        recipientProfileId: studentId,
        recipientType: config_1.RECIPIENT_MEMBER,
        data: { disciplineId, rankAchievedId, gradingScore },
    });
});
//# sourceMappingURL=onGradingPromotionRecorded.js.map