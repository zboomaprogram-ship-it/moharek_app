import 'package:flutter/material.dart';
import 'package:moharek_app/core/theme/app_theme.dart';
import 'package:moharek_app/l10n/app_localizations.dart';

class NPSSurveyBottomSheet extends StatefulWidget {
  final Function(int score, String? comment) onSubmit;

  const NPSSurveyBottomSheet({super.key, required this.onSubmit});

  @override
  State<NPSSurveyBottomSheet> createState() => _NPSSurveyBottomSheetState();
}

class _NPSSurveyBottomSheetState extends State<NPSSurveyBottomSheet> {
  int? _selectedScore;
  final _commentController = TextEditingController();

  final List<String> _emojis = ['😞', '🙁', '😐', '🙂', '😊', '😁', '🤩', '🔥', '🚀', '😍'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.howAreWeDoing,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.feedbackHelpGrow,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          
          // Score Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(10, (index) {
                final score = index + 1;
                final isSelected = _selectedScore == score;
                return GestureDetector(
                  onTap: () => setState(() => _selectedScore = score),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryGreen : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        score.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          if (_selectedScore != null) ...[
            const SizedBox(height: 16),
            Text(
              _emojis[_selectedScore! - 1],
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: l10n.anySpecificFeedback,
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => widget.onSubmit(_selectedScore!, _commentController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(l10n.sendFeedback, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
