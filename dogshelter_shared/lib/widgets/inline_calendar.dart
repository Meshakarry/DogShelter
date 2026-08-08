import 'package:flutter/material.dart';

// Matches DogShelter.Services.Constants.MjeseciNazivi on the backend exactly, so report and
// booking screens never disagree on Bosnian month spelling.
const _monthNames = [
  'Januar', 'Februar', 'Mart', 'April', 'Maj', 'Juni',
  'Juli', 'August', 'Septembar', 'Oktobar', 'Novembar', 'Decembar',
];

// Monday-first week, one-letter Bosnian weekday initials (Pon/Uto/Sri/Čet/Pet/Sub/Ned).
const _weekdayLetters = ['P', 'U', 'S', 'Č', 'P', 'S', 'N'];

/// Hand-rolled inline month calendar - always visible in the booking sheet rather than hidden
/// behind a native showDatePicker dialog, with Bosnian month/weekday names and no `intl`
/// dependency.
class InlineCalendar extends StatefulWidget {
  const InlineCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<InlineCalendar> createState() => _InlineCalendarState();
}

class _InlineCalendarState extends State<InlineCalendar> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    final base = widget.selectedDate ?? widget.firstDate;
    _displayedMonth = DateTime(base.year, base.month);
  }

  bool get _canGoPrev => _displayedMonth.isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  bool get _canGoNext => _displayedMonth.isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

  void _changeMonth(int delta) {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta));
  }

  bool _isDisabled(DateTime day) {
    final firstDay = DateTime(widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    return day.isBefore(firstDay) || day.isAfter(widget.lastDate);
  }

  bool _isSelected(DateTime day) {
    final s = widget.selectedDate;
    return s != null && s.year == day.year && s.month == day.month && s.day == day.day;
  }

  @override
  Widget build(BuildContext context) {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = DateTime(year, month, 1).weekday - 1;
    final cells = <int?>[
      ...List.filled(leadingBlanks, null),
      for (var d = 1; d <= daysInMonth; d++) d,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _canGoPrev ? () => _changeMonth(-1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text(
              '${_monthNames[month - 1]} $year',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            IconButton(
              onPressed: _canGoNext ? () => _changeMonth(1) : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        Row(
          children: [
            for (final letter in _weekdayLetters)
              Expanded(
                child: Center(
                  child: Text(
                    letter,
                    style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final cell in cells)
              if (cell == null)
                const SizedBox.shrink()
              else
                _DayCell(
                  label: '$cell',
                  disabled: _isDisabled(DateTime(year, month, cell)),
                  selected: _isSelected(DateTime(year, month, cell)),
                  onTap: () => widget.onDateSelected(DateTime(year, month, cell)),
                ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.label, required this.disabled, required this.selected, required this.onTap});

  final String label;
  final bool disabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: disabled ? null : onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? const Color(0xFF008554) : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: disabled ? const Color(0xFFBDBDBD) : (selected ? Colors.white : Colors.black87),
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
