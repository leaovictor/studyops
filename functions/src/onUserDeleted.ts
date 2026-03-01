import * as admin from "firebase-admin";
import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

const db = () => admin.firestore();

/**
 * Deletes ALL user data when a user document is deleted from /users/{userId}.
 * This ensures GDPR/LGPD compliance and keeps the database clean.
 */
export const onUserDeleted = onDocumentDeleted(
    "users/{userId}",
    async (event) => {
        const userId = event.params.userId;
        logger.info(`onUserDeleted: full cleanup for userId=${userId}`);

        const firestore = db();

        // List of collections where 'userId' is a field
        const collections = [
            "goals",
            "subjects",
            "topics",
            "study_plans",
            "daily_tasks",
            "study_logs",
            "error_notebook",
            "flashcards",
            "fsrs_review_logs",
            "study_journals",
            "usage",
        ];

        const deleteDocs = async (docs: admin.firestore.DocumentReference[]) => {
            const chunks = chunkArray(docs, 499);
            for (const chunk of chunks) {
                const batch = firestore.batch();
                for (const ref of chunk) {
                    batch.delete(ref);
                }
                await batch.commit();
            }
        };

        for (const colName of collections) {
            const snap = await firestore
                .collection(colName)
                .where("userId", "==", userId)
                .get();

            if (!snap.empty) {
                logger.info(`onUserDeleted: deleting ${snap.size} docs from ${colName}`);
                await deleteDocs(snap.docs.map((d) => d.ref));
            }
        }

        // Special case: pomodoro_settings (docId is userId)
        const settingsRef = firestore.collection("pomodoro_settings").doc(userId);
        await settingsRef.delete();

        logger.info(`onUserDeleted: done for userId=${userId}`);
    }
);

function chunkArray<T>(arr: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < arr.length; i += size) {
        chunks.push(arr.slice(i, i + size));
    }
    return chunks;
}
