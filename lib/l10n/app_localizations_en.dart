// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Tutor App';

  @override
  String get tabStudents => 'Students';

  @override
  String get tabSchedule => 'Schedule';

  @override
  String get tabJournal => 'Journal';

  @override
  String get tabPayment => 'Payment';

  @override
  String get tabSettings => 'Settings';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Retry';

  @override
  String get next => 'Next';

  @override
  String get done => 'Done';

  @override
  String get select => 'Select';

  @override
  String get remove => 'Remove';

  @override
  String get today => 'Today';

  @override
  String get loading => 'Loading…';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get oauthError => 'OAuth Error';

  @override
  String get oauthLoginFailed => 'OAuth login failed.';

  @override
  String get authTitle => 'Auth';

  @override
  String get welcomeTitle => 'Welcome to Tutor App';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get authSubtitle =>
      'Plan lessons, track notes, and manage your tutoring workflow.';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get createAccount => 'Create Account';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get passwordConfirmation => 'Password Confirmation';

  @override
  String get individualLessonCostOptional =>
      'Individual Lesson Cost (optional)';

  @override
  String get groupLessonCostOptional => 'Group Lesson Cost (optional)';

  @override
  String get emailPasswordRequired => 'Email and password are required.';

  @override
  String get nameRequired => 'Name is required.';

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get passwordConfirmationRequired =>
      'Password confirmation is required.';

  @override
  String get couldNotOpenOAuth => 'Could not open OAuth page.';

  @override
  String get oauthCouldNotStart => 'OAuth flow could not be started.';

  @override
  String get oauthInvalidGrantHint =>
      'Google sign-in expired or the redirect URI does not match. Close the browser, confirm Google Cloud has http://127.0.0.1:8000/api/auth/google/callback, then try again from the app.';

  @override
  String get settings => 'Settings';

  @override
  String signedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get logout => 'Logout';

  @override
  String get students => 'Students';

  @override
  String get groups => 'Groups';

  @override
  String studentCount(int count) {
    return '$count student(s)';
  }

  @override
  String groupCount(int count) {
    return '$count group(s)';
  }

  @override
  String get searchByNameOrPhone => 'Search by name or phone';

  @override
  String get searchGroups => 'Search groups';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noGroupsHint => 'Create a group to organize students together.';

  @override
  String get addGroup => 'Add group';

  @override
  String get noStudentsYet => 'No students yet';

  @override
  String get noStudentsHint =>
      'Add your first student to start tracking lessons.';

  @override
  String get addStudent => 'Add student';

  @override
  String get group => 'Group';

  @override
  String costPerLesson(String cost) {
    return '$cost / lesson';
  }

  @override
  String get deleteStudent => 'Delete Student';

  @override
  String deleteStudentConfirm(String name) {
    return 'Delete $name? This will set status to inactive.';
  }

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String deleteGroupConfirm(String name) {
    return 'Delete $name? This will set status to inactive.';
  }

  @override
  String get studentDetail => 'Student Detail';

  @override
  String get info => 'Info';

  @override
  String get lessons => 'Lessons';

  @override
  String get payments => 'Payments';

  @override
  String get student => 'Student';

  @override
  String get call => 'Call';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get lessonFee => 'Lesson fee';

  @override
  String get notSet => 'Not set';

  @override
  String get perLesson => 'per lesson';

  @override
  String get noBirthdayAdded => 'No birthday added';

  @override
  String get notes => 'Notes';

  @override
  String lastLesson(String date) {
    return 'Last lesson: $date';
  }

  @override
  String get tapPhotoToChange => 'Tap photo to change or remove';

  @override
  String get studentName => 'Student name';

  @override
  String get eg500 => 'e.g. 500';

  @override
  String get addShortNote => 'Add a short note…';

  @override
  String get deleteStudentAction => 'Delete student';

  @override
  String get selectDate => 'Select date';

  @override
  String get profilePhoto => 'Profile photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get camera => 'Camera';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get addPhoneFirst => 'Add a phone number first.';

  @override
  String get couldNotStartCall => 'Could not start the call.';

  @override
  String get couldNotOpenWhatsApp => 'Could not open WhatsApp.';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get saveBeforeLeaving => 'Save your changes before leaving?';

  @override
  String get dontSave => 'Don\'t Save';

  @override
  String get studentUpdated => 'Student updated successfully.';

  @override
  String get deleteStudentContinue =>
      'This student will be set inactive. Continue?';

  @override
  String get addStudentTitle => 'Add Student';

  @override
  String get pickAColor => 'Pick a color';

  @override
  String get nameAndSurname => 'Name & Surname';

  @override
  String get addBirthday => 'Add Birthday';

  @override
  String get birthday => 'Birthday';

  @override
  String birthdayColon(String date) {
    return 'Birthday: $date';
  }

  @override
  String get lessonCostColon => 'Lesson Cost:';

  @override
  String get completedLessons => 'Completed lessons';

  @override
  String get lessonsWithStatusCompleted => 'Lessons with status completed';

  @override
  String get total => 'Total';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get completedList => 'Completed list';

  @override
  String get noCompletedLessonsYet => 'No completed lessons yet.';

  @override
  String get noPaymentData => 'No payment data.';

  @override
  String get totalPaid => 'Total paid';

  @override
  String get prepaid => 'Prepaid';

  @override
  String get debtsUnpaid => 'Debts (unpaid)';

  @override
  String get cashflow => 'Cashflow';

  @override
  String get collected => 'Collected';

  @override
  String get refunded => 'Refunded';

  @override
  String get net => 'Net';

  @override
  String get settled => 'Settled';

  @override
  String get lessonTotal => 'Lesson total';

  @override
  String get noStudentsInGroup => 'No students in this group.';

  @override
  String get inactiveInGroup => 'Inactive in group';

  @override
  String addToGroup(String name) {
    return 'Add to $name';
  }

  @override
  String get chooseStudentToAdd => 'Choose a student to add…';

  @override
  String get allStudentsAlreadyInGroup =>
      'All students are already in this group.';

  @override
  String get removeFromGroup => 'Remove from Group';

  @override
  String removeStudentFromGroup(String student, String group) {
    return 'Remove $student from $group?';
  }

  @override
  String get editGroup => 'Edit Group';

  @override
  String get groupName => 'Group name';

  @override
  String get color => 'Color';

  @override
  String get colorHint => 'Color (#33FF57)';

  @override
  String get addGroupTitle => 'Add Group';

  @override
  String get schedule => 'Schedule';

  @override
  String get journal => 'Journal';

  @override
  String get payment => 'Payment';

  @override
  String get markCompleted => 'Mark Completed';

  @override
  String get cancelLesson => 'Cancel Lesson';

  @override
  String get deleteLesson => 'Delete Lesson';

  @override
  String deleteLessonConfirm(String title) {
    return 'Delete \"$title\" permanently?';
  }

  @override
  String get overview => 'Overview';

  @override
  String get monthly => 'Monthly';

  @override
  String get receivables => 'Receivables';

  @override
  String get deletePayment => 'Delete Payment';

  @override
  String deletePaymentConfirm(String amount) {
    return 'Remove $amount payment? Linked lesson may return to unpaid.';
  }

  @override
  String failedToLoad(String label, String error) {
    return 'Failed to load $label: $error';
  }

  @override
  String get failedToLoadDailyChart => 'Failed to load daily chart.';

  @override
  String get noOverviewData => 'No overview data.';

  @override
  String get noReceivablesData => 'No receivables data.';

  @override
  String get noPrepaidData => 'No prepaid data.';

  @override
  String get noPaymentsYet => 'No payments yet.';

  @override
  String get recordPayment => 'Record payment';

  @override
  String get noGroupReceivables => 'No group receivables.';

  @override
  String get noUnallocatedPrepaid => 'No unallocated prepaid credits.';

  @override
  String get lessonSettlement => 'Lesson settlement';

  @override
  String billableFreeCounts(int billable, int free) {
    return 'Billable: $billable · Free: $free';
  }

  @override
  String get earned => 'Earned';

  @override
  String get byStudent => 'By student';

  @override
  String get byGroup => 'By group';

  @override
  String get unpaidLessons => 'Unpaid lessons';

  @override
  String get unallocatedCredits => 'Unallocated credits';

  @override
  String monthTotals(String month) {
    return '$month totals';
  }

  @override
  String get markPaid => 'Mark paid';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get completed => 'Completed';

  @override
  String get paidLessons => 'Paid lessons';

  @override
  String get prepaidLessons => 'Prepaid lessons';

  @override
  String collectedLabel(String amount, String currency) {
    return '$amount $currency Collected';
  }

  @override
  String cashNetLine(String collected, String refunded, String net) {
    return 'Cash +$collected / -$refunded · Net $net';
  }

  @override
  String cashLine(String collected, String refunded) {
    return 'Cash +$collected / -$refunded';
  }

  @override
  String get recordPaymentTitle => 'Record Payment';

  @override
  String get amount => 'Amount';

  @override
  String get kind => 'Kind';

  @override
  String get method => 'Method';

  @override
  String get lessonOptional => 'Lesson (optional)';

  @override
  String get kindLesson => 'Lesson';

  @override
  String get kindPrepaid => 'Prepaid';

  @override
  String get kindRefund => 'Refund';

  @override
  String get methodCash => 'Cash';

  @override
  String get methodTransfer => 'Transfer';

  @override
  String get methodCard => 'Card';

  @override
  String get methodOther => 'Other';

  @override
  String get selectStudent => 'Select student';

  @override
  String get selectLesson => 'Select lesson';

  @override
  String get selectStudentTitle => 'Select Student';

  @override
  String get selectLessonTitle => 'Select Lesson';

  @override
  String get noLesson => 'No lesson';

  @override
  String get noStudentsAvailable => 'No students available.';

  @override
  String get noLessonsFound => 'No lessons found for this filter.';

  @override
  String get applyToLessonStatus => 'Apply to lesson status';

  @override
  String get optionalNotes => 'Optional notes';

  @override
  String get enterValidAmount => 'Enter a valid amount.';

  @override
  String get selectStudentOrLesson => 'Select a student or lesson.';

  @override
  String get addSchedule => 'Add Schedule';

  @override
  String get addLesson => 'Add Lesson';

  @override
  String get editSchedule => 'Edit Schedule';

  @override
  String get editLesson => 'Edit Lesson';

  @override
  String get deleteLessonConfirmShort => 'Delete this lesson permanently?';

  @override
  String get target => 'Target';

  @override
  String get date => 'Date';

  @override
  String get startTime => 'Start time';

  @override
  String get duration => 'Duration';

  @override
  String get status => 'Status';

  @override
  String get titleOptional => 'Title (optional)';

  @override
  String get price => 'Price';

  @override
  String get selectGroup => 'Select group';

  @override
  String get selectGroupTitle => 'Select Group';

  @override
  String get freeLesson => 'Free lesson';

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String get selectAGroup => 'Select a group.';

  @override
  String get selectAStudent => 'Select a student.';

  @override
  String get enterValidPrice => 'Enter a valid price.';

  @override
  String get dismiss => 'Dismiss';

  @override
  String lessonsCount(int count) {
    return '$count lessons';
  }

  @override
  String unpaidLessonsCount(int count) {
    return '$count unpaid lessons';
  }

  @override
  String lessonsOldest(int count, String date) {
    return '$count lessons · oldest $date';
  }

  @override
  String get account => 'Account';

  @override
  String get profile => 'Profile';

  @override
  String get teaching => 'Teaching';

  @override
  String get preferences => 'Preferences';

  @override
  String get about => 'About';

  @override
  String get defaultIndividualCost => 'Default individual fee';

  @override
  String get defaultGroupCost => 'Default group fee';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSubtitle => 'Lesson reminders and payment alerts';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageFollowsDevice => 'Follows device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageTurkish => 'Turkish';

  @override
  String get languageRussian => 'Russian';

  @override
  String get appVersion => 'Version';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get editProfileComingSoon => 'Profile editing will be available soon.';

  @override
  String get logoutConfirmTitle => 'Log out?';

  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again to continue.';

  @override
  String get costPlaceholder => 'e.g. 500';

  @override
  String get currency => 'Currency';

  @override
  String signedInWith(String provider) {
    return 'Signed in with $provider';
  }

  @override
  String get support => 'Support';

  @override
  String get supportMessage => 'Questions or feedback? Email us anytime.';

  @override
  String get teachingDefaultsHint =>
      'Used as the default price when creating new lessons.';

  @override
  String get selectTimeSlot => 'Select a time slot';

  @override
  String get selectTimeSlotHint =>
      'Tap a highlighted cell to choose day and time.';

  @override
  String selectedSlot(String date, String time) {
    return '$date · $time';
  }

  @override
  String get markLessonDone => 'Mark as done';

  @override
  String get movedToJournal => 'Moved to journal as completed.';

  @override
  String get settlePaymentTitle => 'Payment for this lesson';

  @override
  String get leaveUnpaid => 'Leave unpaid';

  @override
  String get markPaidNow => 'Mark as paid';

  @override
  String get applyPrepaidCredit => 'Apply prepaid credit';

  @override
  String get editLessonAction => 'Edit lesson';

  @override
  String get studentNotes => 'Student notes';

  @override
  String studentNotePlaceholder(String name) {
    return 'Note for $name';
  }

  @override
  String get noGroupMembers => 'This group has no members yet.';

  @override
  String get packageCredit => 'Package credit';

  @override
  String approxLessonsLeft(int count) {
    return '~$count lessons left';
  }

  @override
  String get applyCredit => 'Apply credit';

  @override
  String get applyCreditToLesson => 'Apply credit to a lesson';

  @override
  String get noUnpaidLessons => 'No unpaid lessons for this student.';

  @override
  String get creditApplied => 'Prepaid credit applied.';

  @override
  String get loadPackage => 'Load package';

  @override
  String get loadPackageHint =>
      'Record advance payment as package credit for a student.';

  @override
  String get unallocatedCreditTotal => 'Unallocated credit';

  @override
  String get prepaidWalletHint => 'Credits waiting to be applied to lessons.';

  @override
  String get selectUnpaidLesson => 'Select unpaid lesson';

  @override
  String get lessonNotesSummary => 'Notes';

  @override
  String get pickLessonFromCalendar => 'Pick a lesson';

  @override
  String get pickUnpaidLessonHint =>
      'Tap an unpaid journal lesson on the week grid.';

  @override
  String get pickLessonHint => 'Tap a journal lesson on the week grid.';

  @override
  String get noLessonsThisWeek =>
      'No matching lessons this week. Try another week.';

  @override
  String get clearLesson => 'Clear';

  @override
  String get premium => 'Premium';

  @override
  String get paywallTitle => 'Teach without limits';

  @override
  String get paywallSubtitle =>
      'Unlock the full toolkit for growing your tutoring practice.';

  @override
  String get paywallReasonStudents =>
      'You’ve reached the free limit of 4 active students.';

  @override
  String get paywallReasonSchedule =>
      'You’ve reached the free limit of 24 schedule lessons.';

  @override
  String get paywallReasonJournal =>
      'You’ve reached the free limit of 24 journal lessons.';

  @override
  String get paywallFeatureStudents => 'Unlimited active students';

  @override
  String get paywallFeatureSchedule => 'Unlimited schedule lessons';

  @override
  String get paywallFeatureJournal => 'Unlimited journal lessons';

  @override
  String get planWeekly => 'Weekly';

  @override
  String get planMonthly => 'Monthly';

  @override
  String get planYearly => 'Yearly';

  @override
  String get planWeeklyHint => 'Flexible billing';

  @override
  String get planMonthlyHint => 'Billed monthly';

  @override
  String get planYearlyHint => 'Best value annually';

  @override
  String get popular => 'Popular';

  @override
  String get bestValue => 'Best value';

  @override
  String get continueToPremium => 'Unlock Premium';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get paywallProductsUnavailable =>
      'Store products are not available yet. Check RevenueCat and product IDs.';

  @override
  String get paywallNoPurchases => 'No purchases found to restore.';

  @override
  String get paywallLegal =>
      'Payment is charged to your App Store account. Manage subscriptions in Settings.';

  @override
  String get choosePlan => 'Choose a plan';

  @override
  String get freePlanUsage => 'Current free usage';

  @override
  String usageStudents(int used, int limit) {
    return 'Students: $used/$limit';
  }

  @override
  String usageSchedule(int used, int limit) {
    return 'Schedule lessons: $used/$limit';
  }

  @override
  String usageJournal(int used, int limit) {
    return 'Journal lessons: $used/$limit';
  }

  @override
  String get manageSubscription => 'Subscription';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get premiumFree => 'Free plan';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';
}
