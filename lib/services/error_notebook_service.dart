import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/error_note_model.dart';
import '../core/constants/app_constants.dart';

class ErrorNotebookService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _notes =>
      _db.collection(AppConstants.colErrorNotebook);

  Stream<List<ErrorNote>> watchAllNotes(String userId) {
    return _notes.where('userId', isEqualTo: userId).snapshots().map((snap) =>
        snap.docs.map((d) => ErrorNote.fromDoc(d)).toList()
          ..sort((a, b) => a.nextReview.compareTo(b.nextReview)));
  }

  Future<List<ErrorNote>> getDueToday(String userId) async {
    final now = DateTime.now();
    final todayEnd = Timestamp.fromDate(
      DateTime(now.year, now.month, now.day, 23, 59, 59),
    );

    final snap = await _notes
        .where('userId', isEqualTo: userId)
        .where('nextReview', isLessThanOrEqualTo: todayEnd)
        .get();

    return snap.docs.map((d) => ErrorNote.fromDoc(d)).toList();
  }

  Future<ErrorNote> createNote(ErrorNote note) async {
    final ref = await _notes.add(note.toMap());
    return note.copyWith(id: ref.id);
  }

  Future<void> updateNote(ErrorNote note) async {
    await _notes.doc(note.id).update(note.toMap());
  }

  Future<void> deleteNote(String noteId) async {
    await _notes.doc(noteId).delete();
  }

  /// Mark a note as reviewed — advances the spaced repetition stage
  Future<void> markReviewed(ErrorNote note) async {
    final advanced = note.advance();
    await _notes.doc(note.id).update({
      'reviewStage': advanced.reviewStage,
      'nextReview': Timestamp.fromDate(advanced.nextReview),
    });
  }
}
