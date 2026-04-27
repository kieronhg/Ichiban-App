import * as functions from "firebase-functions/v2";

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
export const dailyDbsExpiryCheck = functions.scheduler.onSchedule(
  { schedule: "30 6 * * *", timeZone: "UTC" },
  async () => {
    // Not yet implemented — requires Coach Profiles feature.
    return;
  }
);
