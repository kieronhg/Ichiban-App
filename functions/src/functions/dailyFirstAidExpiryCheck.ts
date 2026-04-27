import * as functions from "firebase-functions/v2";

/**
 * TODO(coach-profiles): Implement when the Coach Profiles feature is built.
 *
 * Runs daily at 06:45 UTC.
 * Same pattern as dailyDbsExpiryCheck but for firstAid.expiryDate.
 *
 * See deferred features item 18 for full specification.
 */
export const dailyFirstAidExpiryCheck = functions.scheduler.onSchedule(
  { schedule: "45 6 * * *", timeZone: "UTC" },
  async () => {
    // Not yet implemented — requires Coach Profiles feature.
    return;
  }
);
