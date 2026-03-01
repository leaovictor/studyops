import * as admin from "firebase-admin";

// Initialize Firebase Admin only once
if (admin.apps.length === 0) {
    admin.initializeApp();
}

// Re-exporting functions for Firebase
export { onDeleteGoal } from "./onDeleteGoal";
export { onDeleteSubject } from "./onDeleteSubject";
export { checkAIRateLimit } from "./checkAIRateLimit";
export { onUserCreated } from "./onUserCreated";
export { onUserDeleted } from "./onUserDeleted";
