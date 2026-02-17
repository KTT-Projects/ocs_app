// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get checkSpamJunk => 'Please check your spam/junk folder if you don\'t see the email in your inbox';

  @override
  String get resendOtp => 'Resend Code';

  @override
  String get appTitle => 'Osakikamijima Community Site';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get newToApp => 'New to the app?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signUpToGetStarted => 'Sign up to get started';

  @override
  String get fullName => 'Full Name (No Nicknames)';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get studentId => 'Graduation Year';

  @override
  String get selectInstitution => 'Select Institution';

  @override
  String get loading => 'Loading...';

  @override
  String errorMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get passwordRequirements => 'Password must be at least 8 characters';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get invalidStudentId => 'Please enter a valid graduation year';

  @override
  String get pleaseSelectInstitution => 'Please select your institution';

  @override
  String get grade => 'Grade';

  @override
  String get pleaseSelectGrade => 'Please select your grade';

  @override
  String get verifyEmail => 'Please verify your email address';

  @override
  String get enterOtp => 'Enter 6-digit verification code';

  @override
  String get verify => 'Verify';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String verificationCodeSent(Object email) {
    return 'A verification code has been sent to $email';
  }

  @override
  String get enterVerificationCode => 'Please enter the 6-digit code to verify your account:';

  @override
  String get enterSixDigitCode => 'Enter 6-digit code';

  @override
  String get later => 'Later';

  @override
  String get invalidVerificationCode => 'Please enter a valid 6-digit code';

  @override
  String get emailVerifiedSuccess => 'Email verified successfully!';

  @override
  String get passwordHelper => 'Must be at least 8 characters';

  @override
  String get registrationFailed => 'Registration failed';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get loginSuccessful => 'Login successful';

  @override
  String get failedToLoadInstitutions => 'Failed to load institutions';

  @override
  String errorDetailsText(Object errorType, Object errorFile, Object errorLine, Object stackTrace) {
    return 'Details:\n$errorType at $errorFile:$errorLine\n\nStack trace:\n$stackTrace';
  }

  @override
  String get unknownErrorType => 'Unknown error type';

  @override
  String get unknownFile => 'unknown file';

  @override
  String get unknownLine => 'unknown line';

  @override
  String get noStackTrace => 'No stack trace available';

  @override
  String get invalidCredentials => 'Invalid email or password';

  @override
  String get backToRegistration => 'Back to Registration';

  @override
  String get invalidOrExpiredOtp => 'Invalid or expired verification code. Please request a new code.';

  @override
  String welcomeUser(Object name) {
    return 'Welcome, $name!';
  }

  @override
  String get logout => 'Logout';

  @override
  String get failedToLoadProfile => 'Failed to load profile';

  @override
  String get setupProfile => 'Setup Profile';

  @override
  String get setupProfileSubtitle => 'Tell us about yourself';

  @override
  String get displayName => 'Display Name';

  @override
  String get bio => 'Bio';

  @override
  String get allowDirectMessages => 'Allow Direct Messages';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get profileSetupFailed => 'Failed to setup profile';

  @override
  String get displayNameRequired => 'Display name is required';

  @override
  String get displayNameTooLong => 'Display name must be less than 30 characters';

  @override
  String get communityFeatures => 'Community Features';

  @override
  String get communityHub => 'Osakikamijima Community Hub';

  @override
  String get eventsFeature => 'Events';

  @override
  String get eventsDescription => 'Discover local events and activities';

  @override
  String get groupsFeature => 'Groups';

  @override
  String get groupsDescription => 'Join community groups and discussions';

  @override
  String get businessFeature => 'Local Business';

  @override
  String get businessDescription => 'Support local businesses';

  @override
  String get volunteerFeature => 'Volunteer';

  @override
  String get volunteerDescription => 'Find volunteering opportunities';

  @override
  String get localNews => 'Local News & Updates';

  @override
  String get settings => 'Settings';

  @override
  String get notifications => 'Notifications';

  @override
  String get profile => 'Profile';

  @override
  String get retry => 'Retry';

  @override
  String get newCommunityCenter => 'New Community Center Opening';

  @override
  String get communityCenterDesc => 'The new community center will open next week with various facilities.';

  @override
  String get beachCleanup => 'Beach Cleanup Event';

  @override
  String get beachCleanupDesc => 'Join us for the monthly beach cleanup activity.';

  @override
  String get summerFestival => 'Summer Festival Planning';

  @override
  String get summerFestivalDesc => 'Planning meeting for this year\'s summer festival.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle => 'Enter your email to receive reset instructions';

  @override
  String get resetPasswordSent => 'Password reset instructions sent to your email';

  @override
  String get resetPasswordFailed => 'Failed to reset password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get resetPasswordButton => 'Reset Password';

  @override
  String get requestPasswordReset => 'Send Verification Code';

  @override
  String get resetPasswordSuccess => 'Password has been reset successfully';

  @override
  String get errorOccurred => 'An unexpected error occurred. Please try again.';

  @override
  String get studyFeature => 'Study';

  @override
  String get studyQuestions => 'Study Questions';

  @override
  String get createQuestion => 'Create Question';

  @override
  String get questionBody => 'Question body';

  @override
  String get questionCategory => 'Category';

  @override
  String get postQuestion => 'Post Question';

  @override
  String get noStudyQuestions => 'No questions yet.';

  @override
  String get failedToLoadStudyQuestions => 'Failed to load questions';

  @override
  String get failedToLoadStudyQuestionDetail => 'Failed to load question detail';

  @override
  String get failedToCreateStudyQuestion => 'Failed to create question';

  @override
  String get questionDetails => 'Question Details';

  @override
  String get questionCategoryRequired => 'Category is required';

  @override
  String get questionCategoryTooLong => 'Category must be less than 100 characters';

  @override
  String get questionStatusOpen => 'Open';

  @override
  String get questionStatusResolved => 'Resolved';

  @override
  String get questionAuthor => 'Author';

  @override
  String get questionCreatedAt => 'Created';

  @override
  String get studyAnswers => 'Answers';

  @override
  String get noStudyAnswers => 'No answers yet.';

  @override
  String get answerInputHint => 'Write your answer...';

  @override
  String get answerBodyRequired => 'Answer is required';

  @override
  String get answerBodyTooLong => 'Answer must be less than 5000 characters';

  @override
  String get failedToLoadStudyAnswers => 'Failed to load answers';

  @override
  String get failedToCreateStudyAnswer => 'Failed to create answer';

  @override
  String get failedToSelectBestAnswer => 'Failed to select best answer';

  @override
  String get markAsBest => 'Mark as Best';

  @override
  String get bestAnswerLabel => 'Best';

  @override
  String get bestAnswerSelectedSuccess => 'Best answer selected';

  @override
  String get bestAnswerAlreadySelected => 'Best answer already selected';

  @override
  String get studyComingSoon => 'Coming soon';

  @override
  String get studyComingSoonDescription => 'Study Q&A is currently under development.';

  @override
  String get feed => 'Feed';

  @override
  String get failedToUpdateProfile => 'Failed to update profile settings';

  @override
  String get role => 'Role';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get cancel => 'Cancel';

  @override
  String get gradeInputHint => 'Enter a number 1-6 or OB';

  @override
  String get invalidGrade => 'Please enter a number from 1 to 6, or OB';

  @override
  String get noName => 'No Name';

  @override
  String get failedToLoadFeeds => 'Failed to load feeds';

  @override
  String get failedToLoadPosts => 'Failed to load posts';

  @override
  String get failedToJoinFeed => 'Failed to join feed';

  @override
  String get failedToCreateFeed => 'Failed to create feed';

  @override
  String get failedToCreatePost => 'Failed to create post';

  @override
  String get failedToVote => 'Failed to vote';

  @override
  String get createFeed => 'Create Feed';

  @override
  String get createPost => 'Create Post';

  @override
  String get feedId => 'Feed ID (Unique identifier)';

  @override
  String get feedDisplayName => 'Display Name';

  @override
  String get feedDescription => 'Description';

  @override
  String get feedRules => 'Rules (Optional)';

  @override
  String get feedIdRequired => 'Feed ID is required';

  @override
  String get feedIdInvalid => 'Only lowercase letters, numbers, and underscores allowed';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get contentRequired => 'Content is required';

  @override
  String get addImage => 'Add Image';

  @override
  String get feedIdHelperText => 'Only lowercase letters, numbers, and underscores';

  @override
  String get postTitle => 'Title';

  @override
  String get writePost => 'Write your post...';

  @override
  String newPostIn(Object feedName) {
    return '$feedName';
  }

  @override
  String get openInFullPage => 'Open in full page';

  @override
  String get post => 'Post';

  @override
  String get discover => 'Discover';

  @override
  String get home => 'Home';

  @override
  String get sortBy => 'Sort by';

  @override
  String get latest => 'Latest';

  @override
  String get popular => 'Popular';

  @override
  String get defaultSort => 'Default';

  @override
  String get feedOptions => 'Feed options';

  @override
  String get createNewFeed => 'Create new feed';

  @override
  String get reorderFeeds => 'Reorder feeds';

  @override
  String get leaveFeed => 'Leave feed';

  @override
  String get selectNewAdmin => 'Select new admin';

  @override
  String get confirmDeleteFeed => 'No other members remain. Leaving will delete this feed. Continue?';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get searchFeeds => 'Search feeds...';

  @override
  String get population => 'Population';

  @override
  String get latestActivity => 'Latest Activity';

  @override
  String get noFeedsFound => 'No feeds found.';

  @override
  String get join => 'Join';

  @override
  String get discoverMoreFeeds => 'Discover more feeds';

  @override
  String get newPost => 'New post';

  @override
  String get newPostTo => 'New post to...';

  @override
  String get chooseFeed => 'Choose a feed';

  @override
  String get feedCreatedSuccess => 'Feed created successfully';

  @override
  String get titleTooLong => 'Title must be less than 300 characters';

  @override
  String get contentTooLong => 'Content must be less than 5000 characters';

  @override
  String get descriptionTooLong => 'Description must be less than 1000 characters';

  @override
  String get rulesTooLong => 'Rules must be less than 1000 characters';

  @override
  String get feedSettings => 'Feed settings';

  @override
  String get feedUpdatedSuccess => 'Feed updated successfully';

  @override
  String get failedToLoadFeedMembers => 'Failed to load feed members';

  @override
  String get currentAdmin => 'Current admin';

  @override
  String get change => 'Change';

  @override
  String get feedDetails => 'Feed details';

  @override
  String get members => 'Members';

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';
}
