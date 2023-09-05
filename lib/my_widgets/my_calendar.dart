
// ignore_for_file: file_names, prefer_const_constructors, must_be_immutable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyCalendar extends StatefulWidget {
  final bool rangeSelectionMode;
  final Function(DateTimeRange?)? onRangeSelected;
  final Function(DateTime?)? onDaySelected;
  DateTimeRange? dateRange;
  DateTime focusedDay;

  MyCalendar({
    Key? key,
    this.dateRange,
    required this.focusedDay,
    this.rangeSelectionMode = true,
    this.onRangeSelected,
    this.onDaySelected,
  }) : super(key: key);

  @override
  State<MyCalendar> createState() => _MyCalendarState();
}

class _MyCalendarState extends State<MyCalendar> {

  @override
  void initState() {
    widget.dateRange = DateTimeRange(
      start: DateTime.now().subtract(Duration(days: 7)),
      end: DateTime.now(),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //print(widget.focusedDay);
    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      // child: TableCalendar(
      //   //Calendar main settings
      //   locale: 'es_US',
      //   firstDay: DateTime(1900),
      //   lastDay: DateTime(2100),
      //   focusedDay: widget.focusedDay,
      //   daysOfWeekVisible: true,
      //   rangeStartDay: widget.rangeSelectionMode ? widget.dateRange?.start : null,
      //   rangeEndDay: widget.rangeSelectionMode ? widget.dateRange?.end : null,

      //   onRangeSelected: (_rangeStartDay, _rangeEndDay, _focusedDay){
      //     if(widget.rangeSelectionMode){
      //       setState((){
      //         if(_rangeStartDay != null && _rangeEndDay != null){
      //           widget.focusedDay = _focusedDay;
      //           widget.dateRange = DateTimeRange(start: _rangeStartDay, end: _rangeEndDay);
      //           widget.onRangeSelected!(widget.dateRange);
      //         }
      //       });
      //     }
      //   },

      //   onDaySelected: (DateTime _selectedDay, DateTime _focusedDay) {
      //     if(!widget.rangeSelectionMode){
      //       setState(() {
      //         widget.focusedDay = _selectedDay;
      //         widget.onDaySelected!(_selectedDay);
      //       });
      //     }
      //   },

      //   selectedDayPredicate: (DateTime date) {
      //     //use this to go to screen_form.dart
      //   },
      // ),
    );
  }
}
