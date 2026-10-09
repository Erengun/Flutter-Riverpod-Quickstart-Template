// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'core_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class CoreLocalizationsTr extends CoreLocalizations {
  CoreLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get authRememberMe => 'Beni hatırla';

  @override
  String get authSessionExpired =>
      'Oturumunuzun süresi doldu. Lütfen tekrar giriş yapın.';

  @override
  String get errorConnection =>
      'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get errorNoPermission => 'Bu işlem için yetkiniz yok.';

  @override
  String get errorNotFound => 'Aradığınız içerik bulunamadı.';

  @override
  String get errorRetry => 'Tekrar dene';

  @override
  String get errorServer =>
      'Sunucuda bir sorun oluştu. Lütfen daha sonra tekrar deneyin.';

  @override
  String get errorSomethingWentWrong =>
      'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errorTimeout =>
      'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.';

  @override
  String get noPermissionBody => 'Bu sayfayı görüntüleme yetkiniz yok.';

  @override
  String get noPermissionTitle => 'Erişim yok';

  @override
  String get pageBackHome => 'Ana sayfaya dön';

  @override
  String get underConstructionBody =>
      'Bu sayfa henüz hazır değil. Lütfen daha sonra tekrar bakın.';

  @override
  String get underConstructionTitle => 'Yakında';

  @override
  String get updateBodyOptional =>
      'Yeni bir sürüm mevcut. Şimdi güncellemek ister misiniz?';

  @override
  String get updateBodyRequired =>
      'Uygulamayı kullanmaya devam etmek için yeni sürüm gerekli. Lütfen şimdi güncelleyin.';

  @override
  String get updateButtonIgnore => 'Yoksay';

  @override
  String get updateButtonLater => 'Daha sonra';

  @override
  String get updateButtonUpdate => 'Güncelle';

  @override
  String get updateTitle => 'Güncelleme mevcut';
}
