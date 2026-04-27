import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import {
  COL_GRADING_EVENT_STUDENTS,
  COL_PROFILES,
  NOTIF_GRADING_ELIGIBILITY,
  RECIPIENT_MEMBER,
} from "../config";
import { sendPush, hasOptedIn } from "../utils/notifications";

const db = () => admin.firestore();

/**
 * Fires when a gradingEventStudents document is created.
 * Sends a "grading eligibility" push to the nominated student.
 *
 * The Flutter app writes the document via NominateStudentUseCase;
 * this function owns all notification delivery.
 */
export const onGradingEligibilityCreated = functions.firestore.onDocumentCreated(
  `${COL_GRADING_EVENT_STUDENTS}/{docId}`,
  async (event) => {
    const data = event.data?.data();
    if (!data) return;

    const studentId: string = data.studentId;
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
    const gradingEventId: string = data.gradingEventId ?? "";
    const disciplineId: string = data.disciplineId ?? "";

    await sendPush({
      token,
      title: "You've been nominated for grading! 🥋",
      body: "Your instructor has put you forward. Check the app for details.",
      type: NOTIF_GRADING_ELIGIBILITY,
      recipientProfileId: studentId,
      recipientType: RECIPIENT_MEMBER,
      data: { gradingEventId, disciplineId },
    });

    // Stamp notificationSentAt on the source document.
    await event.data!.ref.update({
      notificationSentAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);
