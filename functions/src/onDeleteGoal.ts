import * as admin from "firebase-admin";
import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

const db = () => admin.firestore();

/**
 * Deletes all data associated with a goal when the goal document is deleted.
 *
 * Collections cleaned up:
 *   subjects, topics (via subjects), flashcards, error_notebook,
 *   study_logs, study_plans, daily_tasks, study_journals
 *
 * Uses chunked batched writes (max 500 ops per batch) for safety.
 */
export const onDeleteGoal = onDocumentDeleted(
    "goals/{goalId}",
    async (event) => {
        const goalId = event.params.goalId;
        const data = event.data?.data();
        if (!data) {
            logger.warn(`onDeleteGoal: no data found for goalId=${goalId}`);
            return;
        }
        const userId = data.userId as string;
        logger.info(`onDeleteGoal: cleaning up goalId=${goalId} userId=${userId}`);

        const firestore = db();

        // ── Helper: delete docs in chunks of 499 ─────────────────────────────────
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

        // 1. Subjects + their Topics
        const subjectSnap = await firestore
            .collection("subjects")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();

        const topicRefs: admin.firestore.DocumentReference[] = [];
        for (const subjectDoc of subjectSnap.docs) {
            const topicSnap = await firestore
                .collection("topics")
                .where("userId", "==", userId)
                .where("subjectId", "==", subjectDoc.id)
                .get();
            topicRefs.push(...topicSnap.docs.map((d) => d.ref));
        }
        await deleteDocs(topicRefs);
        await deleteDocs(subjectSnap.docs.map((d) => d.ref));

        // 2. Flashcards
        const flashcardSnap = await firestore
            .collection("flashcards")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(flashcardSnap.docs.map((d) => d.ref));

        // 3. Error notebook
        const errorSnap = await firestore
            .collection("error_notebook")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(errorSnap.docs.map((d) => d.ref));

        // 4. Study logs
        const logSnap = await firestore
            .collection("study_logs")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(logSnap.docs.map((d) => d.ref));

        // 5. Study plans
        const planSnap = await firestore
            .collection("study_plans")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(planSnap.docs.map((d) => d.ref));

        // 6. Daily tasks
        const taskSnap = await firestore
            .collection("daily_tasks")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(taskSnap.docs.map((d) => d.ref));

        // 7. Study journals
        const journalSnap = await firestore
            .collection("study_journals")
            .where("userId", "==", userId)
            .where("goalId", "==", goalId)
            .get();
        await deleteDocs(journalSnap.docs.map((d) => d.ref));

        logger.info(`onDeleteGoal: done for goalId=${goalId}`);
    }
);

function chunkArray<T>(arr: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < arr.length; i += size) {
        chunks.push(arr.slice(i, i + size));
    }
    return chunks;
}
