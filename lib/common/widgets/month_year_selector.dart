import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncos_screen/common/widgets/date_selector.dart';

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
    final canDecrementMonth = _canDecrementMonth();
    final canIncrementMonth = _canIncrementMonth();
    final canDecrementYear = _canDecrementYear();
    final canIncrementYear = _canIncrementYear();

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
              onDecrement: canDecrementMonth ? _decrementMonth : () {},
              onIncrement: canIncrementMonth ? _incrementMonth : () {},
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
              onDecrement: canDecrementYear ? _decrementYear : () {},
              onIncrement: canIncrementYear ? _incrementYear : () {},
              canDecrement: canDecrementYear,
              canIncrement: canIncrementYear,
            ),
          ),
        ),
      ],
    );
  }

  bool _canDecrementMonth() {
    final newDate = DateTime(selectedDate.year, selectedDate.month - 1);
    return newDate.isAfter(_minDate) || newDate.isAtSameMomentAs(_minDate);
  }

  bool _canIncrementMonth() {
    final newDate = DateTime(selectedDate.year, selectedDate.month + 1);
    return newDate.isBefore(_maxDate) || newDate.isAtSameMomentAs(_maxDate);
  }

  bool _canDecrementYear() {
    final newDate = DateTime(selectedDate.year - 1, selectedDate.month);
    return newDate.isAfter(_minDate) || newDate.isAtSameMomentAs(_minDate);
  }

  bool _canIncrementYear() {
    final newDate = DateTime(selectedDate.year + 1, selectedDate.month);
    return newDate.isBefore(_maxDate) || newDate.isAtSameMomentAs(_maxDate);
  }

  void _decrementMonth() {
    final newDate = DateTime(selectedDate.year, selectedDate.month - 1);
    onDateChanged(newDate);
  }

  void _incrementMonth() {
    final newDate = DateTime(selectedDate.year, selectedDate.month + 1);
    onDateChanged(newDate);
  }

  void _decrementYear() {
    final newDate = DateTime(selectedDate.year - 1, selectedDate.month);
    onDateChanged(newDate);
  }

  void _incrementYear() {
    final newDate = DateTime(selectedDate.year + 1, selectedDate.month);
    onDateChanged(newDate);
  }
}
