import 'package:flutter/material.dart';

import '../theme/daymark_theme.dart';
import 'lesson_preparation_view_model.dart';

class LessonPreparationEditor extends StatefulWidget {
  const LessonPreparationEditor({
    super.key,
    required this.viewModel,
    this.readOnly = false,
  });

  final LessonPreparationViewModel viewModel;
  final bool readOnly;

  @override
  State<LessonPreparationEditor> createState() =>
      _LessonPreparationEditorState();
}

class _LessonPreparationEditorState extends State<LessonPreparationEditor> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.viewModel.body,
  );

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_syncController);
  }

  @override
  void didUpdateWidget(LessonPreparationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_syncController);
      widget.viewModel.addListener(_syncController);
      _syncController();
    }
  }

  void _syncController() {
    if (_controller.text == widget.viewModel.body) return;
    _controller.value = TextEditingValue(
      text: widget.viewModel.body,
      selection: TextSelection.collapsed(offset: widget.viewModel.body.length),
    );
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_syncController);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final viewModel = widget.viewModel;
      if (viewModel.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Container(
        decoration: BoxDecoration(
          color: DaymarkColors.surface,
          border: Border.all(color: DaymarkColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView(
          padding: const EdgeInsets.all(26),
          children: [
            const Text(
              'Vorbereitungsnotizen',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Diese Notizen gehören nur zu dieser Stunde und bleiben nach dem Start sichtbar.',
              style: TextStyle(color: DaymarkColors.muted, height: 1.4),
            ),
            const SizedBox(height: 22),
            TextField(
              key: const ValueKey('lesson-preparation-notes'),
              controller: _controller,
              enabled: !widget.readOnly && !viewModel.saving,
              minLines: 8,
              maxLines: 14,
              textAlignVertical: TextAlignVertical.top,
              onChanged: viewModel.updateBody,
              decoration: const InputDecoration(
                hintText: 'Material, Ablauf, Ziele und Erinnerungen für diese Stunde …',
                border: OutlineInputBorder(),
              ),
            ),
            if (viewModel.error case final error?) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: DaymarkColors.error)),
            ],
            if (!widget.readOnly) ...[
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: viewModel.saving || !viewModel.dirty
                      ? null
                      : viewModel.save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    viewModel.saving ? 'Speichert …' : 'Vorbereitung speichern',
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
