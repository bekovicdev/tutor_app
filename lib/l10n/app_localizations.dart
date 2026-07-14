import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Tutor App'**
  String get appTitle;

  /// No description provided for @tabStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get tabStudents;

  /// No description provided for @tabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tabSchedule;

  /// No description provided for @tabJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get tabJournal;

  /// No description provided for @tabPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get tabPayment;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @oauthError.
  ///
  /// In en, this message translates to:
  /// **'OAuth Error'**
  String get oauthError;

  /// No description provided for @oauthLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'OAuth login failed.'**
  String get oauthLoginFailed;

  /// No description provided for @authTitle.
  ///
  /// In en, this message translates to:
  /// **'Auth'**
  String get authTitle;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Tutor App'**
  String get welcomeTitle;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan lessons, track notes, and manage your tutoring workflow.'**
  String get authSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'or continue with'**
  String get orContinueWith;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @stepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @passwordConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Password Confirmation'**
  String get passwordConfirmation;

  /// No description provided for @individualLessonCostOptional.
  ///
  /// In en, this message translates to:
  /// **'Individual Lesson Cost (optional)'**
  String get individualLessonCostOptional;

  /// No description provided for @groupLessonCostOptional.
  ///
  /// In en, this message translates to:
  /// **'Group Lesson Cost (optional)'**
  String get groupLessonCostOptional;

  /// No description provided for @emailPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Email and password are required.'**
  String get emailPasswordRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @passwordConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Password confirmation is required.'**
  String get passwordConfirmationRequired;

  /// No description provided for @couldNotOpenOAuth.
  ///
  /// In en, this message translates to:
  /// **'Could not open OAuth page.'**
  String get couldNotOpenOAuth;

  /// No description provided for @oauthCouldNotStart.
  ///
  /// In en, this message translates to:
  /// **'OAuth flow could not be started.'**
  String get oauthCouldNotStart;

  /// No description provided for @oauthInvalidGrantHint.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in expired or the redirect URI does not match. Close the browser, confirm Google Cloud has http://127.0.0.1:8000/api/auth/google/callback, then try again from the app.'**
  String get oauthInvalidGrantHint;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String signedInAs(String name);

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} student(s)'**
  String studentCount(int count);

  /// No description provided for @groupCount.
  ///
  /// In en, this message translates to:
  /// **'{count} group(s)'**
  String groupCount(int count);

  /// No description provided for @searchByNameOrPhone.
  ///
  /// In en, this message translates to:
  /// **'Search by name or phone'**
  String get searchByNameOrPhone;

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups'**
  String get searchGroups;

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No description provided for @noGroupsHint.
  ///
  /// In en, this message translates to:
  /// **'Create a group to organize students together.'**
  String get noGroupsHint;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add group'**
  String get addGroup;

  /// No description provided for @noStudentsYet.
  ///
  /// In en, this message translates to:
  /// **'No students yet'**
  String get noStudentsYet;

  /// No description provided for @noStudentsHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first student to start tracking lessons.'**
  String get noStudentsHint;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add student'**
  String get addStudent;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @costPerLesson.
  ///
  /// In en, this message translates to:
  /// **'{cost} / lesson'**
  String costPerLesson(String cost);

  /// No description provided for @deleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Delete Student'**
  String get deleteStudent;

  /// No description provided for @deleteStudentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This will set status to inactive.'**
  String deleteStudentConfirm(String name);

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This will set status to inactive.'**
  String deleteGroupConfirm(String name);

  /// No description provided for @studentDetail.
  ///
  /// In en, this message translates to:
  /// **'Student Detail'**
  String get studentDetail;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @lessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get lessons;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @student.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get student;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @whatsApp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsApp;

  /// No description provided for @lessonFee.
  ///
  /// In en, this message translates to:
  /// **'Lesson fee'**
  String get lessonFee;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @perLesson.
  ///
  /// In en, this message translates to:
  /// **'per lesson'**
  String get perLesson;

  /// No description provided for @noBirthdayAdded.
  ///
  /// In en, this message translates to:
  /// **'No birthday added'**
  String get noBirthdayAdded;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @lastLesson.
  ///
  /// In en, this message translates to:
  /// **'Last lesson: {date}'**
  String lastLesson(String date);

  /// No description provided for @tapPhotoToChange.
  ///
  /// In en, this message translates to:
  /// **'Tap photo to change or remove'**
  String get tapPhotoToChange;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student name'**
  String get studentName;

  /// No description provided for @eg500.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get eg500;

  /// No description provided for @addShortNote.
  ///
  /// In en, this message translates to:
  /// **'Add a short note…'**
  String get addShortNote;

  /// No description provided for @deleteStudentAction.
  ///
  /// In en, this message translates to:
  /// **'Delete student'**
  String get deleteStudentAction;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @profilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get profilePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @addPhoneFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a phone number first.'**
  String get addPhoneFirst;

  /// No description provided for @couldNotStartCall.
  ///
  /// In en, this message translates to:
  /// **'Could not start the call.'**
  String get couldNotStartCall;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp.'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @saveBeforeLeaving.
  ///
  /// In en, this message translates to:
  /// **'Save your changes before leaving?'**
  String get saveBeforeLeaving;

  /// No description provided for @dontSave.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Save'**
  String get dontSave;

  /// No description provided for @studentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Student updated successfully.'**
  String get studentUpdated;

  /// No description provided for @deleteStudentContinue.
  ///
  /// In en, this message translates to:
  /// **'This student will be set inactive. Continue?'**
  String get deleteStudentContinue;

  /// No description provided for @addStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudentTitle;

  /// No description provided for @pickAColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get pickAColor;

  /// No description provided for @nameAndSurname.
  ///
  /// In en, this message translates to:
  /// **'Name & Surname'**
  String get nameAndSurname;

  /// No description provided for @addBirthday.
  ///
  /// In en, this message translates to:
  /// **'Add Birthday'**
  String get addBirthday;

  /// No description provided for @birthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get birthday;

  /// No description provided for @birthdayColon.
  ///
  /// In en, this message translates to:
  /// **'Birthday: {date}'**
  String birthdayColon(String date);

  /// No description provided for @lessonCostColon.
  ///
  /// In en, this message translates to:
  /// **'Lesson Cost:'**
  String get lessonCostColon;

  /// No description provided for @completedLessons.
  ///
  /// In en, this message translates to:
  /// **'Completed lessons'**
  String get completedLessons;

  /// No description provided for @lessonsWithStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Lessons with status completed'**
  String get lessonsWithStatusCompleted;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @completedList.
  ///
  /// In en, this message translates to:
  /// **'Completed list'**
  String get completedList;

  /// No description provided for @noCompletedLessonsYet.
  ///
  /// In en, this message translates to:
  /// **'No completed lessons yet.'**
  String get noCompletedLessonsYet;

  /// No description provided for @noPaymentData.
  ///
  /// In en, this message translates to:
  /// **'No payment data.'**
  String get noPaymentData;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total paid'**
  String get totalPaid;

  /// No description provided for @prepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get prepaid;

  /// No description provided for @debtsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Debts (unpaid)'**
  String get debtsUnpaid;

  /// No description provided for @cashflow.
  ///
  /// In en, this message translates to:
  /// **'Cashflow'**
  String get cashflow;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @lessonTotal.
  ///
  /// In en, this message translates to:
  /// **'Lesson total'**
  String get lessonTotal;

  /// No description provided for @noStudentsInGroup.
  ///
  /// In en, this message translates to:
  /// **'No students in this group.'**
  String get noStudentsInGroup;

  /// No description provided for @inactiveInGroup.
  ///
  /// In en, this message translates to:
  /// **'Inactive in group'**
  String get inactiveInGroup;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to {name}'**
  String addToGroup(String name);

  /// No description provided for @chooseStudentToAdd.
  ///
  /// In en, this message translates to:
  /// **'Choose a student to add…'**
  String get chooseStudentToAdd;

  /// No description provided for @allStudentsAlreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'All students are already in this group.'**
  String get allStudentsAlreadyInGroup;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from Group'**
  String get removeFromGroup;

  /// No description provided for @removeStudentFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove {student} from {group}?'**
  String removeStudentFromGroup(String student, String group);

  /// No description provided for @editGroup.
  ///
  /// In en, this message translates to:
  /// **'Edit Group'**
  String get editGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @colorHint.
  ///
  /// In en, this message translates to:
  /// **'Color (#33FF57)'**
  String get colorHint;

  /// No description provided for @addGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroupTitle;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @markCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get markCompleted;

  /// No description provided for @cancelLesson.
  ///
  /// In en, this message translates to:
  /// **'Cancel Lesson'**
  String get cancelLesson;

  /// No description provided for @deleteLesson.
  ///
  /// In en, this message translates to:
  /// **'Delete Lesson'**
  String get deleteLesson;

  /// No description provided for @deleteLessonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" permanently?'**
  String deleteLessonConfirm(String title);

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @receivables.
  ///
  /// In en, this message translates to:
  /// **'Receivables'**
  String get receivables;

  /// No description provided for @deletePayment.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get deletePayment;

  /// No description provided for @deletePaymentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {amount} payment? Linked lesson may return to unpaid.'**
  String deletePaymentConfirm(String amount);

  /// No description provided for @failedToLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load {label}: {error}'**
  String failedToLoad(String label, String error);

  /// No description provided for @failedToLoadDailyChart.
  ///
  /// In en, this message translates to:
  /// **'Failed to load daily chart.'**
  String get failedToLoadDailyChart;

  /// No description provided for @noOverviewData.
  ///
  /// In en, this message translates to:
  /// **'No overview data.'**
  String get noOverviewData;

  /// No description provided for @noReceivablesData.
  ///
  /// In en, this message translates to:
  /// **'No receivables data.'**
  String get noReceivablesData;

  /// No description provided for @noPrepaidData.
  ///
  /// In en, this message translates to:
  /// **'No prepaid data.'**
  String get noPrepaidData;

  /// No description provided for @noPaymentsYet.
  ///
  /// In en, this message translates to:
  /// **'No payments yet.'**
  String get noPaymentsYet;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @noGroupReceivables.
  ///
  /// In en, this message translates to:
  /// **'No group receivables.'**
  String get noGroupReceivables;

  /// No description provided for @noUnallocatedPrepaid.
  ///
  /// In en, this message translates to:
  /// **'No unallocated prepaid credits.'**
  String get noUnallocatedPrepaid;

  /// No description provided for @lessonSettlement.
  ///
  /// In en, this message translates to:
  /// **'Lesson settlement'**
  String get lessonSettlement;

  /// No description provided for @earned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get earned;

  /// No description provided for @byStudent.
  ///
  /// In en, this message translates to:
  /// **'By student'**
  String get byStudent;

  /// No description provided for @byGroup.
  ///
  /// In en, this message translates to:
  /// **'By group'**
  String get byGroup;

  /// No description provided for @unpaidLessons.
  ///
  /// In en, this message translates to:
  /// **'Unpaid lessons'**
  String get unpaidLessons;

  /// No description provided for @unallocatedCredits.
  ///
  /// In en, this message translates to:
  /// **'Unallocated credits'**
  String get unallocatedCredits;

  /// No description provided for @monthTotals.
  ///
  /// In en, this message translates to:
  /// **'{month} totals'**
  String monthTotals(String month);

  /// No description provided for @markPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get markPaid;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @paidLessons.
  ///
  /// In en, this message translates to:
  /// **'Paid lessons'**
  String get paidLessons;

  /// No description provided for @prepaidLessons.
  ///
  /// In en, this message translates to:
  /// **'Prepaid lessons'**
  String get prepaidLessons;

  /// No description provided for @collectedLabel.
  ///
  /// In en, this message translates to:
  /// **'TRY {amount} Collected'**
  String collectedLabel(String amount);

  /// No description provided for @cashNetLine.
  ///
  /// In en, this message translates to:
  /// **'Cash +{collected} / -{refunded} · Net {net}'**
  String cashNetLine(String collected, String refunded, String net);

  /// No description provided for @cashLine.
  ///
  /// In en, this message translates to:
  /// **'Cash +{collected} / -{refunded}'**
  String cashLine(String collected, String refunded);

  /// No description provided for @recordPaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPaymentTitle;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get kind;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @lessonOptional.
  ///
  /// In en, this message translates to:
  /// **'Lesson (optional)'**
  String get lessonOptional;

  /// No description provided for @kindLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get kindLesson;

  /// No description provided for @kindPrepaid.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get kindPrepaid;

  /// No description provided for @kindRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get kindRefund;

  /// No description provided for @methodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get methodCash;

  /// No description provided for @methodTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get methodTransfer;

  /// No description provided for @methodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get methodCard;

  /// No description provided for @methodOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get methodOther;

  /// No description provided for @selectStudent.
  ///
  /// In en, this message translates to:
  /// **'Select student'**
  String get selectStudent;

  /// No description provided for @selectLesson.
  ///
  /// In en, this message translates to:
  /// **'Select lesson'**
  String get selectLesson;

  /// No description provided for @selectStudentTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Student'**
  String get selectStudentTitle;

  /// No description provided for @selectLessonTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Lesson'**
  String get selectLessonTitle;

  /// No description provided for @noLesson.
  ///
  /// In en, this message translates to:
  /// **'No lesson'**
  String get noLesson;

  /// No description provided for @noStudentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No students available.'**
  String get noStudentsAvailable;

  /// No description provided for @noLessonsFound.
  ///
  /// In en, this message translates to:
  /// **'No lessons found for this filter.'**
  String get noLessonsFound;

  /// No description provided for @applyToLessonStatus.
  ///
  /// In en, this message translates to:
  /// **'Apply to lesson status'**
  String get applyToLessonStatus;

  /// No description provided for @optionalNotes.
  ///
  /// In en, this message translates to:
  /// **'Optional notes'**
  String get optionalNotes;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @selectStudentOrLesson.
  ///
  /// In en, this message translates to:
  /// **'Select a student or lesson.'**
  String get selectStudentOrLesson;

  /// No description provided for @addSchedule.
  ///
  /// In en, this message translates to:
  /// **'Add Schedule'**
  String get addSchedule;

  /// No description provided for @addLesson.
  ///
  /// In en, this message translates to:
  /// **'Add Lesson'**
  String get addLesson;

  /// No description provided for @editSchedule.
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editSchedule;

  /// No description provided for @editLesson.
  ///
  /// In en, this message translates to:
  /// **'Edit Lesson'**
  String get editLesson;

  /// No description provided for @deleteLessonConfirmShort.
  ///
  /// In en, this message translates to:
  /// **'Delete this lesson permanently?'**
  String get deleteLessonConfirmShort;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get startTime;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @titleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptional;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @selectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get selectGroup;

  /// No description provided for @selectGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroupTitle;

  /// No description provided for @freeLesson.
  ///
  /// In en, this message translates to:
  /// **'Free lesson'**
  String get freeLesson;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @mathTutoringPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Math tutoring'**
  String get mathTutoringPlaceholder;

  /// No description provided for @selectAGroup.
  ///
  /// In en, this message translates to:
  /// **'Select a group.'**
  String get selectAGroup;

  /// No description provided for @selectAStudent.
  ///
  /// In en, this message translates to:
  /// **'Select a student.'**
  String get selectAStudent;

  /// No description provided for @enterValidPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price.'**
  String get enterValidPrice;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @lessonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String lessonsCount(int count);

  /// No description provided for @unpaidLessonsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unpaid lessons'**
  String unpaidLessonsCount(int count);

  /// No description provided for @lessonsOldest.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons · oldest {date}'**
  String lessonsOldest(int count, String date);

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @teaching.
  ///
  /// In en, this message translates to:
  /// **'Teaching'**
  String get teaching;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @defaultIndividualCost.
  ///
  /// In en, this message translates to:
  /// **'Default individual fee'**
  String get defaultIndividualCost;

  /// No description provided for @defaultGroupCost.
  ///
  /// In en, this message translates to:
  /// **'Default group fee'**
  String get defaultGroupCost;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson reminders and payment alerts'**
  String get notificationsSubtitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageFollowsDevice.
  ///
  /// In en, this message translates to:
  /// **'Follows device language'**
  String get languageFollowsDevice;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageTurkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get languageTurkish;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get appVersion;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @editProfileComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile editing will be available soon.'**
  String get editProfileComingSoon;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to continue.'**
  String get logoutConfirmMessage;

  /// No description provided for @costPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get costPlaceholder;

  /// No description provided for @currencyTry.
  ///
  /// In en, this message translates to:
  /// **'TRY'**
  String get currencyTry;

  /// No description provided for @signedInWith.
  ///
  /// In en, this message translates to:
  /// **'Signed in with {provider}'**
  String signedInWith(String provider);

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportMessage.
  ///
  /// In en, this message translates to:
  /// **'Questions or feedback? Email us anytime.'**
  String get supportMessage;

  /// No description provided for @teachingDefaultsHint.
  ///
  /// In en, this message translates to:
  /// **'Used as the default price when creating new lessons.'**
  String get teachingDefaultsHint;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select a time slot'**
  String get selectTimeSlot;

  /// No description provided for @selectTimeSlotHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a highlighted cell to choose day and time.'**
  String get selectTimeSlotHint;

  /// No description provided for @selectedSlot.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time}'**
  String selectedSlot(String date, String time);

  /// No description provided for @markLessonDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as done'**
  String get markLessonDone;

  /// No description provided for @movedToJournal.
  ///
  /// In en, this message translates to:
  /// **'Moved to journal as completed.'**
  String get movedToJournal;

  /// No description provided for @settlePaymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment for this lesson'**
  String get settlePaymentTitle;

  /// No description provided for @leaveUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Leave unpaid'**
  String get leaveUnpaid;

  /// No description provided for @markPaidNow.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markPaidNow;

  /// No description provided for @applyPrepaidCredit.
  ///
  /// In en, this message translates to:
  /// **'Apply prepaid credit'**
  String get applyPrepaidCredit;

  /// No description provided for @editLessonAction.
  ///
  /// In en, this message translates to:
  /// **'Edit lesson'**
  String get editLessonAction;

  /// No description provided for @studentNotes.
  ///
  /// In en, this message translates to:
  /// **'Student notes'**
  String get studentNotes;

  /// No description provided for @studentNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Note for {name}'**
  String studentNotePlaceholder(String name);

  /// No description provided for @noGroupMembers.
  ///
  /// In en, this message translates to:
  /// **'This group has no members yet.'**
  String get noGroupMembers;

  /// No description provided for @packageCredit.
  ///
  /// In en, this message translates to:
  /// **'Package credit'**
  String get packageCredit;

  /// No description provided for @approxLessonsLeft.
  ///
  /// In en, this message translates to:
  /// **'~{count} lessons left'**
  String approxLessonsLeft(int count);

  /// No description provided for @applyCredit.
  ///
  /// In en, this message translates to:
  /// **'Apply credit'**
  String get applyCredit;

  /// No description provided for @applyCreditToLesson.
  ///
  /// In en, this message translates to:
  /// **'Apply credit to a lesson'**
  String get applyCreditToLesson;

  /// No description provided for @noUnpaidLessons.
  ///
  /// In en, this message translates to:
  /// **'No unpaid lessons for this student.'**
  String get noUnpaidLessons;

  /// No description provided for @creditApplied.
  ///
  /// In en, this message translates to:
  /// **'Prepaid credit applied.'**
  String get creditApplied;

  /// No description provided for @loadPackage.
  ///
  /// In en, this message translates to:
  /// **'Load package'**
  String get loadPackage;

  /// No description provided for @loadPackageHint.
  ///
  /// In en, this message translates to:
  /// **'Record advance payment as package credit for a student.'**
  String get loadPackageHint;

  /// No description provided for @unallocatedCreditTotal.
  ///
  /// In en, this message translates to:
  /// **'Unallocated credit'**
  String get unallocatedCreditTotal;

  /// No description provided for @prepaidWalletHint.
  ///
  /// In en, this message translates to:
  /// **'Credits waiting to be applied to lessons.'**
  String get prepaidWalletHint;

  /// No description provided for @selectUnpaidLesson.
  ///
  /// In en, this message translates to:
  /// **'Select unpaid lesson'**
  String get selectUnpaidLesson;

  /// No description provided for @lessonNotesSummary.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get lessonNotesSummary;

  /// No description provided for @pickLessonFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'Pick a lesson'**
  String get pickLessonFromCalendar;

  /// No description provided for @pickUnpaidLessonHint.
  ///
  /// In en, this message translates to:
  /// **'Tap an unpaid journal lesson on the week grid.'**
  String get pickUnpaidLessonHint;

  /// No description provided for @pickLessonHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a journal lesson on the week grid.'**
  String get pickLessonHint;

  /// No description provided for @noLessonsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No matching lessons this week. Try another week.'**
  String get noLessonsThisWeek;

  /// No description provided for @clearLesson.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLesson;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Teach without limits'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full toolkit for growing your tutoring practice.'**
  String get paywallSubtitle;

  /// No description provided for @paywallReasonStudents.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the free limit of 4 active students.'**
  String get paywallReasonStudents;

  /// No description provided for @paywallReasonSchedule.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the free limit of 24 schedule lessons.'**
  String get paywallReasonSchedule;

  /// No description provided for @paywallReasonJournal.
  ///
  /// In en, this message translates to:
  /// **'You’ve reached the free limit of 24 journal lessons.'**
  String get paywallReasonJournal;

  /// No description provided for @paywallFeatureStudents.
  ///
  /// In en, this message translates to:
  /// **'Unlimited active students'**
  String get paywallFeatureStudents;

  /// No description provided for @paywallFeatureSchedule.
  ///
  /// In en, this message translates to:
  /// **'Unlimited schedule lessons'**
  String get paywallFeatureSchedule;

  /// No description provided for @paywallFeatureJournal.
  ///
  /// In en, this message translates to:
  /// **'Unlimited journal lessons'**
  String get paywallFeatureJournal;

  /// No description provided for @planWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get planWeekly;

  /// No description provided for @planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get planMonthly;

  /// No description provided for @planYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get planYearly;

  /// No description provided for @planWeeklyHint.
  ///
  /// In en, this message translates to:
  /// **'Flexible billing'**
  String get planWeeklyHint;

  /// No description provided for @planMonthlyHint.
  ///
  /// In en, this message translates to:
  /// **'Billed monthly'**
  String get planMonthlyHint;

  /// No description provided for @planYearlyHint.
  ///
  /// In en, this message translates to:
  /// **'Best value annually'**
  String get planYearlyHint;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @continueToPremium.
  ///
  /// In en, this message translates to:
  /// **'Unlock Premium'**
  String get continueToPremium;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @paywallProductsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store products are not available yet. Check RevenueCat and product IDs.'**
  String get paywallProductsUnavailable;

  /// No description provided for @paywallNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'No purchases found to restore.'**
  String get paywallNoPurchases;

  /// No description provided for @paywallLegal.
  ///
  /// In en, this message translates to:
  /// **'Payment is charged to your App Store account. Manage subscriptions in Settings.'**
  String get paywallLegal;

  /// No description provided for @choosePlan.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan'**
  String get choosePlan;

  /// No description provided for @freePlanUsage.
  ///
  /// In en, this message translates to:
  /// **'Current free usage'**
  String get freePlanUsage;

  /// No description provided for @usageStudents.
  ///
  /// In en, this message translates to:
  /// **'Students: {used}/{limit}'**
  String usageStudents(int used, int limit);

  /// No description provided for @usageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule lessons: {used}/{limit}'**
  String usageSchedule(int used, int limit);

  /// No description provided for @usageJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal lessons: {used}/{limit}'**
  String usageJournal(int used, int limit);

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get manageSubscription;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premiumActive;

  /// No description provided for @premiumFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get premiumFree;

  /// No description provided for @upgradeToPremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradeToPremium;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
