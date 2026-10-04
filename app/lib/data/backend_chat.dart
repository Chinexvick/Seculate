import 'backend.dart';
import 'models.dart';

/// Extra chat / offer calls used by the chat screens.
extension BackendChat on Backend {
  /// A single counter-offer (shown inside chat as an offer bubble).
  Future<Offer> offer(String id) async {
    try {
      final r = await c.from('offers').select().eq('id', id).single();
      return Offer.fromRow(Map<String, dynamic>.from(r));
    } catch (e) {
      if (e is BackendError) rethrow;
      throw BackendError('Could not load this offer.');
    }
  }
}
