import 'package:easy_localization/easy_localization.dart';

extension DateTimeExtension on DateTime {
  // String get formattedDate => DateFormat('dd/MM/yyyy').format(this);

  // ~~년/~~월/~~일 순으로 수정했다
  String get formattedDate => DateFormat('yyyy년 MM월 dd일').format(this);

  String get formattedTime => DateFormat('HH:mm').format(this);

  String get formattedDateTime => DateFormat('dd/MM/yyyy HH:mm').format(this);

  /**
   * 상대적인 날짜를 표시하기 위한 포맷
   */
  String get relativeDays {
    final diffDays = difference(DateTime.now().onlyDate).inDays;
    final isNegative = diffDays.isNegative;

    final checkCondition = (diffDays, isNegative);
    return switch (checkCondition) {
      (0, _) => _tillToday,
      (1, _) => _tillTomorrow,
      (_, true) => _dayPassed,
      _ => _dayLeft
    };
  }

  DateTime get onlyDate {
    return DateTime(year, month, day);
  }

  /**
   * 국제화 고려 -> assets/translations 폴더 참고
   */
  String get _dayLeft => 'daysLeft'
      .tr(namedArgs: {"daysCount": difference(DateTime.now().onlyDate).inDays.toString()});

  String get _dayPassed => 'daysPassed'
      .tr(namedArgs: {"daysCount": difference(DateTime.now().onlyDate).inDays.abs().toString()});

  String get _tillToday => 'tillToday'.tr();

  String get _tillTomorrow => 'tillTomorrow'.tr();
}
