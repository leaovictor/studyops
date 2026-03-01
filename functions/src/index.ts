import * as admin from "firebase-admin";

// Initialize Firebase Admin only once
if (admin.apps.length === 0) {
    admin.initializeApp();
}

export { onDeleteGoal } from "./onDeleteGoal";
export { onDeleteSubject } from "./onDeleteSubject";
export { checkAIRateLimit } from "./checkAIRateLimit";
export { onUserCreated } from "./onUserCreated";
export { onUserDeleted } from "./onUserDeleted";
