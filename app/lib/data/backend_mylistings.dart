import 'backend.dart';

extension BackendMyListings on Backend {
  /// Withdraws one of the user's own errand requests.
  Future<void> archiveTask(String id) async {
    try {
      await c.rpc('archive_task', params: {'p_id': id});
    } catch (_) {
      throw BackendError('Could not remove this request. Please try again.');
    }
  }
}
