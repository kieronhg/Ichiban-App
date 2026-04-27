import * as admin from "firebase-admin";

admin.initializeApp();

// ── Firestore triggers ─────────────────────────────────────────────────────

export { onGradingEligibilityCreated } from "./functions/onGradingEligibilityCreated";
export { onGradingPromotionRecorded } from "./functions/onGradingPromotionRecorded";

// TODO(coach-profiles): export compliance triggers from onCoachComplianceUpdated
// when the Coach Profiles feature is implemented.

// ── HTTP callables ─────────────────────────────────────────────────────────

export { sendAnnouncement } from "./functions/sendAnnouncement";

// ── Scheduled functions ────────────────────────────────────────────────────

export { dailyMembershipCheck } from "./functions/dailyMembershipCheck";
export { dailyTrialExpiryCheck } from "./functions/dailyTrialExpiryCheck";
export { dailyDbsExpiryCheck } from "./functions/dailyDbsExpiryCheck";
export { dailyFirstAidExpiryCheck } from "./functions/dailyFirstAidExpiryCheck";
export { cleanStaleFcmTokens } from "./functions/cleanStaleFcmTokens";
