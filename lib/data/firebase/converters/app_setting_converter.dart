import '../../../domain/entities/app_setting.dart';

class AppSettingConverter {
  AppSettingConverter._();

  static AppSetting fromMap(String key, Map<String, dynamic> map) {
    return AppSetting(
      key: key,
      value: map['value'],
    );
  }

  static Map<String, dynamic> toMap(AppSetting setting) {
    return {
      'value': setting.value,
    };
  }
}
