import * as admin from "firebase-admin";
import { COL_APP_SETTINGS } from "../config";

const db = () => admin.firestore();

/** Fetch a single appSettings value by document ID. Returns defaultValue
 *  if the document does not exist or the field is missing. */
export async function getSetting(
  key: string,
  defaultValue: number
): Promise<number> {
  const snap = await db().collection(COL_APP_SETTINGS).doc(key).get();
  if (!snap.exists) return defaultValue;
  const val = snap.data()?.[key];
  return typeof val === "number" ? val : defaultValue;
}
