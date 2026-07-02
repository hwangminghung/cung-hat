import 'package:flutter/material.dart';

class PlanTimePickerSheet extends StatefulWidget {
  const PlanTimePickerSheet({
    super.key,
    required this.venueName,
    required this.now,
  });

  final String venueName;
  final DateTime now;

  @override
  State<PlanTimePickerSheet> createState() => _PlanTimePickerSheetState();
}

class _PlanTimePickerSheetState extends State<PlanTimePickerSheet> {
  static const _timeSlots = [18, 19, 20, 21, 22, 23];

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  @override
  void initState() {
    super.initState();
    final initial = _initialWhen(widget.now);
    _selectedDate = DateTime(initial.year, initial.month, initial.day);
    _selectedTime = TimeOfDay.fromDateTime(initial);
  }

  DateTime _initialWhen(DateTime now) {
    final todayAtSeven = DateTime(now.year, now.month, now.day, 19);
    if (todayAtSeven.isAfter(now)) return todayAtSeven;
    final nextHour = DateTime(now.year, now.month, now.day, now.hour + 1);
    if (nextHour.day == now.day && nextHour.hour <= 23) return nextHour;
    final tomorrow = now.add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 19);
  }

  List<DateTime> get _dateOptions {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    return [for (var i = 0; i < 7; i++) today.add(Duration(days: i))];
  }

  String _dateLabel(DateTime date) {
    final today = DateTime(widget.now.year, widget.now.month, widget.now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (_sameDay(date, today)) return 'Hôm nay';
    if (_sameDay(date, tomorrow)) return 'Mai';
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdays[date.weekday - 1];
  }

  String _dateSubLabel(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}';
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _whenFor(int hour) => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    hour,
  );

  DateTime get _selectedWhen => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      if (!_selectedWhen.isAfter(widget.now)) {
        DateTime? next;
        for (final hour in _timeSlots) {
          final candidate = _whenFor(hour);
          if (candidate.isAfter(widget.now)) {
            next = candidate;
            break;
          }
        }
        if (next != null) {
          _selectedTime = TimeOfDay.fromDateTime(next);
        }
      }
    });
  }

  Future<void> _pickCustomTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('plan_time_sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chọn lịch hát',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.venueName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đóng',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _dateOptions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final date = _dateOptions[index];
                  final selected = _sameDay(date, _selectedDate);
                  return ChoiceChip(
                    key: Key('plan_date_$index'),
                    selected: selected,
                    onSelected: (_) => _selectDate(date),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_dateLabel(date)),
                        Text(_dateSubLabel(date)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hour in _timeSlots)
                  ChoiceChip(
                    key: Key('plan_time_${hour.toString().padLeft(2, '0')}00'),
                    label: Text('${hour.toString().padLeft(2, '0')}:00'),
                    selected:
                        _selectedTime.hour == hour && _selectedTime.minute == 0,
                    onSelected: _whenFor(hour).isAfter(widget.now)
                        ? (_) => setState(
                            () => _selectedTime = TimeOfDay(
                              hour: hour,
                              minute: 0,
                            ),
                          )
                        : null,
                  ),
                OutlinedButton.icon(
                  key: const Key('plan_time_custom_btn'),
                  onPressed: _pickCustomTime,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Giờ khác'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('confirm_plan_time_btn'),
                onPressed: _selectedWhen.isAfter(widget.now)
                    ? () => Navigator.of(context).pop(_selectedWhen)
                    : null,
                child: const Text('Đề xuất kế hoạch'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
