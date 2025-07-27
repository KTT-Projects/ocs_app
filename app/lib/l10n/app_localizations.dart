import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ja')
  ];

  /// Error message shown when non-Gmail email is entered
  ///
  /// In en, this message translates to:
  /// **'Only Gmail accounts are supported at this time'**
  String get onlyGoogleEmailAllowed;

  /// Helper text to check spam folder for verification email
  ///
  /// In en, this message translates to:
  /// **'Please check your spam/junk folder if you don\'t see the email in your inbox'**
  String get checkSpamJunk;

  /// Button text to resend verification code
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendOtp;

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Osakikamijima Community Site'**
  String get appTitle;

  /// Welcome message on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// Label for the email address input field
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// Label for the password input field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Text for the sign in button
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Text prompting account creation
  ///
  /// In en, this message translates to:
  /// **'New to the app?'**
  String get newToApp;

  /// Text for the sign up link
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Text for the password reset link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Title on the sign up screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Subtitle on the sign up screen
  ///
  /// In en, this message translates to:
  /// **'Sign up to get started'**
  String get signUpToGetStarted;

  /// Label for the full name input field (no nicknames allowed)
  ///
  /// In en, this message translates to:
  /// **'Full Name (No Nicknames)'**
  String get fullName;

  /// Text prompting to sign in
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Label for the graduation year input field
  ///
  /// In en, this message translates to:
  /// **'Graduation Year'**
  String get studentId;

  /// Label for the institution selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Select Institution'**
  String get selectInstitution;

  /// Text shown during loading states
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Generic error message format
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(Object message);

  /// Password requirements hint
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordRequirements;

  /// Error message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get invalidEmail;

  /// Error message for invalid graduation year
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid graduation year'**
  String get invalidStudentId;

  /// Error message for institution selection
  ///
  /// In en, this message translates to:
  /// **'Please select your institution'**
  String get pleaseSelectInstitution;

  /// Label for the grade selection dropdown
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// Error message for grade selection
  ///
  /// In en, this message translates to:
  /// **'Please select your grade'**
  String get pleaseSelectGrade;

  /// Message shown when email verification is needed
  ///
  /// In en, this message translates to:
  /// **'Please verify your email address'**
  String get verifyEmail;

  /// Hint text for OTP input field
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code'**
  String get enterOtp;

  /// Text for verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Text for back to login button
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// Title of email verification dialog
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Message shown when verification code is sent
  ///
  /// In en, this message translates to:
  /// **'A verification code has been sent to {email}'**
  String verificationCodeSent(Object email);

  /// Instructions for entering verification code
  ///
  /// In en, this message translates to:
  /// **'Please enter the 6-digit code to verify your account:'**
  String get enterVerificationCode;

  /// Hint text for verification code input
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enterSixDigitCode;

  /// Text for later/skip button
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// Error message for invalid verification code
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get invalidVerificationCode;

  /// Success message when email is verified
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// Helper text for password field
  ///
  /// In en, this message translates to:
  /// **'Must be at least 8 characters'**
  String get passwordHelper;

  /// Error message when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration failed'**
  String get registrationFailed;

  /// Error message when email verification fails
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// Error message when login fails
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// Success message when login is successful
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccessful;

  /// Error message when loading institutions fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load institutions'**
  String get failedToLoadInstitutions;

  /// Format for detailed error information
  ///
  /// In en, this message translates to:
  /// **'Details:\n{errorType} at {errorFile}:{errorLine}\n\nStack trace:\n{stackTrace}'**
  String errorDetailsText(
      Object errorType, Object errorFile, Object errorLine, Object stackTrace);

  /// Text for unknown error type
  ///
  /// In en, this message translates to:
  /// **'Unknown error type'**
  String get unknownErrorType;

  /// Text for unknown file location
  ///
  /// In en, this message translates to:
  /// **'unknown file'**
  String get unknownFile;

  /// Text for unknown line number
  ///
  /// In en, this message translates to:
  /// **'unknown line'**
  String get unknownLine;

  /// Text when no stack trace is available
  ///
  /// In en, this message translates to:
  /// **'No stack trace available'**
  String get noStackTrace;

  /// Error message when login credentials are invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get invalidCredentials;

  /// Text for back to registration button
  ///
  /// In en, this message translates to:
  /// **'Back to Registration'**
  String get backToRegistration;

  /// Error message shown when OTP is invalid or expired
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired verification code. Please request a new code.'**
  String get invalidOrExpiredOtp;

  /// Welcome message on home page with user's name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}!'**
  String welcomeUser(Object name);

  /// Text for logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Error message when loading user profile fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failedToLoadProfile;

  /// Title for profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Setup Profile'**
  String get setupProfile;

  /// Subtitle for profile setup screen
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself'**
  String get setupProfileSubtitle;

  /// Label for display name input field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// Label for bio input field
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// Label for direct messages toggle
  ///
  /// In en, this message translates to:
  /// **'Allow Direct Messages'**
  String get allowDirectMessages;

  /// Text for save profile button
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// Error message when profile setup fails
  ///
  /// In en, this message translates to:
  /// **'Failed to setup profile'**
  String get profileSetupFailed;

  /// Error message when display name is empty
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get displayNameRequired;

  /// Error message when display name is too long
  ///
  /// In en, this message translates to:
  /// **'Display name must be less than 30 characters'**
  String get displayNameTooLong;

  /// Title for the community features section
  ///
  /// In en, this message translates to:
  /// **'Community Features'**
  String get communityFeatures;

  /// Subtitle for the community hub
  ///
  /// In en, this message translates to:
  /// **'Osakikamijima Community Hub'**
  String get communityHub;

  /// Title for events feature
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsFeature;

  /// Description for events feature
  ///
  /// In en, this message translates to:
  /// **'Discover local events and activities'**
  String get eventsDescription;

  /// Title for groups feature
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsFeature;

  /// Description for groups feature
  ///
  /// In en, this message translates to:
  /// **'Join community groups and discussions'**
  String get groupsDescription;

  /// Title for local business feature
  ///
  /// In en, this message translates to:
  /// **'Local Business'**
  String get businessFeature;

  /// Description for local business feature
  ///
  /// In en, this message translates to:
  /// **'Support local businesses'**
  String get businessDescription;

  /// Title for volunteer feature
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get volunteerFeature;

  /// Description for volunteer feature
  ///
  /// In en, this message translates to:
  /// **'Find volunteering opportunities'**
  String get volunteerDescription;

  /// Title for the local news section
  ///
  /// In en, this message translates to:
  /// **'Local News & Updates'**
  String get localNews;

  /// Text for settings menu item
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Text for notifications button
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Text for profile button
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Text for retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Title for community center news
  ///
  /// In en, this message translates to:
  /// **'New Community Center Opening'**
  String get newCommunityCenter;

  /// Description for community center opening
  ///
  /// In en, this message translates to:
  /// **'The new community center will open next week with various facilities.'**
  String get communityCenterDesc;

  /// Title for beach cleanup event
  ///
  /// In en, this message translates to:
  /// **'Beach Cleanup Event'**
  String get beachCleanup;

  /// Description for beach cleanup event
  ///
  /// In en, this message translates to:
  /// **'Join us for the monthly beach cleanup activity.'**
  String get beachCleanupDesc;

  /// Title for summer festival planning
  ///
  /// In en, this message translates to:
  /// **'Summer Festival Planning'**
  String get summerFestival;

  /// Description for summer festival planning
  ///
  /// In en, this message translates to:
  /// **'Planning meeting for this year\'s summer festival.'**
  String get summerFestivalDesc;

  /// Title for reset password screen
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordTitle;

  /// Subtitle for reset password screen
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive reset instructions'**
  String get resetPasswordSubtitle;

  /// Success message when reset email is sent
  ///
  /// In en, this message translates to:
  /// **'Password reset instructions sent to your email'**
  String get resetPasswordSent;

  /// Error message when password reset fails
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get resetPasswordFailed;

  /// Label for new password input field
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Label for confirm password input field
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Error message when passwords do not match
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Text for reset password button
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordButton;

  /// Text for request password reset button (sends a code)
  ///
  /// In en, this message translates to:
  /// **'Send Verification Code'**
  String get requestPasswordReset;

  /// Success message when password is reset
  ///
  /// In en, this message translates to:
  /// **'Password has been reset successfully'**
  String get resetPasswordSuccess;

  /// Generic error message shown when an unknown error happens
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorOccurred;

  /// Title for the feed section
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// Error message when profile update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile settings'**
  String get failedToUpdateProfile;

  /// Label for user role display
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// Text for cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Hint text for grade input field
  ///
  /// In en, this message translates to:
  /// **'Enter a number 1-6 or OB'**
  String get gradeInputHint;

  /// Error message when grade input is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a number from 1 to 6, or OB'**
  String get invalidGrade;

  /// Text shown when user has no name set
  ///
  /// In en, this message translates to:
  /// **'No Name'**
  String get noName;

  /// Error message when loading feeds fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load feeds'**
  String get failedToLoadFeeds;

  /// Error message when loading posts fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts'**
  String get failedToLoadPosts;

  /// Error message when joining a feed fails
  ///
  /// In en, this message translates to:
  /// **'Failed to join feed'**
  String get failedToJoinFeed;

  /// Error message when creating a feed fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create feed'**
  String get failedToCreateFeed;

  /// Error message when creating a post fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create post'**
  String get failedToCreatePost;

  /// Error message when voting fails
  ///
  /// In en, this message translates to:
  /// **'Failed to vote'**
  String get failedToVote;

  /// Title for create feed page
  ///
  /// In en, this message translates to:
  /// **'Create Feed'**
  String get createFeed;

  /// Title for create post page
  ///
  /// In en, this message translates to:
  /// **'Create Post'**
  String get createPost;

  /// Label for feed ID input field
  ///
  /// In en, this message translates to:
  /// **'Feed ID (Unique identifier)'**
  String get feedId;

  /// Label for feed display name input field
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get feedDisplayName;

  /// Label for feed description input field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get feedDescription;

  /// Label for feed rules input field
  ///
  /// In en, this message translates to:
  /// **'Rules (Optional)'**
  String get feedRules;

  /// Error message when feed ID is empty
  ///
  /// In en, this message translates to:
  /// **'Feed ID is required'**
  String get feedIdRequired;

  /// Error message when feed ID contains invalid characters
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers, and underscores allowed'**
  String get feedIdInvalid;

  /// Error message when description is empty
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get descriptionRequired;

  /// Error message when title is empty
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// Error message when content is empty
  ///
  /// In en, this message translates to:
  /// **'Content is required'**
  String get contentRequired;

  /// Button text for adding an image
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// Helper text for feed ID input field
  ///
  /// In en, this message translates to:
  /// **'Only lowercase letters, numbers, and underscores'**
  String get feedIdHelperText;

  /// Label for post title input field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get postTitle;

  /// Placeholder text for post content input field
  ///
  /// In en, this message translates to:
  /// **'Write your post...'**
  String get writePost;

  /// Title for new post dialog with feed name
  ///
  /// In en, this message translates to:
  /// **'New post in {feedName}'**
  String newPostIn(Object feedName);

  /// Tooltip for button to open post editor in full page
  ///
  /// In en, this message translates to:
  /// **'Open in full page'**
  String get openInFullPage;

  /// Button text to submit a post
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// Title for the discover tab
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Title for the home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Title for the sort menu
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// Sort by latest option
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get latest;

  /// Sort by popular option
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// Title for the feed options menu
  ///
  /// In en, this message translates to:
  /// **'Feed options'**
  String get feedOptions;

  /// Button to create a new feed
  ///
  /// In en, this message translates to:
  /// **'Create new feed'**
  String get createNewFeed;

  /// Button to reorder feeds
  ///
  /// In en, this message translates to:
  /// **'Reorder feeds'**
  String get reorderFeeds;

  /// Button to leave the selected feed
  ///
  /// In en, this message translates to:
  /// **'Leave feed'**
  String get leaveFeed;

  /// Dialog title when selecting a new admin
  ///
  /// In en, this message translates to:
  /// **'Select new admin'**
  String get selectNewAdmin;

  /// Confirmation message shown when the last admin leaves a feed
  ///
  /// In en, this message translates to:
  /// **'No other members remain. Leaving will delete this feed. Continue?'**
  String get confirmDeleteFeed;

  /// Generic OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Placeholder for search feeds input
  ///
  /// In en, this message translates to:
  /// **'Search feeds...'**
  String get searchFeeds;

  /// Sort by population option
  ///
  /// In en, this message translates to:
  /// **'Population'**
  String get population;

  /// Sort by latest activity option
  ///
  /// In en, this message translates to:
  /// **'Latest Activity'**
  String get latestActivity;

  /// Message when no feeds are found
  ///
  /// In en, this message translates to:
  /// **'No feeds found.'**
  String get noFeedsFound;

  /// Button to join a feed
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Title for the discover more feeds section
  ///
  /// In en, this message translates to:
  /// **'Discover more feeds'**
  String get discoverMoreFeeds;

  /// Button to create a new post
  ///
  /// In en, this message translates to:
  /// **'New post'**
  String get newPost;

  /// Button to create a new post to a specific feed
  ///
  /// In en, this message translates to:
  /// **'New post to...'**
  String get newPostTo;

  /// Success message when a feed is created
  ///
  /// In en, this message translates to:
  /// **'Feed created successfully'**
  String get feedCreatedSuccess;

  /// Error message when post title is too long
  ///
  /// In en, this message translates to:
  /// **'Title must be less than 300 characters'**
  String get titleTooLong;

  /// Error message when post content is too long
  ///
  /// In en, this message translates to:
  /// **'Content must be less than 5000 characters'**
  String get contentTooLong;

  /// Error message when feed description is too long
  ///
  /// In en, this message translates to:
  /// **'Description must be less than 1000 characters'**
  String get descriptionTooLong;

  /// Error message when feed rules are too long
  ///
  /// In en, this message translates to:
  /// **'Rules must be less than 1000 characters'**
  String get rulesTooLong;
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
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
