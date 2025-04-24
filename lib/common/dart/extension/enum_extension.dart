import 'package:THECommu/data/models/chat/chat_type_enum.dart';
import 'package:THECommu/data/models/feed_model.dart';
import 'package:easy_localization/easy_localization.dart';

/**
 * String -> Enum으로 변환하는 메서드들이 포함된다
 */
extension ConvertString on String {
  FeedActiveStatus toFeedActiveStatus() {
    switch (this) {
      case "cold":
        return FeedActiveStatus.cold;
      case "hot":
        return FeedActiveStatus.hot;
      default:
        return FeedActiveStatus.normal;
    }
  }

  ChatTypeEnum toChatTypeEnum() {
    switch (this) {
      case "text":
        return ChatTypeEnum.text;
      case "image":
        return ChatTypeEnum.image;
      case "video":
        return ChatTypeEnum.video;
      default:
        return ChatTypeEnum.text;
    }
  }
}

/**
 * Enum -> String으로 변환하는 메서드들이 포함된다
 */
extension ConvertEnum on ChatTypeEnum {
  String fromChatTypeEnumToText() {
    switch (this) {
      case ChatTypeEnum.image:
        return "imageChat".tr();
      case ChatTypeEnum.video:
        return "videoChat".tr();
      case ChatTypeEnum.text:
        return 'TEXT';
    }
  }
}