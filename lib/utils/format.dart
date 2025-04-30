import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// This function formats a DateTime object into a localized string
String formatDate(BuildContext context, DateTime date) {
  DateTime localDate = date.toLocal();
  String locale = Localizations.localeOf(context).languageCode;
  String yearMonthDay = DateFormat.yMd(locale).format(localDate);
  String hourMinutes = DateFormat.Hm(locale).format(localDate);
  String formattedDate = "$yearMonthDay $hourMinutes";
  return formattedDate;
}
