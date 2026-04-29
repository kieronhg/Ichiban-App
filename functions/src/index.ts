import * as admin from "firebase-admin";

admin.initializeApp();

// ── Firestore triggers ─────────────────────────────────────────────────────

export { onGradingEligibilityCreated } from "./functions/onGradingEligibilityCreated";
export { onGradingPromotionRecorded } from "./functions/onGradingPromotionRecorded";
export { onCoachComplianceUpdated } from "./functions/onCoachComplianceUpdated";

// ── HTTP callables ─────────────────────────────────────────────────────────

export { sendAnnouncement } from "./functions/sendAnnouncement";
export { disableAdminUser, enableAdminUser, deleteAdminUser } from "./functions/adminUserAuth";

// ── Scheduled functions ────────────────────────────────────────────────────

export { dailyMembershipCheck } from "./functions/dailyMembershipCheck";
export { dailyTrialExpiryCheck } from "./functions/dailyTrialExpiryCheck";
export { dailyDbsExpiryCheck } from "./functions/dailyDbsExpiryCheck";
export { dailyFirstAidExpiryCheck } from "./functions/dailyFirstAidExpiryCheck";
export { cleanStaleFcmTokens } from "./functions/cleanStaleFcmTokens";
