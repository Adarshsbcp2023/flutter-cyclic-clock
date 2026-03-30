import 'package:flutter/material.dart';

class DaySelector extends StatelessWidget {
  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  static const _labels = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];
  static const _fullLabels = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return Semantics(
          label: _fullLabels[i],
          selected: selectedDays[i],
          child: FilterChip(
            label: Text(_labels[i]),
            selected: selectedDays[i],
            onSelected: (selected) {
              final days = List<bool>.from(selectedDays);
              days[i] = selected;
              onChanged(days);
            },
            showCheckmark: false,
            padding: EdgeInsets.zero,
            labelPadding:
                const EdgeInsets.symmetric(horizontal: 4),
          ),
        );
      }),
    );
  }
}
