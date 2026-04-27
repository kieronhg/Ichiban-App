import '../entities/announcement.dart';

abstract class AnnouncementRepository {
  /// Returns all announcements, most recent first.
  Future<List<Announcement>> getAll();

  /// Returns a single announcement by ID, or null if not found.
  Future<Announcement?> getById(String id);

  /// Watches all announcements in real time, most recent first.
  Stream<List<Announcement>> watchAll();
}
