import * as admin from "firebase-admin";
import { onDocumentDeleted } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

const db = () => admin.firestore();

/**
 * Deletes all data associated with a subject when the subject document is deleted.
 *
 * Collections cleaned up: topics, flashcards, error_notebook,
 * study_logs, daily_tasks, fsrs_review_logs
 */
export const onDeleteSubject = onDocumentDeleted(
    "subjects/{subjectId}",
    async (event) => {
        const subjectId = event.params.subjectId;
        const data = event.data?.data();
        if (!data) {
            logger.warn(`onDeleteSubject: no data for subjectId=${subjectId}`);
            return;
        }
        const userId = data.userId as string;
        logger.info(
            `onDeleteSubject: cleaning up subjectId=${subjectId} userId=${userId}`
        );

        const firestore = db();

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

        // 1. Topics
        const topicSnap = await firestore
            .collection("topics")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(topicSnap.docs.map((d) => d.ref));

        // 2. Flashcards
        const flashcardSnap = await firestore
            .collection("flashcards")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(flashcardSnap.docs.map((d) => d.ref));

        // 3. Error notebook
        const errorSnap = await firestore
            .collection("error_notebook")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(errorSnap.docs.map((d) => d.ref));

        // 4. Study logs
        const logSnap = await firestore
            .collection("study_logs")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(logSnap.docs.map((d) => d.ref));

        // 5. Daily tasks
        const taskSnap = await firestore
            .collection("daily_tasks")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(taskSnap.docs.map((d) => d.ref));

        // 6. FSRS Review Logs
        const fsrsSnap = await firestore
            .collection("fsrs_review_logs")
            .where("userId", "==", userId)
            .where("subjectId", "==", subjectId)
            .get();
        await deleteDocs(fsrsSnap.docs.map((d) => d.ref));

        logger.info(`onDeleteSubject: done for subjectId=${subjectId}`);
    }
);

function chunkArray<T>(arr: T[], size: number): T[][] {
    const chunks: T[][] = [];
    for (let i = 0; i < arr.length; i += size) {
        chunks.push(arr.slice(i, i + size));
    }
    return chunks;
}
