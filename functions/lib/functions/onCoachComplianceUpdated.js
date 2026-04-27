"use strict";
// TODO(coach-profiles): Implement when the Coach Profiles feature is built.
//
// Two Firestore triggers will live here:
//
// 1. onCoachComplianceSubmitted
//    Fires on adminUsers/{uid} onUpdate when dbs or firstAid data changes
//    (other than status changing to 'verified'). Sends push to all owners:
//    "[Coach Name] has submitted updated compliance details for review."
//    Type: complianceSubmitted
//
// 2. onCoachComplianceVerified
//    Fires on adminUsers/{uid} onUpdate when dbs.status or firstAid.status
//    changes to 'verified'. Sends push to the coach:
//    "Your [DBS / First Aid] compliance has been verified."
//    Type: complianceVerified
//
// See deferred features item 19 for full specification.
Object.defineProperty(exports, "__esModule", { value: true });
//# sourceMappingURL=onCoachComplianceUpdated.js.map