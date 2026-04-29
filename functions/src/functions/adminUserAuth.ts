import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v2";
import { COL_ADMIN_USERS, ROLE_OWNER } from "../config";

const db = () => admin.firestore();

/** Verifies the caller is a signed-in owner. Throws HttpsError otherwise. */
async function requireOwner(
  auth: functions.https.CallableRequest["auth"]
): Promise<void> {
  if (!auth) {
    throw new functions.https.HttpsError("unauthenticated", "Must be signed in.");
  }
  const callerSnap = await db().collection(COL_ADMIN_USERS).doc(auth.uid).get();
  const caller = callerSnap.data();
  if (!caller || caller.role !== ROLE_OWNER || caller.isActive !== true) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only active owners can manage admin accounts."
    );
  }
}

// ── disableAdminUser ──────────────────────────────────────────────────────────

interface AdminUidRequest {
  uid: string;
}

/**
 * Disables a Firebase Auth account.
 * Called by DeactivateAdminUserUseCase after the Firestore write.
 */
export const disableAdminUser = functions.https.onCall(
  async (request: functions.https.CallableRequest<AdminUidRequest>) => {
    await requireOwner(request.auth);

    const { uid } = request.data;
    if (!uid?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "uid is required.");
    }
    if (uid === request.auth!.uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot disable your own account."
      );
    }

    await admin.auth().updateUser(uid, { disabled: true });
    return { success: true };
  }
);

// ── enableAdminUser ───────────────────────────────────────────────────────────

/**
 * Re-enables a Firebase Auth account.
 * Called by ReactivateAdminUserUseCase after the Firestore write.
 */
export const enableAdminUser = functions.https.onCall(
  async (request: functions.https.CallableRequest<AdminUidRequest>) => {
    await requireOwner(request.auth);

    const { uid } = request.data;
    if (!uid?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "uid is required.");
    }

    await admin.auth().updateUser(uid, { disabled: false });
    return { success: true };
  }
);

// ── deleteAdminUser ───────────────────────────────────────────────────────────

/**
 * Permanently deletes a Firebase Auth account.
 * Called by DeleteAdminUserUseCase after the Firestore write.
 */
export const deleteAdminUser = functions.https.onCall(
  async (request: functions.https.CallableRequest<AdminUidRequest>) => {
    await requireOwner(request.auth);

    const { uid } = request.data;
    if (!uid?.trim()) {
      throw new functions.https.HttpsError("invalid-argument", "uid is required.");
    }
    if (uid === request.auth!.uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Cannot delete your own account."
      );
    }

    await admin.auth().deleteUser(uid);
    return { success: true };
  }
);
