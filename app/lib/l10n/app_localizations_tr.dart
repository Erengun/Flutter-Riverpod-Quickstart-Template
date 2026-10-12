// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Flutter Production Boilerplate';

  @override
  String get authCreateAccount => 'Hesap oluştur';

  @override
  String get authCredentialsRequired =>
      'Lütfen e-posta adresinizi ve şifrenizi girin.';

  @override
  String get authEmailHint => 'E-posta adresinizi girin';

  @override
  String get authEmailInvalid => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get authEmailRequired => 'Lütfen bir e-posta adresi girin';

  @override
  String get authLoginButton => 'Giriş yap';

  @override
  String get authLoginFailed => 'E-posta adresi veya şifre hatalı.';

  @override
  String get authLoginSubtitle =>
      'E-posta adresiniz ve şifrenizle giriş yapabilirsiniz';

  @override
  String get authLoginTitle => 'Giriş';

  @override
  String get authPasswordHint => 'Şifrenizi girin';

  @override
  String get authPasswordLabel => 'Şifre';

  @override
  String get authRegisterButton => 'Kaydol';

  @override
  String get authRegisterCancel => 'İptal';

  @override
  String get authRegisterTitle => 'Yeni Profil';

  @override
  String get authUsernameHint => 'Kullanıcı adınızı girin';

  @override
  String get authUsernameLabel => 'Kullanıcı adı';

  @override
  String get authWelcome => 'Uygulamaya hoş geldiniz';

  @override
  String demoAreaBody(String area) {
    return 'Bu sayfayı görebiliyorsunuz çünkü yetkileriniz \"$area\" alanını içeriyor.';
  }

  @override
  String get demoComponentRulesTitle => 'Bileşen kuralları';

  @override
  String get demoDeleteAccountHidden => 'Hesabı sil (gizli)';

  @override
  String get demoEditProfileDisabled => 'Profili düzenle (devre dışı)';

  @override
  String get demoEmailReadonly => 'E-posta (salt okunur)';

  @override
  String get demoOrdersTitle => 'Siparişler';

  @override
  String get demoPermissionsTitle => 'Yetki örneği';

  @override
  String get demoProfileTitle => 'Profil';

  @override
  String get demoReportsTitle => 'Raporlar';

  @override
  String get demoSettingsTitle => 'Ayarlar';

  @override
  String get homeBottomNavFirst => 'Ana Sayfa';

  @override
  String get homeBottomNavSecond => 'Ayarlar';

  @override
  String get homeInfo => 'Hakkında';

  @override
  String get homeIntro => 'Merhaba, ben Eren 👋🏽';

  @override
  String get homeMenuTitle => 'Menü';

  @override
  String get homeMore => 'Daha Fazla';

  @override
  String get homeThemeMode => 'Tema Modu';

  @override
  String get homeThemeModeDark => 'Karanlık';

  @override
  String get homeThemeModeLight => 'Aydınlık';

  @override
  String get homeThemeModeSystem => 'Sistem';

  @override
  String get homeTitle => 'Ana Sayfa';

  @override
  String get homeToggleLanguage => 'Dili Değiştir';

  @override
  String get homeToggleTheme => 'Temayı Değiştir';
}
