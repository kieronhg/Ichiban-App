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
exports.cleanStaleFcmTokens = exports.dailyFirstAidExpiryCheck = exports.dailyDbsExpiryCheck = exports.dailyTrialExpiryCheck = exports.dailyMembershipCheck = exports.sendAnnouncement = exports.onGradingPromotionRecorded = exports.onGradingEligibilityCreated = void 0;
const admin = __importStar(require("firebase-admin"));
admin.initializeApp();
// ── Firestore triggers ─────────────────────────────────────────────────────
var onGradingEligibilityCreated_1 = require("./functions/onGradingEligibilityCreated");
Object.defineProperty(exports, "onGradingEligibilityCreated", { enumerable: true, get: function () { return onGradingEligibilityCreated_1.onGradingEligibilityCreated; } });
var onGradingPromotionRecorded_1 = require("./functions/onGradingPromotionRecorded");
Object.defineProperty(exports, "onGradingPromotionRecorded", { enumerable: true, get: function () { return onGradingPromotionRecorded_1.onGradingPromotionRecorded; } });
// TODO(coach-profiles): export compliance triggers from onCoachComplianceUpdated
// when the Coach Profiles feature is implemented.
// ── HTTP callables ─────────────────────────────────────────────────────────
var sendAnnouncement_1 = require("./functions/sendAnnouncement");
Object.defineProperty(exports, "sendAnnouncement", { enumerable: true, get: function () { return sendAnnouncement_1.sendAnnouncement; } });
// ── Scheduled functions ────────────────────────────────────────────────────
var dailyMembershipCheck_1 = require("./functions/dailyMembershipCheck");
Object.defineProperty(exports, "dailyMembershipCheck", { enumerable: true, get: function () { return dailyMembershipCheck_1.dailyMembershipCheck; } });
var dailyTrialExpiryCheck_1 = require("./functions/dailyTrialExpiryCheck");
Object.defineProperty(exports, "dailyTrialExpiryCheck", { enumerable: true, get: function () { return dailyTrialExpiryCheck_1.dailyTrialExpiryCheck; } });
var dailyDbsExpiryCheck_1 = require("./functions/dailyDbsExpiryCheck");
Object.defineProperty(exports, "dailyDbsExpiryCheck", { enumerable: true, get: function () { return dailyDbsExpiryCheck_1.dailyDbsExpiryCheck; } });
var dailyFirstAidExpiryCheck_1 = require("./functions/dailyFirstAidExpiryCheck");
Object.defineProperty(exports, "dailyFirstAidExpiryCheck", { enumerable: true, get: function () { return dailyFirstAidExpiryCheck_1.dailyFirstAidExpiryCheck; } });
var cleanStaleFcmTokens_1 = require("./functions/cleanStaleFcmTokens");
Object.defineProperty(exports, "cleanStaleFcmTokens", { enumerable: true, get: function () { return cleanStaleFcmTokens_1.cleanStaleFcmTokens; } });
//# sourceMappingURL=index.js.map