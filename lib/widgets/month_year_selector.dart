import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncos_screen/widgets/date_selector.dart';

class MonthYearSelector extends StatelessWidget {
  MonthYearSelector({
    required this.selectedDate,
    required this.onDateChanged,
    super.key,
  }) : _minDate = DateTime(1900),
       _maxDate = DateTime.now();

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  final DateTime _minDate;
  final DateTime _maxDate;

  @override
  Widget build(BuildContext context) {
    final previousMonth = DateTime(selectedDate.year, selectedDate.month - 1);
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
    final previousYear = DateTime(selectedDate.year - 1, selectedDate.month);
    final nextYear = DateTime(selectedDate.year + 1, selectedDate.month);

    final canDecrementMonth = _isAfterOrAtMin(previousMonth);
    final canIncrementMonth = _isBeforeOrAtMax(nextMonth);
    final canDecrementYear = _isAfterOrAtMin(previousYear);
    final canIncrementYear = _isBeforeOrAtMax(nextYear);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 10,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: DateSelector(
              value: DateFormat('MMMM').format(selectedDate),
              onDecrement: canDecrementMonth
                  ? () => onDateChanged(previousMonth)
                  : () {},
              onIncrement: canIncrementMonth
                  ? () => onDateChanged(nextMonth)
                  : () {},
              canDecrement: canDecrementMonth,
              canIncrement: canIncrementMonth,
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: DateSelector(
              value: selectedDate.year.toString(),
              onDecrement: canDecrementYear
                  ? () => onDateChanged(previousYear)
                  : () {},
              onIncrement: canIncrementYear
                  ? () => onDateChanged(nextYear)
                  : () {},
              canDecrement: canDecrementYear,
              canIncrement: canIncrementYear,
            ),
          ),
        ),
      ],
    );
  }

  bool _isAfterOrAtMin(DateTime candidate) {
    return candidate.isAfter(_minDate) || candidate.isAtSameMomentAs(_minDate);
  }

  bool _isBeforeOrAtMax(DateTime candidate) {
    return candidate.isBefore(_maxDate) || candidate.isAtSameMomentAs(_maxDate);
  }
}
