// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Lessify';

  @override
  String get tabStudents => 'Öğrenciler';

  @override
  String get tabSchedule => 'Program';

  @override
  String get tabJournal => 'Günlük';

  @override
  String get tabPayment => 'Ödeme';

  @override
  String get tabSettings => 'Ayarlar';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get edit => 'Düzenle';

  @override
  String get add => 'Ekle';

  @override
  String get back => 'Geri';

  @override
  String get close => 'Kapat';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get next => 'İleri';

  @override
  String get done => 'Tamam';

  @override
  String get select => 'Seç';

  @override
  String get remove => 'Kaldır';

  @override
  String get today => 'Bugün';

  @override
  String get loading => 'Yükleniyor…';

  @override
  String get somethingWentWrong => 'Bir şeyler ters gitti';

  @override
  String get oauthError => 'OAuth Hatası';

  @override
  String get oauthLoginFailed => 'OAuth girişi başarısız.';

  @override
  String get authTitle => 'Giriş';

  @override
  String get welcomeTitle => 'Lessify\'ye hoş geldiniz';

  @override
  String get createAccountTitle => 'Hesabınızı oluşturun';

  @override
  String get authSubtitle =>
      'Dersleri planlayın, notları takip edin ve özel ders işlerinizi yönetin.';

  @override
  String get login => 'Giriş yap';

  @override
  String get register => 'Kayıt ol';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get orContinueWith => 'veya şununla devam et';

  @override
  String get dontHaveAccount => 'Hesabınız yok mu?';

  @override
  String get alreadyHaveAccount => 'Zaten hesabınız var mı?';

  @override
  String stepOf(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get name => 'Ad';

  @override
  String get phone => 'Telefon';

  @override
  String get passwordConfirmation => 'Şifre tekrarı';

  @override
  String get individualLessonCostOptional =>
      'Bireysel ders ücreti (isteğe bağlı)';

  @override
  String get groupLessonCostOptional => 'Grup ders ücreti (isteğe bağlı)';

  @override
  String get emailPasswordRequired => 'E-posta ve şifre gerekli.';

  @override
  String get nameRequired => 'Ad gerekli.';

  @override
  String get emailRequired => 'E-posta gerekli.';

  @override
  String get passwordRequired => 'Şifre gerekli.';

  @override
  String get passwordConfirmationRequired => 'Şifre tekrarı gerekli.';

  @override
  String get couldNotOpenOAuth => 'OAuth sayfası açılamadı.';

  @override
  String get oauthCouldNotStart => 'OAuth akışı başlatılamadı.';

  @override
  String get oauthInvalidGrantHint =>
      'Google girişi süresi doldu veya yönlendirme adresi uyuşmuyor. Tarayıcıyı kapat, Google Cloud\'da https://getlessify.com/api/auth/google/callback adresinin kayıtlı olduğundan emin ol, sonra uygulamadan tekrar dene.';

  @override
  String get settings => 'Ayarlar';

  @override
  String signedInAs(String name) {
    return '$name olarak giriş yapıldı';
  }

  @override
  String get logout => 'Çıkış yap';

  @override
  String get students => 'Öğrenciler';

  @override
  String get groups => 'Gruplar';

  @override
  String studentCount(int count) {
    return '$count öğrenci';
  }

  @override
  String groupCount(int count) {
    return '$count grup';
  }

  @override
  String get searchByNameOrPhone => 'Ad veya telefona göre ara';

  @override
  String get searchGroups => 'Gruplarda ara';

  @override
  String get noGroupsYet => 'Henüz grup yok';

  @override
  String get noGroupsHint =>
      'Öğrencileri birlikte organize etmek için bir grup oluşturun.';

  @override
  String get addGroup => 'Grup ekle';

  @override
  String get noStudentsYet => 'Henüz öğrenci yok';

  @override
  String get noStudentsHint =>
      'Ders takibine başlamak için ilk öğrencinizi ekleyin.';

  @override
  String get addStudent => 'Öğrenci ekle';

  @override
  String get group => 'Grup';

  @override
  String costPerLesson(String cost) {
    return '$cost / ders';
  }

  @override
  String get deleteStudent => 'Öğrenciyi Sil';

  @override
  String deleteStudentConfirm(String name) {
    return '$name silinsin mi? Durum pasif yapılacak.';
  }

  @override
  String get deleteGroup => 'Grubu Sil';

  @override
  String deleteGroupConfirm(String name) {
    return '$name silinsin mi? Durum pasif yapılacak.';
  }

  @override
  String get studentDetail => 'Öğrenci Detayı';

  @override
  String get info => 'Bilgi';

  @override
  String get lessons => 'Dersler';

  @override
  String get payments => 'Ödemeler';

  @override
  String get student => 'Öğrenci';

  @override
  String get call => 'Ara';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get lessonFee => 'Ders ücreti';

  @override
  String get notSet => 'Belirtilmedi';

  @override
  String get perLesson => 'ders başı';

  @override
  String get noBirthdayAdded => 'Doğum günü eklenmedi';

  @override
  String get notes => 'Notlar';

  @override
  String lastLesson(String date) {
    return 'Son ders: $date';
  }

  @override
  String get tapPhotoToChange => 'Fotoğrafa dokunarak değiştir veya kaldır';

  @override
  String get studentName => 'Öğrenci adı';

  @override
  String get eg500 => 'Örn. 500';

  @override
  String get addShortNote => 'Kısa not ekle…';

  @override
  String get deleteStudentAction => 'Öğrenciyi sil';

  @override
  String get selectDate => 'Tarih seç';

  @override
  String get profilePhoto => 'Profil fotoğrafı';

  @override
  String get chooseFromGallery => 'Galeriden seç';

  @override
  String get camera => 'Kamera';

  @override
  String get removePhoto => 'Fotoğrafı kaldır';

  @override
  String get addPhoneFirst => 'Önce bir telefon numarası ekleyin.';

  @override
  String get couldNotStartCall => 'Arama başlatılamadı.';

  @override
  String get couldNotOpenWhatsApp => 'WhatsApp açılamadı.';

  @override
  String get unsavedChanges => 'Kaydedilmemiş değişiklikler';

  @override
  String get saveBeforeLeaving =>
      'Çıkmadan önce değişiklikleri kaydetmek ister misiniz?';

  @override
  String get dontSave => 'Kaydetme';

  @override
  String get studentUpdated => 'Öğrenci başarıyla güncellendi.';

  @override
  String get deleteStudentContinue =>
      'Bu öğrenci pasif yapılacak. Devam edilsin mi?';

  @override
  String get addStudentTitle => 'Öğrenci Ekle';

  @override
  String get pickAColor => 'Renk seç';

  @override
  String get nameAndSurname => 'Ad & Soyad';

  @override
  String get addBirthday => 'Doğum günü ekle';

  @override
  String get birthday => 'Doğum günü';

  @override
  String birthdayColon(String date) {
    return 'Doğum günü: $date';
  }

  @override
  String get lessonCostColon => 'Ders ücreti:';

  @override
  String get completedLessons => 'Tamamlanan dersler';

  @override
  String get lessonsWithStatusCompleted => 'Tamamlandı durumundaki dersler';

  @override
  String get total => 'Toplam';

  @override
  String get cancelled => 'İptal';

  @override
  String get completedList => 'Tamamlanan liste';

  @override
  String get noCompletedLessonsYet => 'Henüz tamamlanan ders yok.';

  @override
  String get noPaymentData => 'Ödeme verisi yok.';

  @override
  String get totalPaid => 'Toplam ödenen';

  @override
  String get prepaid => 'Ön ödemeli';

  @override
  String get debtsUnpaid => 'Borçlar (ödenmemiş)';

  @override
  String get cashflow => 'Nakit akışı';

  @override
  String get collected => 'Tahsil edilen';

  @override
  String get refunded => 'İade';

  @override
  String get net => 'Net';

  @override
  String get settled => 'Mahsup';

  @override
  String get lessonTotal => 'Ders toplamı';

  @override
  String get noStudentsInGroup => 'Bu grupta öğrenci yok.';

  @override
  String get inactiveInGroup => 'Grupta pasif';

  @override
  String addToGroup(String name) {
    return '$name grubuna ekle';
  }

  @override
  String get chooseStudentToAdd => 'Eklenecek öğrenciyi seçin…';

  @override
  String get allStudentsAlreadyInGroup => 'Tüm öğrenciler zaten bu grupta.';

  @override
  String get removeFromGroup => 'Gruptan çıkar';

  @override
  String removeStudentFromGroup(String student, String group) {
    return '$student, $group grubundan çıkarılsın mı?';
  }

  @override
  String get editGroup => 'Grubu düzenle';

  @override
  String get groupName => 'Grup adı';

  @override
  String get color => 'Renk';

  @override
  String get colorHint => 'Renk (#33FF57)';

  @override
  String get addGroupTitle => 'Grup Ekle';

  @override
  String get schedule => 'Program';

  @override
  String get journal => 'Günlük';

  @override
  String get payment => 'Ödeme';

  @override
  String get markCompleted => 'Tamamlandı işaretle';

  @override
  String get cancelLesson => 'Dersi iptal et';

  @override
  String get deleteLesson => 'Dersi Sil';

  @override
  String deleteLessonConfirm(String title) {
    return '\"$title\" kalıcı olarak silinsin mi?';
  }

  @override
  String get overview => 'Özet';

  @override
  String get monthly => 'Aylık';

  @override
  String get receivables => 'Alacaklar';

  @override
  String get deletePayment => 'Ödemeyi Sil';

  @override
  String deletePaymentConfirm(String amount) {
    return '$amount ödemesi kaldırılsın mı? Bağlı ders ödenmemişe dönebilir.';
  }

  @override
  String failedToLoad(String label, String error) {
    return '$label yüklenemedi: $error';
  }

  @override
  String get failedToLoadDailyChart => 'Günlük grafik yüklenemedi.';

  @override
  String get noOverviewData => 'Özet verisi yok.';

  @override
  String get noReceivablesData => 'Alacak verisi yok.';

  @override
  String get noPrepaidData => 'Ön ödeme verisi yok.';

  @override
  String get noPaymentsYet => 'Henüz ödeme yok.';

  @override
  String get recordPayment => 'Ödeme kaydet';

  @override
  String get noGroupReceivables => 'Grup alacağı yok.';

  @override
  String get noUnallocatedPrepaid => 'Dağıtılmamış ön ödeme kredisi yok.';

  @override
  String get lessonSettlement => 'Ders mahsubu';

  @override
  String billableFreeCounts(int billable, int free) {
    return 'Ücretli: $billable · Ücretsiz: $free';
  }

  @override
  String get earned => 'Kazanılan';

  @override
  String get byStudent => 'Öğrenciye göre';

  @override
  String get byGroup => 'Gruba göre';

  @override
  String get unpaidLessons => 'Ödenmemiş dersler';

  @override
  String get unallocatedCredits => 'Dağıtılmamış krediler';

  @override
  String monthTotals(String month) {
    return '$month toplamları';
  }

  @override
  String get markPaid => 'Ödendi işaretle';

  @override
  String get paid => 'Ödendi';

  @override
  String get unpaid => 'Ödenmedi';

  @override
  String get scheduled => 'Planlandı';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get paidLessons => 'Ödenen dersler';

  @override
  String get prepaidLessons => 'Ön ödemeli dersler';

  @override
  String collectedLabel(String amount, String currency) {
    return '$amount $currency tahsil';
  }

  @override
  String cashNetLine(String collected, String refunded, String net) {
    return 'Nakit +$collected / -$refunded · Net $net';
  }

  @override
  String cashLine(String collected, String refunded) {
    return 'Nakit +$collected / -$refunded';
  }

  @override
  String get recordPaymentTitle => 'Ödeme Kaydet';

  @override
  String get amount => 'Tutar';

  @override
  String get kind => 'Tür';

  @override
  String get method => 'Yöntem';

  @override
  String get lessonOptional => 'Ders (isteğe bağlı)';

  @override
  String get kindLesson => 'Ders';

  @override
  String get kindPrepaid => 'Ön ödemeli';

  @override
  String get kindRefund => 'İade';

  @override
  String get methodCash => 'Nakit';

  @override
  String get methodTransfer => 'Transfer';

  @override
  String get methodCard => 'Kart';

  @override
  String get methodOther => 'Diğer';

  @override
  String get selectStudent => 'Öğrenci seç';

  @override
  String get selectLesson => 'Ders seç';

  @override
  String get selectStudentTitle => 'Öğrenci Seç';

  @override
  String get selectLessonTitle => 'Ders Seç';

  @override
  String get noLesson => 'Ders yok';

  @override
  String get noStudentsAvailable => 'Kullanılabilir öğrenci yok.';

  @override
  String get noLessonsFound => 'Bu filtre için ders bulunamadı.';

  @override
  String get applyToLessonStatus => 'Ders durumuna uygula';

  @override
  String get optionalNotes => 'İsteğe bağlı notlar';

  @override
  String get enterValidAmount => 'Geçerli bir tutar girin.';

  @override
  String get selectStudentOrLesson => 'Bir öğrenci veya ders seçin.';

  @override
  String get addSchedule => 'Programa Ekle';

  @override
  String get addLesson => 'Ders Ekle';

  @override
  String get editSchedule => 'Programı Düzenle';

  @override
  String get editLesson => 'Dersi Düzenle';

  @override
  String get deleteLessonConfirmShort => 'Bu ders kalıcı olarak silinsin mi?';

  @override
  String get target => 'Hedef';

  @override
  String get date => 'Tarih';

  @override
  String get startTime => 'Başlangıç saati';

  @override
  String get duration => 'Süre';

  @override
  String get status => 'Durum';

  @override
  String get titleOptional => 'Başlık (isteğe bağlı)';

  @override
  String get price => 'Ücret';

  @override
  String get selectGroup => 'Grup seç';

  @override
  String get selectGroupTitle => 'Grup Seç';

  @override
  String get freeLesson => 'Ücretsiz ders';

  @override
  String minutes(int count) {
    return '$count dk';
  }

  @override
  String get selectAGroup => 'Bir grup seçin.';

  @override
  String get selectAStudent => 'Bir öğrenci seçin.';

  @override
  String get enterValidPrice => 'Geçerli bir ücret girin.';

  @override
  String get dismiss => 'Kapat';

  @override
  String lessonsCount(int count) {
    return '$count ders';
  }

  @override
  String unpaidLessonsCount(int count) {
    return '$count ödenmemiş ders';
  }

  @override
  String lessonsOldest(int count, String date) {
    return '$count ders · en eski $date';
  }

  @override
  String get account => 'Hesap';

  @override
  String get profile => 'Profil';

  @override
  String get teaching => 'Ders';

  @override
  String get preferences => 'Tercihler';

  @override
  String get about => 'Hakkında';

  @override
  String get defaultIndividualCost => 'Varsayılan bireysel ücret';

  @override
  String get defaultGroupCost => 'Varsayılan grup ücreti';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get notificationsSubtitle => 'Ders hatırlatmaları ve ödeme uyarıları';

  @override
  String get appearance => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get language => 'Dil';

  @override
  String get languageFollowsDevice => 'Cihaz dilini takip eder';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Rusça';

  @override
  String get appVersion => 'Sürüm';

  @override
  String get editProfile => 'Profili düzenle';

  @override
  String get editProfileComingSoon => 'Profil düzenleme yakında eklenecek.';

  @override
  String get logoutConfirmTitle => 'Çıkış yapılsın mı?';

  @override
  String get logoutConfirmMessage =>
      'Devam etmek için tekrar giriş yapmanız gerekir.';

  @override
  String get costPlaceholder => 'Örn. 500';

  @override
  String get currency => 'Para birimi';

  @override
  String get lessonDetail => 'Ders detayı';

  @override
  String signedInWith(String provider) {
    return '$provider ile giriş yapıldı';
  }

  @override
  String get support => 'Destek';

  @override
  String get supportMessage =>
      'Soru veya geri bildirim için bize yazabilirsiniz.';

  @override
  String get teachingDefaultsHint =>
      'Yeni ders oluştururken varsayılan ücret olarak kullanılır.';

  @override
  String get selectTimeSlot => 'Saat dilimi seç';

  @override
  String get selectTimeSlotHint =>
      'Gün ve saati seçmek için vurgulanan bir hücreye dokun.';

  @override
  String selectedSlot(String date, String time) {
    return '$date · $time';
  }

  @override
  String get markLessonDone => 'Dersi yaptım';

  @override
  String get movedToJournal => 'Tamamlandı olarak günlüğe taşındı.';

  @override
  String get settlePaymentTitle => 'Bu dersin ödemesi';

  @override
  String get leaveUnpaid => 'Ödenmedi bırak';

  @override
  String get markPaidNow => 'Ödendi olarak işaretle';

  @override
  String get applyPrepaidCredit => 'Ön ödeme kredisi uygula';

  @override
  String get editLessonAction => 'Dersi düzenle';

  @override
  String get studentNotes => 'Öğrenci notları';

  @override
  String studentNotePlaceholder(String name) {
    return '$name için not';
  }

  @override
  String get noGroupMembers => 'Bu grupta henüz üye yok.';

  @override
  String get packageCredit => 'Paket kredisi';

  @override
  String approxLessonsLeft(int count) {
    return '~$count ders kaldı';
  }

  @override
  String get applyCredit => 'Krediyi uygula';

  @override
  String get applyCreditToLesson => 'Krediyi bir derse uygula';

  @override
  String get noUnpaidLessons => 'Bu öğrenci için ödenmemiş ders yok.';

  @override
  String get creditApplied => 'Ön ödeme kredisi uygulandı.';

  @override
  String get loadPackage => 'Paket yükle';

  @override
  String get loadPackageHint =>
      'Öğrenci için peşin ödemeyi paket kredisi olarak kaydet.';

  @override
  String get unallocatedCreditTotal => 'Dağıtılmamış kredi';

  @override
  String get prepaidWalletHint => 'Derslere uygulanmayı bekleyen krediler.';

  @override
  String get selectUnpaidLesson => 'Ödenmemiş ders seç';

  @override
  String get lessonNotesSummary => 'Notlar';

  @override
  String get pickLessonFromCalendar => 'Ders seç';

  @override
  String get pickUnpaidLessonHint =>
      'Haftalık takvimde ödenmemiş bir günlük dersine dokun.';

  @override
  String get pickLessonHint => 'Haftalık takvimde bir günlük dersine dokun.';

  @override
  String get noLessonsThisWeek =>
      'Bu hafta uygun ders yok. Başka bir haftayı dene.';

  @override
  String get clearLesson => 'Temizle';

  @override
  String get premium => 'Premium';

  @override
  String get paywallTitle => 'Limitsiz öğret';

  @override
  String get paywallSubtitle =>
      'Öğretmenlik pratiğini büyütmek için tüm araçların kilidini aç.';

  @override
  String get paywallReasonStudents =>
      'Ücretsiz planda 4 aktif öğrenci limitine ulaştın.';

  @override
  String get paywallReasonGroups => 'Ücretsiz planda 4 grup limitine ulaştın.';

  @override
  String get paywallReasonSchedule =>
      'Ücretsiz planda 24 program dersi limitine ulaştın.';

  @override
  String get paywallReasonJournal =>
      'Ücretsiz planda 24 günlük dersi limitine ulaştın.';

  @override
  String get paywallFeatureStudents => 'Sınırsız aktif öğrenci';

  @override
  String get paywallFeatureSchedule => 'Sınırsız program dersi';

  @override
  String get paywallFeatureJournal => 'Sınırsız günlük dersi';

  @override
  String get paywallFeatureGroups => 'Sınırsız grup';

  @override
  String get planWeekly => 'Haftalık';

  @override
  String get planMonthly => 'Aylık';

  @override
  String get planYearly => 'Yıllık';

  @override
  String get planWeeklyHint => 'Esnek faturalama';

  @override
  String get planMonthlyHint => 'Aylık yenilenir';

  @override
  String get planYearlyHint => 'Yıllık en avantajlı';

  @override
  String get popular => 'Popüler';

  @override
  String get bestValue => 'En iyi değer';

  @override
  String get continueToPremium => 'Premium’u aç';

  @override
  String get restorePurchases => 'Satın alımları geri yükle';

  @override
  String get paywallProductsUnavailable =>
      'App Store ürünleri henüz yüklenemedi. RevenueCat ve ürün kimliklerini kontrol et.';

  @override
  String get paywallNoPurchases => 'Geri yüklenecek satın alma bulunamadı.';

  @override
  String get paywallLegal =>
      'Ödeme App Store hesabına yansır. Abonelikleri Ayarlar’dan yönetebilirsin.';

  @override
  String get choosePlan => 'Plan seç';

  @override
  String get freePlanUsage => 'Ücretsiz kullanımın';

  @override
  String usageStudents(int used, int limit) {
    return 'Öğrenciler: $used/$limit';
  }

  @override
  String usageSchedule(int used, int limit) {
    return 'Program dersleri: $used/$limit';
  }

  @override
  String usageJournal(int used, int limit) {
    return 'Günlük dersleri: $used/$limit';
  }

  @override
  String get manageSubscription => 'Abonelik';

  @override
  String get premiumActive => 'Premium aktif';

  @override
  String get premiumFree => 'Ücretsiz plan';

  @override
  String get upgradeToPremium => 'Premium’a yükselt';
}
