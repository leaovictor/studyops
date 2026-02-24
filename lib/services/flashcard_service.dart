import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fsrs/fsrs.dart';
import '../models/flashcard_model.dart';
import '../core/constants/app_constants.dart';

class FlashcardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection(AppConstants.colFlashcards);

  // ── Streams ──────────────────────────────────

  Stream<List<Flashcard>> watchAll(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('due')
        .snapshots()
        .map((s) => s.docs.map((d) => Flashcard.fromDoc(d)).toList());
  }

  Stream<List<Flashcard>> watchDueToday(String userId) {
    final endOfDay = DateTime.now();
    return _col
        .where('userId', isEqualTo: userId)
        .where('due', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((s) => s.docs.map((d) => Flashcard.fromDoc(d)).toList());
  }

  Stream<List<Flashcard>> watchBySubject(String userId, String subjectId) {
    return _col
        .where('userId', isEqualTo: userId)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('due')
        .snapshots()
        .map((s) => s.docs.map((d) => Flashcard.fromDoc(d)).toList());
  }

  // ── CRUD ──────────────────────────────────

  Future<Flashcard> create(Flashcard card) async {
    // Initialize a fresh FSRS Card (due immediately)
    final fsrsCard = Card(cardId: 1);
    final now = DateTime.now();
    final enriched = card.copyWith(
      fsrsCard: fsrsCard.toMap(),
      due: now,
      createdAt: now,
    );
    final ref = await _col.add(enriched.toMap());
    return enriched.copyWith(id: ref.id);
  }

  Future<void> update(Flashcard card) async {
    await _col.doc(card.id).update(card.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  // ── FSRS Rating ──────────────────────────────

  /// Rates the card and updates its FSRS state in Firestore.
  Future<Flashcard> rateCard(Flashcard flashcard, Rating rating) async {
    final fsrsCard = Card.fromMap(flashcard.fsrsCard);
    final scheduler = Scheduler();
    final result = scheduler.reviewCard(fsrsCard, rating);
    final updatedCard = flashcard.copyWith(
      fsrsCard: result.card.toMap(),
      due: result.card.due,
    );
    await _col.doc(flashcard.id).update({
      'fsrsCard': result.card.toMap(),
      'due': Timestamp.fromDate(result.card.due),
    });
    return updatedCard;
  }
}
