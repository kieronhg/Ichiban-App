import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_ADMIN_USERS,
  COL_COACH_PROFILES,
  NOTIF_COMPLIANCE_SUBMITTED,
  NOTIF_COMPLIANCE_VERIFIED,
  RECIPIENT_ADMIN,
  ROLE_OWNER,
} from "../config";
import { sendPush } from "../utils/notifications";

const db = () => admin.firestore();

/**
 * Fires when a coachProfiles document is updated.
 *
 * - onCoachComplianceSubmitted: when dbs.pendingVerification or
 *   firstAid.pendingVerification flips to true, notifies all owners.
 *
 * - onCoachComplianceVerified: when dbs.status or firstAid.status changes
 *   to 'verified', notifies the coach.
 */
export const onCoachComplianceUpdated = functions.firestore.onDocumentUpdated(
  `${COL_COACH_PROFILES}/{uid}`,
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const coachUid: string = event.params.uid;

    // ── Detect what changed ────────────────────────────────────────────────

    const dbsSubmitted =
      !before.dbs?.pendingVerification && after.dbs?.pendingVerification === true;
    const firstAidSubmitted =
      !before.firstAid?.pendingVerification &&
      after.firstAid?.pendingVerification === true;

    const dbsVerified =
      before.dbs?.status !== "verified" && after.dbs?.status === "verified";
    const firstAidVerified =
      before.firstAid?.status !== "verified" &&
      after.firstAid?.status === "verified";

    const anySubmitted = dbsSubmitted || firstAidSubmitted;
    const anyVerified = dbsVerified || firstAidVerified;

    if (!anySubmitted && !anyVerified) return;

    // ── Load the coach's adminUsers document ───────────────────────────────

    const coachSnap = await db().collection(COL_ADMIN_USERS).doc(coachUid).get();
    const coach = coachSnap.data();
    const coachName: string = coach
      ? `${coach.firstName ?? ""} ${coach.lastName ?? ""}`.trim()
      : "A coach";

    // ── Notify owners when compliance is submitted ─────────────────────────

    if (anySubmitted) {
      const complianceType = dbsSubmitted ? "DBS" : "First Aid";
      const ownersSnap = await db()
        .collection(COL_ADMIN_USERS)
        .where("role", "==", ROLE_OWNER)
        .where("isActive", "==", true)
        .get();

      await Promise.all(
        ownersSnap.docs.map((doc) => {
          const owner = doc.data();
          return sendPush({
            token: owner.fcmToken,
            title: "Compliance update submitted",
            body: `${coachName} has submitted updated ${complianceType} details for review.`,
            type: NOTIF_COMPLIANCE_SUBMITTED,
            recipientProfileId: doc.id,
            recipientType: RECIPIENT_ADMIN,
            data: { coachUid, complianceType },
          });
        })
      );
    }

    // ── Notify coach when compliance is verified ───────────────────────────

    if (anyVerified) {
      const complianceType = dbsVerified ? "DBS" : "First Aid";
      await sendPush({
        token: coach?.fcmToken,
        title: "Compliance verified",
        body: `Your ${complianceType} compliance has been verified.`,
        type: NOTIF_COMPLIANCE_VERIFIED,
        recipientProfileId: coachUid,
        recipientType: RECIPIENT_ADMIN,
        data: { complianceType },
      });
    }
  }
);
