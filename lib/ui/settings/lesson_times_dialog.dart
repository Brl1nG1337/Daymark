import 'package:flutter/material.dart';

typedef SaveLessonTimes = Future<void> Function(List<String> startTimes);

class LessonTimesDialog extends StatefulWidget {
  const LessonTimesDialog({
    super.key,
    required this.initialStartTimes,
    required this.onSave,
  });

  final List<String> initialStartTimes;
  final SaveLessonTimes onSave;

  @override
  State<LessonTimesDialog> createState() => _LessonTimesDialogState();
}

class _LessonTimesDialogState extends State<LessonTimesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    assert(widget.initialStartTimes.length == 8);
    _controllers = [
      for (final startTime in widget.initialStartTimes)
        TextEditingController(text: startTime),
    ];
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _minutes(String value) {
    if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(value)) {
      return null;
    }
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String? _validateTime(int index, String? rawValue) {
    final value = rawValue?.trim() ?? '';
    final minutes = _minutes(value);
    if (minutes == null) return 'Bitte im Format HH:MM eingeben.';
    if (index == 0) return null;

    final previous = _minutes(_controllers[index - 1].text.trim());
    if (previous != null && minutes < previous + 45) {
      return 'Darf die $index. Stunde nicht überlappen.';
    }
    return null;
  }

  String? _endTime(String value) {
    final minutes = _minutes(value.trim());
    if (minutes == null) return null;
    final endMinutes = minutes + 45;
    final hours = (endMinutes ~/ 60) % 24;
    final mins = endMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    setState(() => _saveError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.onSave([
        for (final controller in _controllers) controller.text.trim(),
      ]);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveError = 'Speichern fehlgeschlagen: $error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Unterrichtszeiten bearbeiten'),
    content: SizedBox(
      width: 460,
      height: MediaQuery.sizeOf(context).height * 0.64,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lege die Startzeit jeder Stunde fest. Das Ende wird mit einer '
              'Unterrichtsdauer von 45 Minuten berechnet.',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _controllers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) => ValueListenableBuilder(
                  valueListenable: _controllers[index],
                  builder: (context, value, child) {
                    final end = _endTime(value.text);
                    return TextFormField(
                      key: ValueKey('period-${index + 1}-start'),
                      controller: _controllers[index],
                      enabled: !_saving,
                      keyboardType: TextInputType.datetime,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        labelText: '${index + 1}. Stunde · Startzeit',
                        helperText: end == null ? null : 'Ende: $end',
                      ),
                      validator: (value) => _validateTime(index, value),
                    );
                  },
                ),
              ),
            ),
            if (_saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                _saveError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context, false),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Speichern'),
      ),
    ],
  );
}
