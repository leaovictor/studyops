import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";

/**
 * Callable function that checks and enforces per-user AI rate limiting.
 *
 * Limits: 10 AI calls per hour per user (free tier).
 *
 * The Flutter client should call this BEFORE making an AI request.
 * Returns { allowed: boolean, remaining: number }.
 *
 * Usage from Flutter (via Cloud Functions callable):
 *   final result = await FirebaseFunctions.instance
 *     .httpsCallable('checkAIRateLimit')
 *     .call();
 */
export const checkAIRateLimit = onCall(
    { cors: true },
    async (request) => {
        // Must be authenticated
        if (!request.auth) {
            throw new HttpsError("unauthenticated", "Autenticação necessária.");
        }

        const userId = request.auth.uid;
        const HOURLY_LIMIT = 10;

        const firestore = admin.firestore();
        const oneHourAgo = Timestamp.fromDate(
            new Date(Date.now() - 60 * 60 * 1000)
        );

        // Aggregation count: avoids reading all documents
        const countSnapshot = await firestore
            .collection("usage")
            .where("userId", "==", userId)
            .where("type", "==", "ai_call")
            .where("timestamp", ">=", oneHourAgo)
            .count()
            .get();

        const callsThisHour = countSnapshot.data().count;
        const remaining = Math.max(0, HOURLY_LIMIT - callsThisHour);

        logger.info(
            `checkAIRateLimit: userId=${userId} calls=${callsThisHour} limit=${HOURLY_LIMIT}`
        );

        if (callsThisHour >= HOURLY_LIMIT) {
            throw new HttpsError(
                "resource-exhausted",
                `Limite de ${HOURLY_LIMIT} chamadas de IA por hora atingido. Tente novamente em breve.`
            );
        }

        return { allowed: true, remaining };
    }
);
