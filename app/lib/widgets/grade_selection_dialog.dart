import 'package:flutter/material.dart';

class GradeSelectionDialog extends StatelessWidget {
  final String title;
  final Function(int) onGradeSelected;

  const GradeSelectionDialog({
    super.key,
    required this.title,
    required this.onGradeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 18,
            ),
          ),
        ),
        ...List.generate(8, (index) {
          final grade = index + 7;
          return _buildGradeItem(context, 'G$grade', () => onGradeSelected(grade));
        }),
        _buildGradeItem(context, 'OB', () => onGradeSelected(99)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGradeItem(BuildContext context, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
