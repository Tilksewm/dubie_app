import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Dubie'**
  String get appName;

  /// No description provided for @guestUser.
  ///
  /// In en, this message translates to:
  /// **'Guest User'**
  String get guestUser;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No Email'**
  String get noEmail;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @signinSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data and get personalized content.'**
  String get signinSuggestion;

  /// No description provided for @signinSignup.
  ///
  /// In en, this message translates to:
  /// **'Sign In / Sign Up'**
  String get signinSignup;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @youLent.
  ///
  /// In en, this message translates to:
  /// **'You Lent'**
  String get youLent;

  /// No description provided for @youBorrow.
  ///
  /// In en, this message translates to:
  /// **'You Borrow'**
  String get youBorrow;

  /// No description provided for @noLent.
  ///
  /// In en, this message translates to:
  /// **'No one currently owes you money.'**
  String get noLent;

  /// No description provided for @noBorrow.
  ///
  /// In en, this message translates to:
  /// **'No one currently you owes money.'**
  String get noBorrow;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Syncing Offline data failed'**
  String get syncFailed;

  /// No description provided for @onLogoutSyncFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Please connect to the internet to sync offline data. otherwise offline data will be lost.'**
  String get onLogoutSyncFailedMessage;

  /// No description provided for @logoutAnyway.
  ///
  /// In en, this message translates to:
  /// **'Logout anyway'**
  String get logoutAnyway;

  /// No description provided for @trySyncAgain.
  ///
  /// In en, this message translates to:
  /// **'Try sync and logout'**
  String get trySyncAgain;

  /// No description provided for @enablePinInSettings.
  ///
  /// In en, this message translates to:
  /// **'PIN lock is not enabled.'**
  String get enablePinInSettings;

  /// No description provided for @lockApp.
  ///
  /// In en, this message translates to:
  /// **'Lock App'**
  String get lockApp;

  /// No description provided for @createNewDebt.
  ///
  /// In en, this message translates to:
  /// **'Create New Debt'**
  String get createNewDebt;

  /// No description provided for @addPerson.
  ///
  /// In en, this message translates to:
  /// **'Add Person'**
  String get addPerson;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Your Password?'**
  String get forgotPassword;

  /// No description provided for @enterYourEmailToResetPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address associated with your account and we\'ll send you a link to reset your password.'**
  String get enterYourEmailToResetPassword;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @couldNotConnect.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to the server. Please check your connection.'**
  String get couldNotConnect;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Signup'**
  String get signup;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter Your Password'**
  String get enterYourPassword;

  /// No description provided for @noAccountSignUp.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get noAccountSignUp;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration successful! Please check your email for verification before logging in.'**
  String get signupSuccess;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterYourFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterYourFullName;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordMinLength;

  /// No description provided for @usernameOptional.
  ///
  /// In en, this message translates to:
  /// **'Username (Optional)'**
  String get usernameOptional;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @phoneOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone (Optional)'**
  String get phoneOptional;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'phone'**
  String get phone;

  /// No description provided for @emailOptional.
  ///
  /// In en, this message translates to:
  /// **'Email (Optional)'**
  String get emailOptional;

  /// No description provided for @enterValidPhoneWithCountryCode.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number with country code'**
  String get enterValidPhoneWithCountryCode;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get alreadyHaveAccount;

  /// No description provided for @personAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Person added successfully!'**
  String get personAddedSuccessfully;

  /// No description provided for @addNewPerson.
  ///
  /// In en, this message translates to:
  /// **'Add New Person'**
  String get addNewPerson;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @enterItemDescriptionAndPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter item description and price.'**
  String get enterItemDescriptionAndPrice;

  /// No description provided for @enterValidPositivePrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid positive price.'**
  String get enterValidPositivePrice;

  /// No description provided for @debtCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Debt created successfully!'**
  String get debtCreatedSuccessfully;

  /// No description provided for @failedToCreateDebt.
  ///
  /// In en, this message translates to:
  /// **'Failed to create debt'**
  String get failedToCreateDebt;

  /// No description provided for @addAtListOneItem.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one debt item.'**
  String get addAtListOneItem;

  /// No description provided for @createNewDubie.
  ///
  /// In en, this message translates to:
  /// **'Create New Dubie'**
  String get createNewDubie;

  /// No description provided for @overallDescriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Overall Description (Optional)'**
  String get overallDescriptionOptional;

  /// No description provided for @addDubieItems.
  ///
  /// In en, this message translates to:
  /// **'Add Dubie Items:'**
  String get addDubieItems;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item Description'**
  String get itemDescription;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @etb.
  ///
  /// In en, this message translates to:
  /// **'ETB'**
  String get etb;

  /// No description provided for @createDubie.
  ///
  /// In en, this message translates to:
  /// **'Create Dubie'**
  String get createDubie;

  /// No description provided for @deleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Delete Debt'**
  String get deleteDebt;

  /// No description provided for @deleteDebtConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this Debt? This action cannot be undone.'**
  String get deleteDebtConfirmation;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @debtDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Debt deleted successfully.'**
  String get debtDeletedSuccessfully;

  /// No description provided for @failedToDeleteDebt.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete Debt'**
  String get failedToDeleteDebt;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @commentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Comment added!'**
  String get commentAddedSuccessfully;

  /// No description provided for @failedToAddComment.
  ///
  /// In en, this message translates to:
  /// **'Failed to add comment'**
  String get failedToAddComment;

  /// No description provided for @itemAdded.
  ///
  /// In en, this message translates to:
  /// **'Item added!'**
  String get itemAdded;

  /// No description provided for @failedToAddItem.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item'**
  String get failedToAddItem;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get recordPayment;

  /// No description provided for @amountPaidMax.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid, Max:'**
  String get amountPaidMax;

  /// No description provided for @enterAmountToPay.
  ///
  /// In en, this message translates to:
  /// **'Enter amount to pay'**
  String get enterAmountToPay;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get enterValidAmount;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @failedToRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get failedToRecordPayment;

  /// No description provided for @paymentRecordedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded!'**
  String get paymentRecordedSuccessfully;

  /// No description provided for @enterAmountExceededOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Entered Amount Exceeded the outstanding Amount'**
  String get enterAmountExceededOutstanding;

  /// No description provided for @enterTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter Total Amount'**
  String get enterTotalAmount;

  /// No description provided for @addNewDubieItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Dubie Item'**
  String get addNewDubieItem;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @loadingDebt.
  ///
  /// In en, this message translates to:
  /// **'Loading Debt...'**
  String get loadingDebt;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid:'**
  String get paidAmount;

  /// No description provided for @debtNotFound.
  ///
  /// In en, this message translates to:
  /// **'Debt not found.'**
  String get debtNotFound;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @editDebt.
  ///
  /// In en, this message translates to:
  /// **'Edit Debt'**
  String get editDebt;

  /// No description provided for @payAll.
  ///
  /// In en, this message translates to:
  /// **'Pay All'**
  String get payAll;

  /// No description provided for @noItemsInThisDubie.
  ///
  /// In en, this message translates to:
  /// **'No items in this dubie yet.'**
  String get noItemsInThisDubie;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @addNewItem.
  ///
  /// In en, this message translates to:
  /// **'Add New Item'**
  String get addNewItem;

  /// No description provided for @dubieItems.
  ///
  /// In en, this message translates to:
  /// **'Debt Items'**
  String get dubieItems;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @errorLoadingComments.
  ///
  /// In en, this message translates to:
  /// **'Error loading comments'**
  String get errorLoadingComments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @debtAccepted.
  ///
  /// In en, this message translates to:
  /// **'Debt accepted'**
  String get debtAccepted;

  /// No description provided for @faildToAcceptDebt.
  ///
  /// In en, this message translates to:
  /// **'Failed to accept this Debt'**
  String get faildToAcceptDebt;

  /// No description provided for @acceptDubie.
  ///
  /// In en, this message translates to:
  /// **'Accept Dubie'**
  String get acceptDubie;

  /// No description provided for @debtRejected.
  ///
  /// In en, this message translates to:
  /// **'Debt rejected'**
  String get debtRejected;

  /// No description provided for @failedToRejectDebt.
  ///
  /// In en, this message translates to:
  /// **'Failed to reject this Debt'**
  String get failedToRejectDebt;

  /// No description provided for @rejectDubie.
  ///
  /// In en, this message translates to:
  /// **'Reject Dubie'**
  String get rejectDubie;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @createYourPin.
  ///
  /// In en, this message translates to:
  /// **'Create your 4-digit PIN'**
  String get createYourPin;

  /// No description provided for @enterYourPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your 4-digit PIN'**
  String get enterYourPin;

  /// No description provided for @lockedOutFor.
  ///
  /// In en, this message translates to:
  /// **'Locked out for'**
  String get lockedOutFor;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name can\'t be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @pinSetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN set successfully'**
  String get pinSetSuccessfully;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN (4 digits)'**
  String get newPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm New PIN'**
  String get confirmNewPin;

  /// No description provided for @pinsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'New PINs do not match'**
  String get pinsDoNotMatch;

  /// No description provided for @newPinMustBe4Digits.
  ///
  /// In en, this message translates to:
  /// **'New PIN must be 4 Digits'**
  String get newPinMustBe4Digits;

  /// No description provided for @pinChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN changed successfully'**
  String get pinChangedSuccessfully;

  /// No description provided for @changePinBtn.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePinBtn;

  /// No description provided for @pinCodeSettings.
  ///
  /// In en, this message translates to:
  /// **'PIN Code Settings'**
  String get pinCodeSettings;

  /// No description provided for @enablePinLock.
  ///
  /// In en, this message translates to:
  /// **'Enable PIN Lock'**
  String get enablePinLock;

  /// No description provided for @pinLockedDisabled.
  ///
  /// In en, this message translates to:
  /// **'PIN lock disabled.'**
  String get pinLockedDisabled;

  /// No description provided for @failedToDisablePin.
  ///
  /// In en, this message translates to:
  /// **'Failed to disable PIN'**
  String get failedToDisablePin;

  /// No description provided for @unlockExclusiveFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlock Exclusive Features'**
  String get unlockExclusiveFeatures;

  /// No description provided for @signInSuggestionMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an account to save your preferences, and to sync your data across devices.'**
  String get signInSuggestionMessage;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @noDebtThreadFoundWith.
  ///
  /// In en, this message translates to:
  /// **'No debt threads found with {debt}'**
  String noDebtThreadFoundWith(Object debt);

  /// No description provided for @startNewDubie.
  ///
  /// In en, this message translates to:
  /// **'Start New Dubie'**
  String get startNewDubie;

  /// No description provided for @debtThread.
  ///
  /// In en, this message translates to:
  /// **'Debt Thread'**
  String get debtThread;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @createdByYou.
  ///
  /// In en, this message translates to:
  /// **'Created By: You'**
  String get createdByYou;

  /// No description provided for @createdBy.
  ///
  /// In en, this message translates to:
  /// **'Created By፡ {name}'**
  String createdBy(Object name);

  /// No description provided for @invite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// No description provided for @personUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Person updated successfully!'**
  String get personUpdatedSuccessfully;

  /// No description provided for @failedToUpdatePerson.
  ///
  /// In en, this message translates to:
  /// **'Failed to update person.'**
  String get failedToUpdatePerson;

  /// No description provided for @updateUserData.
  ///
  /// In en, this message translates to:
  /// **'Update User data'**
  String get updateUserData;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @switchGiverAndBorrower.
  ///
  /// In en, this message translates to:
  /// **'Switch Giver and Borrower'**
  String get switchGiverAndBorrower;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get enterDescription;

  /// No description provided for @unknownUser.
  ///
  /// In en, this message translates to:
  /// **'Unknown User'**
  String get unknownUser;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
