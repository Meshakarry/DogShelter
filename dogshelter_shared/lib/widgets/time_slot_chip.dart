import 'package:flutter/material.dart';

/// Assumed shelter visiting hours (09:00-16:00, hourly) - shared by mobile self-booking and
/// desktop admin walk-in booking so both surfaces offer the exact same slots.
const shelterVisitTimeSlots = ['09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00'];

/// The earliest date a visit can be booked for - always "today", never a past date, for both
/// mobile self-booking and desktop admin walk-in booking. Time-of-day is stripped so this can be
/// used directly as an InlineCalendar `firstDate`.
DateTime firstBookableVisitDate() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

List<String> availableTimeSlots(DateTime? selectedDate) {
  if (selectedDate == null) return shelterVisitTimeSlots;
  final now = DateTime.now();
  final selectedDateOnly = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
  final todayOnly = DateTime(now.year, now.month, now.day);
  if (selectedDateOnly.isBefore(todayOnly)) return const [];
  if (selectedDateOnly.isAfter(todayOnly)) return shelterVisitTimeSlots;
  return shelterVisitTimeSlots.where((slot) {
    final parts = slot.split(':');
    final slotTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, int.parse(parts[0]), int.parse(parts[1]));
    return slotTime.isAfter(now);
  }).toList();
}

/// One selectable hourly slot in a booking sheet - greyed out and struck through when [taken]
/// (per PosjetaService.EnsureSlotAvailableAsync's definition of an occupied slot), filled green
/// when [selected].
class TimeSlotChip extends StatelessWidget {
  const TimeSlotChip({super.key, required this.label, required this.selected, required this.taken, required this.onTap});

  final String label;
  final bool selected;
  final bool taken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: taken ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF008554) : (taken ? const Color(0xFFF3F4F6) : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF008554) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Text(
          taken ? '$label (zauzeto)' : label,
          style: TextStyle(
            color: selected ? Colors.white : (taken ? const Color(0xFFBDBDBD) : Colors.black87),
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            decoration: taken ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
