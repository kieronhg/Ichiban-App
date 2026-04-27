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
exports.dailyDbsExpiryCheck = void 0;
const functions = __importStar(require("firebase-functions/v2"));
/**
 * TODO(coach-profiles): Implement when the Coach Profiles feature is built.
 *
 * Runs daily at 06:30 UTC.
 * Checks adminUsers where role=coach for approaching/expired DBS dates.
 *
 * Logic (once coachProfiles or adminUsers contains dbs fields):
 * - Query documents where dbs.expiryDate < today → set dbs.status = 'expired'
 * - Query documents where dbs.expiryDate within dbsExpiryAlertDays (default 60)
 * - For each: push to the coach + push to all active owners
 * - Write notificationLogs for type: dbsExpiry
 *
 * See deferred features item 18 for full specification.
 */
exports.dailyDbsExpiryCheck = functions.scheduler.onSchedule({ schedule: "30 6 * * *", timeZone: "UTC" }, async () => {
    // Not yet implemented — requires Coach Profiles feature.
    return;
});
//# sourceMappingURL=dailyDbsExpiryCheck.js.map