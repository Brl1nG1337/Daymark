import 'package:flutter/foundation.dart';

import '../../data/lesson_preparation_repository.dart';
import '../../domain/lesson_preparation.dart';

class LessonPreparationViewModel extends ChangeNotifier {
  LessonPreparationViewModel(
    this._repository, {
    required this.slotId,
    required this.day,
  });

  final LessonPreparationRepository _repository;
  final int slotId;
  final DateTime day;

  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _savedBody = '';
  String _body = '';
  bool _disposed = false;

  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  String get body => _body;
  bool get dirty => _body != _savedBody;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      final preparation = await _repository.load(slotId: slotId, day: day);
      _savedBody = preparation.body;
      _body = preparation.body;
    } catch (error) {
      _error = 'Vorbereitungsnotizen konnten nicht geladen werden: $error';
    } finally {
      _loading = false;
      _notify();
    }
  }

  void updateBody(String value) {
    if (value == _body) return;
    _body = value;
    _notify();
  }

  void discardChanges() {
    if (!dirty) return;
    _body = _savedBody;
    _notify();
  }

  Future<bool> save() async {
    if (_saving || _loading) return false;
    _saving = true;
    _error = null;
    _notify();
    try {
      final trimmed = _body.trim();
      await _repository.save(
        LessonPreparation(slotId: slotId, day: day, body: trimmed),
      );
      _savedBody = trimmed;
      _body = trimmed;
      return true;
    } catch (error) {
      _error = 'Vorbereitungsnotizen konnten nicht gespeichert werden: $error';
      return false;
    } finally {
      _saving = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
