// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Tutor App';

  @override
  String get tabStudents => 'Ученики';

  @override
  String get tabSchedule => 'Расписание';

  @override
  String get tabJournal => 'Журнал';

  @override
  String get tabPayment => 'Оплата';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get delete => 'Удалить';

  @override
  String get edit => 'Изменить';

  @override
  String get add => 'Добавить';

  @override
  String get back => 'Назад';

  @override
  String get close => 'Закрыть';

  @override
  String get retry => 'Повторить';

  @override
  String get next => 'Далее';

  @override
  String get done => 'Готово';

  @override
  String get select => 'Выбрать';

  @override
  String get remove => 'Убрать';

  @override
  String get today => 'Сегодня';

  @override
  String get loading => 'Загрузка…';

  @override
  String get somethingWentWrong => 'Что-то пошло не так';

  @override
  String get oauthError => 'Ошибка OAuth';

  @override
  String get oauthLoginFailed => 'Не удалось войти через OAuth.';

  @override
  String get authTitle => 'Вход';

  @override
  String get welcomeTitle => 'Добро пожаловать в Tutor App';

  @override
  String get createAccountTitle => 'Создайте аккаунт';

  @override
  String get authSubtitle =>
      'Планируйте уроки, ведите заметки и управляйте репетиторством.';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get orContinueWith => 'или продолжить через';

  @override
  String get dontHaveAccount => 'Нет аккаунта?';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт?';

  @override
  String stepOf(int current, int total) {
    return 'Шаг $current из $total';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get name => 'Имя';

  @override
  String get phone => 'Телефон';

  @override
  String get passwordConfirmation => 'Подтверждение пароля';

  @override
  String get individualLessonCostOptional =>
      'Стоимость индивидуального урока (необязательно)';

  @override
  String get groupLessonCostOptional =>
      'Стоимость группового урока (необязательно)';

  @override
  String get emailPasswordRequired => 'Укажите email и пароль.';

  @override
  String get nameRequired => 'Укажите имя.';

  @override
  String get emailRequired => 'Укажите email.';

  @override
  String get passwordRequired => 'Укажите пароль.';

  @override
  String get passwordConfirmationRequired => 'Подтвердите пароль.';

  @override
  String get couldNotOpenOAuth => 'Не удалось открыть страницу OAuth.';

  @override
  String get oauthCouldNotStart => 'Не удалось начать вход через OAuth.';

  @override
  String get oauthInvalidGrantHint =>
      'Сессия Google истекла или redirect URI не совпадает. Закройте браузер, проверьте в Google Cloud адрес http://127.0.0.1:8000/api/auth/google/callback и попробуйте снова из приложения.';

  @override
  String get settings => 'Настройки';

  @override
  String signedInAs(String name) {
    return 'Вы вошли как $name';
  }

  @override
  String get logout => 'Выйти';

  @override
  String get students => 'Ученики';

  @override
  String get groups => 'Группы';

  @override
  String studentCount(int count) {
    return '$count ученик(ов)';
  }

  @override
  String groupCount(int count) {
    return '$count групп(ы)';
  }

  @override
  String get searchByNameOrPhone => 'Поиск по имени или телефону';

  @override
  String get searchGroups => 'Поиск групп';

  @override
  String get noGroupsYet => 'Пока нет групп';

  @override
  String get noGroupsHint => 'Создайте группу, чтобы объединить учеников.';

  @override
  String get addGroup => 'Добавить группу';

  @override
  String get noStudentsYet => 'Пока нет учеников';

  @override
  String get noStudentsHint =>
      'Добавьте первого ученика, чтобы начать учёт уроков.';

  @override
  String get addStudent => 'Добавить ученика';

  @override
  String get group => 'Группа';

  @override
  String costPerLesson(String cost) {
    return '$cost / урок';
  }

  @override
  String get deleteStudent => 'Удалить ученика';

  @override
  String deleteStudentConfirm(String name) {
    return 'Удалить $name? Статус станет неактивным.';
  }

  @override
  String get deleteGroup => 'Удалить группу';

  @override
  String deleteGroupConfirm(String name) {
    return 'Удалить $name? Статус станет неактивным.';
  }

  @override
  String get studentDetail => 'Карточка ученика';

  @override
  String get info => 'Инфо';

  @override
  String get lessons => 'Уроки';

  @override
  String get payments => 'Платежи';

  @override
  String get student => 'Ученик';

  @override
  String get call => 'Позвонить';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get lessonFee => 'Стоимость урока';

  @override
  String get notSet => 'Не указано';

  @override
  String get perLesson => 'за урок';

  @override
  String get noBirthdayAdded => 'День рождения не добавлен';

  @override
  String get notes => 'Заметки';

  @override
  String lastLesson(String date) {
    return 'Последний урок: $date';
  }

  @override
  String get tapPhotoToChange => 'Нажмите, чтобы изменить или удалить фото';

  @override
  String get studentName => 'Имя ученика';

  @override
  String get eg500 => 'напр. 500';

  @override
  String get addShortNote => 'Краткая заметка…';

  @override
  String get deleteStudentAction => 'Удалить ученика';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get profilePhoto => 'Фото профиля';

  @override
  String get chooseFromGallery => 'Выбрать из галереи';

  @override
  String get camera => 'Камера';

  @override
  String get removePhoto => 'Удалить фото';

  @override
  String get addPhoneFirst => 'Сначала добавьте номер телефона.';

  @override
  String get couldNotStartCall => 'Не удалось начать звонок.';

  @override
  String get couldNotOpenWhatsApp => 'Не удалось открыть WhatsApp.';

  @override
  String get unsavedChanges => 'Несохранённые изменения';

  @override
  String get saveBeforeLeaving => 'Сохранить изменения перед выходом?';

  @override
  String get dontSave => 'Не сохранять';

  @override
  String get studentUpdated => 'Ученик успешно обновлён.';

  @override
  String get deleteStudentContinue => 'Ученик станет неактивным. Продолжить?';

  @override
  String get addStudentTitle => 'Новый ученик';

  @override
  String get pickAColor => 'Выбрать цвет';

  @override
  String get nameAndSurname => 'Имя и фамилия';

  @override
  String get addBirthday => 'Добавить день рождения';

  @override
  String get birthday => 'День рождения';

  @override
  String birthdayColon(String date) {
    return 'День рождения: $date';
  }

  @override
  String get lessonCostColon => 'Стоимость урока:';

  @override
  String get completedLessons => 'Завершённые уроки';

  @override
  String get lessonsWithStatusCompleted => 'Уроки со статусом «завершён»';

  @override
  String get total => 'Итого';

  @override
  String get cancelled => 'Отменён';

  @override
  String get completedList => 'Список завершённых';

  @override
  String get noCompletedLessonsYet => 'Завершённых уроков пока нет.';

  @override
  String get noPaymentData => 'Нет данных об оплате.';

  @override
  String get totalPaid => 'Всего оплачено';

  @override
  String get prepaid => 'Предоплата';

  @override
  String get debtsUnpaid => 'Долги (не оплачено)';

  @override
  String get cashflow => 'Денежный поток';

  @override
  String get collected => 'Получено';

  @override
  String get refunded => 'Возврат';

  @override
  String get net => 'Нетто';

  @override
  String get settled => 'Зачтено';

  @override
  String get lessonTotal => 'Сумма уроков';

  @override
  String get noStudentsInGroup => 'В этой группе нет учеников.';

  @override
  String get inactiveInGroup => 'Неактивен в группе';

  @override
  String addToGroup(String name) {
    return 'Добавить в $name';
  }

  @override
  String get chooseStudentToAdd => 'Выберите ученика…';

  @override
  String get allStudentsAlreadyInGroup => 'Все ученики уже в этой группе.';

  @override
  String get removeFromGroup => 'Убрать из группы';

  @override
  String removeStudentFromGroup(String student, String group) {
    return 'Убрать $student из $group?';
  }

  @override
  String get editGroup => 'Редактировать группу';

  @override
  String get groupName => 'Название группы';

  @override
  String get color => 'Цвет';

  @override
  String get colorHint => 'Цвет (#33FF57)';

  @override
  String get addGroupTitle => 'Новая группа';

  @override
  String get schedule => 'Расписание';

  @override
  String get journal => 'Журнал';

  @override
  String get payment => 'Оплата';

  @override
  String get markCompleted => 'Отметить выполненным';

  @override
  String get cancelLesson => 'Отменить урок';

  @override
  String get deleteLesson => 'Удалить урок';

  @override
  String deleteLessonConfirm(String title) {
    return 'Удалить «$title» навсегда?';
  }

  @override
  String get overview => 'Обзор';

  @override
  String get monthly => 'По месяцам';

  @override
  String get receivables => 'Дебиторка';

  @override
  String get deletePayment => 'Удалить платёж';

  @override
  String deletePaymentConfirm(String amount) {
    return 'Удалить платёж $amount? Связанный урок может стать неоплаченным.';
  }

  @override
  String failedToLoad(String label, String error) {
    return 'Не удалось загрузить $label: $error';
  }

  @override
  String get failedToLoadDailyChart => 'Не удалось загрузить дневной график.';

  @override
  String get noOverviewData => 'Нет данных обзора.';

  @override
  String get noReceivablesData => 'Нет данных по дебиторке.';

  @override
  String get noPrepaidData => 'Нет данных по предоплате.';

  @override
  String get noPaymentsYet => 'Платежей пока нет.';

  @override
  String get recordPayment => 'Записать платёж';

  @override
  String get noGroupReceivables => 'Нет групповой дебиторки.';

  @override
  String get noUnallocatedPrepaid => 'Нет нераспределённых предоплат.';

  @override
  String get lessonSettlement => 'Зачёт уроков';

  @override
  String billableFreeCounts(int billable, int free) {
    return 'Платные: $billable · Бесплатные: $free';
  }

  @override
  String get earned => 'Заработано';

  @override
  String get byStudent => 'По ученикам';

  @override
  String get byGroup => 'По группам';

  @override
  String get unpaidLessons => 'Неоплаченные уроки';

  @override
  String get unallocatedCredits => 'Нераспределённый кредит';

  @override
  String monthTotals(String month) {
    return 'Итоги за $month';
  }

  @override
  String get markPaid => 'Отметить оплаченным';

  @override
  String get paid => 'Оплачено';

  @override
  String get unpaid => 'Не оплачено';

  @override
  String get scheduled => 'Запланировано';

  @override
  String get completed => 'Завершено';

  @override
  String get paidLessons => 'Оплаченные уроки';

  @override
  String get prepaidLessons => 'Уроки из предоплаты';

  @override
  String collectedLabel(String amount, String currency) {
    return '$amount $currency получено';
  }

  @override
  String cashNetLine(String collected, String refunded, String net) {
    return 'Нал +$collected / -$refunded · Нетто $net';
  }

  @override
  String cashLine(String collected, String refunded) {
    return 'Нал +$collected / -$refunded';
  }

  @override
  String get recordPaymentTitle => 'Записать платёж';

  @override
  String get amount => 'Сумма';

  @override
  String get kind => 'Тип';

  @override
  String get method => 'Способ';

  @override
  String get lessonOptional => 'Урок (необязательно)';

  @override
  String get kindLesson => 'Урок';

  @override
  String get kindPrepaid => 'Предоплата';

  @override
  String get kindRefund => 'Возврат';

  @override
  String get methodCash => 'Наличные';

  @override
  String get methodTransfer => 'Перевод';

  @override
  String get methodCard => 'Карта';

  @override
  String get methodOther => 'Другое';

  @override
  String get selectStudent => 'Выбрать ученика';

  @override
  String get selectLesson => 'Выбрать урок';

  @override
  String get selectStudentTitle => 'Выбор ученика';

  @override
  String get selectLessonTitle => 'Выбор урока';

  @override
  String get noLesson => 'Без урока';

  @override
  String get noStudentsAvailable => 'Нет доступных учеников.';

  @override
  String get noLessonsFound => 'Уроков по этому фильтру нет.';

  @override
  String get applyToLessonStatus => 'Применить к статусу урока';

  @override
  String get optionalNotes => 'Заметка (необязательно)';

  @override
  String get enterValidAmount => 'Введите корректную сумму.';

  @override
  String get selectStudentOrLesson => 'Выберите ученика или урок.';

  @override
  String get addSchedule => 'Добавить в расписание';

  @override
  String get addLesson => 'Добавить урок';

  @override
  String get editSchedule => 'Изменить расписание';

  @override
  String get editLesson => 'Изменить урок';

  @override
  String get deleteLessonConfirmShort => 'Удалить этот урок навсегда?';

  @override
  String get target => 'Кому';

  @override
  String get date => 'Дата';

  @override
  String get startTime => 'Время начала';

  @override
  String get duration => 'Длительность';

  @override
  String get status => 'Статус';

  @override
  String get titleOptional => 'Название (необязательно)';

  @override
  String get price => 'Цена';

  @override
  String get selectGroup => 'Выбрать группу';

  @override
  String get selectGroupTitle => 'Выбор группы';

  @override
  String get freeLesson => 'Бесплатный урок';

  @override
  String minutes(int count) {
    return '$count мин';
  }

  @override
  String get selectAGroup => 'Выберите группу.';

  @override
  String get selectAStudent => 'Выберите ученика.';

  @override
  String get enterValidPrice => 'Введите корректную цену.';

  @override
  String get dismiss => 'Закрыть';

  @override
  String lessonsCount(int count) {
    return '$count уроков';
  }

  @override
  String unpaidLessonsCount(int count) {
    return '$count неоплаченных уроков';
  }

  @override
  String lessonsOldest(int count, String date) {
    return '$count уроков · старейший $date';
  }

  @override
  String get account => 'Аккаунт';

  @override
  String get profile => 'Профиль';

  @override
  String get teaching => 'Преподавание';

  @override
  String get preferences => 'Предпочтения';

  @override
  String get about => 'О приложении';

  @override
  String get defaultIndividualCost => 'Стандартная цена индивидуального';

  @override
  String get defaultGroupCost => 'Стандартная цена группового';

  @override
  String get notifications => 'Уведомления';

  @override
  String get notificationsSubtitle => 'Напоминания об уроках и оплате';

  @override
  String get appearance => 'Оформление';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get language => 'Язык';

  @override
  String get languageFollowsDevice => 'Как на устройстве';

  @override
  String get languageEnglish => 'Английский';

  @override
  String get languageTurkish => 'Турецкий';

  @override
  String get languageRussian => 'Русский';

  @override
  String get appVersion => 'Версия';

  @override
  String get editProfile => 'Редактировать профиль';

  @override
  String get editProfileComingSoon => 'Редактирование профиля скоро появится.';

  @override
  String get logoutConfirmTitle => 'Выйти?';

  @override
  String get logoutConfirmMessage =>
      'Чтобы продолжить, нужно будет войти снова.';

  @override
  String get costPlaceholder => 'напр. 500';

  @override
  String get currency => 'Валюта';

  @override
  String signedInWith(String provider) {
    return 'Вход через $provider';
  }

  @override
  String get support => 'Поддержка';

  @override
  String get supportMessage =>
      'Вопросы или отзывы? Напишите нам в любое время.';

  @override
  String get teachingDefaultsHint =>
      'Используется как цена по умолчанию при создании уроков.';

  @override
  String get selectTimeSlot => 'Выберите время';

  @override
  String get selectTimeSlotHint =>
      'Нажмите на ячейку, чтобы выбрать день и время.';

  @override
  String selectedSlot(String date, String time) {
    return '$date · $time';
  }

  @override
  String get markLessonDone => 'Отметить выполненным';

  @override
  String get movedToJournal => 'Перенесено в журнал как завершённое.';

  @override
  String get settlePaymentTitle => 'Оплата за этот урок';

  @override
  String get leaveUnpaid => 'Оставить неоплаченным';

  @override
  String get markPaidNow => 'Отметить оплаченным';

  @override
  String get applyPrepaidCredit => 'Списать с предоплаты';

  @override
  String get editLessonAction => 'Изменить урок';

  @override
  String get studentNotes => 'Заметки по ученикам';

  @override
  String studentNotePlaceholder(String name) {
    return 'Заметка для $name';
  }

  @override
  String get noGroupMembers => 'В этой группе пока нет участников.';

  @override
  String get packageCredit => 'Кредит пакета';

  @override
  String approxLessonsLeft(int count) {
    return '~$count уроков осталось';
  }

  @override
  String get applyCredit => 'Применить кредит';

  @override
  String get applyCreditToLesson => 'Применить кредит к уроку';

  @override
  String get noUnpaidLessons => 'У этого ученика нет неоплаченных уроков.';

  @override
  String get creditApplied => 'Предоплата применена.';

  @override
  String get loadPackage => 'Пополнить пакет';

  @override
  String get loadPackageHint =>
      'Записать предоплату как кредит пакета для ученика.';

  @override
  String get unallocatedCreditTotal => 'Нераспределённый кредит';

  @override
  String get prepaidWalletHint => 'Кредиты, ожидающие применения к урокам.';

  @override
  String get selectUnpaidLesson => 'Выбрать неоплаченный урок';

  @override
  String get lessonNotesSummary => 'Заметки';

  @override
  String get pickLessonFromCalendar => 'Выбрать урок';

  @override
  String get pickUnpaidLessonHint =>
      'Нажмите неоплаченный урок журнала на сетке недели.';

  @override
  String get pickLessonHint => 'Нажмите урок журнала на сетке недели.';

  @override
  String get noLessonsThisWeek =>
      'На этой неделе подходящих уроков нет. Попробуйте другую неделю.';

  @override
  String get clearLesson => 'Очистить';

  @override
  String get premium => 'Premium';

  @override
  String get paywallTitle => 'Учите без ограничений';

  @override
  String get paywallSubtitle =>
      'Откройте полный набор инструментов для роста практики.';

  @override
  String get paywallReasonStudents =>
      'Достигнут лимит бесплатного плана: 4 активных ученика.';

  @override
  String get paywallReasonSchedule =>
      'Достигнут лимит бесплатного плана: 24 урока в расписании.';

  @override
  String get paywallReasonJournal =>
      'Достигнут лимит бесплатного плана: 24 урока в журнале.';

  @override
  String get paywallFeatureStudents => 'Неограниченное число учеников';

  @override
  String get paywallFeatureSchedule => 'Неограниченное расписание';

  @override
  String get paywallFeatureJournal => 'Неограниченный журнал';

  @override
  String get planWeekly => 'Неделя';

  @override
  String get planMonthly => 'Месяц';

  @override
  String get planYearly => 'Год';

  @override
  String get planWeeklyHint => 'Гибкая оплата';

  @override
  String get planMonthlyHint => 'Ежемесячно';

  @override
  String get planYearlyHint => 'Выгоднее за год';

  @override
  String get popular => 'Популярный';

  @override
  String get bestValue => 'Лучшая цена';

  @override
  String get continueToPremium => 'Открыть Premium';

  @override
  String get restorePurchases => 'Восстановить покупки';

  @override
  String get paywallProductsUnavailable =>
      'Товары App Store ещё не загрузились. Проверьте RevenueCat и ID продуктов.';

  @override
  String get paywallNoPurchases => 'Покупки для восстановления не найдены.';

  @override
  String get paywallLegal =>
      'Оплата списывается с аккаунта App Store. Управляйте подписками в Настройках.';

  @override
  String get choosePlan => 'Выберите план';

  @override
  String get freePlanUsage => 'Текущее использование бесплатного плана';

  @override
  String usageStudents(int used, int limit) {
    return 'Ученики: $used/$limit';
  }

  @override
  String usageSchedule(int used, int limit) {
    return 'Уроки в расписании: $used/$limit';
  }

  @override
  String usageJournal(int used, int limit) {
    return 'Уроки в журнале: $used/$limit';
  }

  @override
  String get manageSubscription => 'Подписка';

  @override
  String get premiumActive => 'Premium активен';

  @override
  String get premiumFree => 'Бесплатный план';

  @override
  String get upgradeToPremium => 'Перейти на Premium';
}
