import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../features/shop/models/jour_semaine.dart';

class THelperFunctions {
  static Color? getColor(String value) {
    /// Define your product specific colors here and it will match the attribute colors and show specific 🟠🟡🟢🔵🟣🟤

    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  static void showSnackBar(String message) {
    ScaffoldMessenger.of(Get.context!).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(DateTime date,
      {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
          i, i + rowSize > widgets.length ? widgets.length : i + rowSize);
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static List<String> generateTimeSlots(String start, String end,
      {int intervalMinutes = 30}) {
    final List<String> slots = [];
    final startParts = start.split(':').map(int.parse).toList();
    final endParts = end.split(':').map(int.parse).toList();

    DateTime startTime = DateTime(0, 0, 0, startParts[0], startParts[1]);
    DateTime endTime = DateTime(0, 0, 0, endParts[0], endParts[1]);

    while (startTime.isBefore(endTime)) {
      final slotEnd = startTime.add(Duration(minutes: intervalMinutes));
      if (slotEnd.isAfter(endTime)) break;

      final slotStr =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${slotEnd.hour.toString().padLeft(2, '0')}:${slotEnd.minute.toString().padLeft(2, '0')}';
      slots.add(slotStr);
      startTime = slotEnd;
    }

    return slots;
  }

  static int weekdayFromJour(JourSemaine jour) {
    switch (jour) {
      case JourSemaine.lundi:
        return 1;
      case JourSemaine.mardi:
        return 2;
      case JourSemaine.mercredi:
        return 3;
      case JourSemaine.jeudi:
        return 4;
      case JourSemaine.vendredi:
        return 5;
      case JourSemaine.samedi:
        return 6;
      case JourSemaine.dimanche:
        return 7;
    }
  }

  static JourSemaine stringToJourSemaine(String jour) {
    switch (jour.toLowerCase()) {
      case 'lundi':
        return JourSemaine.lundi;
      case 'mardi':
        return JourSemaine.mardi;
      case 'mercredi':
        return JourSemaine.mercredi;
      case 'jeudi':
        return JourSemaine.jeudi;
      case 'vendredi':
        return JourSemaine.vendredi;
      case 'samedi':
        return JourSemaine.samedi;
      case 'dimanche':
        return JourSemaine.dimanche;
      default:
        throw Exception('Invalid day string: $jour');
    }
  }
}
