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
exports.onGradingEligibilityCreated = void 0;
const admin = __importStar(require("firebase-admin"));
const functions = __importStar(require("firebase-functions/v2"));
const config_1 = require("../config");
const notifications_1 = require("../utils/notifications");
const db = () => admin.firestore();
/**
 * Fires when a gradingEventStudents document is created.
 * Sends a "grading eligibility" push to the nominated student.
 *
 * The Flutter app writes the document via NominateStudentUseCase;
 * this function owns all notification delivery.
 */
exports.onGradingEligibilityCreated = functions.firestore.onDocumentCreated(`${config_1.COL_GRADING_EVENT_STUDENTS}/{docId}`, async (event) => {
    var _a, _b, _c;
    const data = (_a = event.data) === null || _a === void 0 ? void 0 : _a.data();
    if (!data)
        return;
    const studentId = data.studentId;
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
    const gradingEventId = (_b = data.gradingEventId) !== null && _b !== void 0 ? _b : "";
    const disciplineId = (_c = data.disciplineId) !== null && _c !== void 0 ? _c : "";
    await (0, notifications_1.sendPush)({
        token,
        title: "You've been nominated for grading! 🥋",
        body: "Your instructor has put you forward. Check the app for details.",
        type: config_1.NOTIF_GRADING_ELIGIBILITY,
        recipientProfileId: studentId,
        recipientType: config_1.RECIPIENT_MEMBER,
        data: { gradingEventId, disciplineId },
    });
    // Stamp notificationSentAt on the source document.
    await event.data.ref.update({
        notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
//# sourceMappingURL=onGradingEligibilityCreated.js.map