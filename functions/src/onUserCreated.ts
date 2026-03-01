import * as admin from "firebase-admin";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { logger } from "firebase-functions";

/**
 * Runs when a new user document is created in /users/{userId}.
 * Ensures default pomodoro_settings exist for the new user.
 *
 * This provides a safety net in case the Flutter app crashes before
 * writing the settings on the client side.
 */
export const onUserCreated = onDocumentCreated(
    "users/{userId}",
    async (event) => {
        const userId = event.params.userId;
        logger.info(`onUserCreated: initializing settings for userId=${userId}`);

        const firestore = admin.firestore();
        const settingsRef = firestore
            .collection("pomodoro_settings")
            .doc(userId);

        const existing = await settingsRef.get();
        if (existing.exists) {
            logger.info(`onUserCreated: settings already exist for userId=${userId}`);
            return;
        }

        await settingsRef.set({
            userId,
            workMinutes: 25,
            breakMinutes: 5,
            longBreakMinutes: 15,
            rounds: 4,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        logger.info(
            `onUserCreated: default pomodoro settings created for userId=${userId}`
        );
    }
);
