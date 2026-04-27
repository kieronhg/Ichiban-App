import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_GRADING_EVENT_STUDENTS,
  COL_PROFILES,
  NOTIF_GRADING_PROMOTION,
  OUTCOME_PROMOTED,
  RECIPIENT_MEMBER,
} from "../config";
import { sendPush, hasOptedIn } from "../utils/notifications";

const db = () => admin.firestore();

/**
 * Fires when a gradingEventStudents document is updated.
 * Sends a "grading promotion" push if outcome just changed to 'promoted'.
 */
export const onGradingPromotionRecorded = functions.firestore.onDocumentUpdated(
  `${COL_GRADING_EVENT_STUDENTS}/{docId}`,
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    // Only fire when outcome newly becomes 'promoted'
    if (
      before.outcome === OUTCOME_PROMOTED ||
      after.outcome !== OUTCOME_PROMOTED
    ) {
      return;
    }

    const studentId: string = after.studentId;
    if (!studentId) return;

    const profileSnap = await db()
      .collection(COL_PROFILES)
      .doc(studentId)
      .get();
    if (!profileSnap.exists) return;

    const profile = profileSnap.data()!;

    if (!hasOptedIn(profile.communicationPreferences, "gradingNotifications")) {
      return;
    }

    const token: string | undefined = profile.fcmToken;
    const disciplineId: string = after.disciplineId ?? "";
    const rankAchievedId: string = after.rankAchievedId ?? "";
    const gradingScore: string =
      after.gradingScore != null ? String(after.gradingScore) : "";

    await sendPush({
      token,
      title: "Congratulations — you've been promoted! 🎉",
      body: "Your instructor has recorded your grading results. Well done!",
      type: NOTIF_GRADING_PROMOTION,
      recipientProfileId: studentId,
      recipientType: RECIPIENT_MEMBER,
      data: { disciplineId, rankAchievedId, gradingScore },
    });
  }
);
