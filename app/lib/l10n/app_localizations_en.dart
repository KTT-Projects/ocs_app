// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get checkSpamJunk =>
      'Please check your spam/junk folder if you don\'t see the email in your inbox';

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
  String get enterVerificationCode =>
      'Please enter the 6-digit code to verify your account:';

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
  String errorDetailsText(
      Object errorType, Object errorFile, Object errorLine, Object stackTrace) {
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
  String get invalidOrExpiredOtp =>
      'Invalid or expired verification code. Please request a new code.';

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
  String get displayNameTooLong =>
      'Display name must be less than 30 characters';

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
  String get volunteerOpportunities => 'Volunteer Opportunities';

  @override
  String get myVolunteerActivities => 'My Activities';

  @override
  String get createOpportunity => 'Create Opportunity';

  @override
  String get opportunityTitle => 'Title';

  @override
  String get opportunityDescription => 'Description';

  @override
  String get opportunityLocation => 'Location';

  @override
  String get volunteerStartDate => 'Start Date';

  @override
  String get volunteerEndDate => 'End Date';

  @override
  String get requiredParticipants => 'Required Participants';

  @override
  String get volunteerApply => 'Apply';

  @override
  String get volunteerApplied => 'Applied';

  @override
  String get volunteerApproved => 'Approved';

  @override
  String get volunteerCompleted => 'Completed';

  @override
  String get volunteerCancelled => 'Cancelled';

  @override
  String get opportunityOpen => 'Open';

  @override
  String get opportunityFilled => 'Filled';

  @override
  String get volunteerParticipants => 'Participants';

  @override
  String get volunteerRoleMember => 'Member';

  @override
  String get volunteerRoleCoordinator => 'Coordinator';

  @override
  String get volunteerRoleAdmin => 'Admin';

  @override
  String get volunteerManageTitle => 'Manage Volunteer';

  @override
  String get volunteerRequiredParticipantsOptional =>
      'Required participants (Optional)';

  @override
  String volunteerSpotsRemaining(int count) {
    return '$count spots left';
  }

  @override
  String get volunteerNoLimit => 'No capacity limit';

  @override
  String get volunteerOrganizer => 'Organizer';

  @override
  String get save => 'Save';

  @override
  String get volunteerHistory => 'Volunteer History';

  @override
  String get downloadCertificate => 'Download Certificate';

  @override
  String get hoursCompleted => 'Hours Completed';

  @override
  String get certificateIssued => 'Certificate Issued';

  @override
  String get noVolunteerOpportunities => 'No volunteer opportunities available';

  @override
  String get noVolunteerActivities => 'No volunteer activities yet';

  @override
  String get viewDetails => 'View Details';

  @override
  String get cancelApplication => 'Cancel';

  @override
  String get certificateButton => 'Certificate';

  @override
  String get applicationCancelled => 'Application cancelled';

  @override
  String get certificateDownloaded => 'Certificate downloaded successfully!';

  @override
  String get filterByVolunteerStatus => 'Filter by Status';

  @override
  String get sortVolunteerBy => 'Sort by';

  @override
  String get volunteerNewest => 'Newest';

  @override
  String get volunteerOldest => 'Oldest';

  @override
  String get volunteerUpcoming => 'Upcoming';

  @override
  String get volunteerOngoing => 'Ongoing';

  @override
  String get volunteerPast => 'Past';

  @override
  String get allVolunteerStatuses => 'All Statuses';

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
  String get communityCenterDesc =>
      'The new community center will open next week with various facilities.';

  @override
  String get beachCleanup => 'Beach Cleanup Event';

  @override
  String get beachCleanupDesc =>
      'Join us for the monthly beach cleanup activity.';

  @override
  String get summerFestival => 'Summer Festival Planning';

  @override
  String get summerFestivalDesc =>
      'Planning meeting for this year\'s summer festival.';

  @override
  String get resetPasswordTitle => 'Reset Password';

  @override
  String get resetPasswordSubtitle =>
      'Enter your email to receive reset instructions';

  @override
  String get resetPasswordSent =>
      'Password reset instructions sent to your email';

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
  String get questionTags => 'Tags';

  @override
  String get questionTagsHint => 'Enter a tag (e.g. Physics)';

  @override
  String get addTag => 'Add';

  @override
  String get postQuestion => 'Post Question';

  @override
  String get studySearchHint => 'Search title/body/tag...';

  @override
  String get studyFilterTitle => 'Filter Questions';

  @override
  String get studyFilterCategory => 'Category';

  @override
  String get studyFilterTag => 'Tag';

  @override
  String get studyFilterUnresolvedOnly => 'Unresolved only';

  @override
  String get studyFilterApply => 'Apply';

  @override
  String get studyFilterReset => 'Reset';

  @override
  String get studySortNewest => 'Newest';

  @override
  String get studySortAnswers => 'Most Answers';

  @override
  String get studySortUnresolvedFirst => 'Unresolved First';

  @override
  String get noStudyQuestions => 'No questions yet.';

  @override
  String get failedToLoadStudyQuestions => 'Failed to load questions';

  @override
  String get failedToLoadStudyQuestionDetail =>
      'Failed to load question detail';

  @override
  String get failedToCreateStudyQuestion => 'Failed to create question';

  @override
  String get questionDetails => 'Question Details';

  @override
  String get questionCategoryRequired => 'Category is required';

  @override
  String get questionCategoryTooLong =>
      'Category must be less than 100 characters';

  @override
  String get questionTagsRequired => 'At least one tag is required';

  @override
  String get questionTagsTooMany => 'You can add up to 5 tags';

  @override
  String get questionTagTooLong => 'Each tag must be 30 characters or less';

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
  String get studyRanking => 'Ranking';

  @override
  String get studyRankingMyRank => 'Your Rank';

  @override
  String get studyRankingUnranked => 'Unranked';

  @override
  String get noStudyRanking => 'No ranking data yet.';

  @override
  String get failedToLoadStudyRanking => 'Failed to load ranking';

  @override
  String get studyComingSoon => 'Coming soon';

  @override
  String get studyComingSoonDescription =>
      'Study Q&A is currently under development.';

  @override
  String get feed => 'Feed';

  @override
  String get failedToUpdateProfile => 'Failed to update profile settings';

  @override
  String get role => 'Role';

  @override
  String get totalPoints => 'Total Points';

  @override
  String get studyBadge => 'Badge';

  @override
  String get studyBadgeNone => 'No Badge';

  @override
  String get studyBadgeBronze => 'Bronze';

  @override
  String get studyBadgeSilver => 'Silver';

  @override
  String get studyBadgeGold => 'Gold';

  @override
  String get studyBadgePlatinum => 'Platinum';

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
  String get feedIdInvalid =>
      'Only lowercase letters, numbers, and underscores allowed';

  @override
  String get descriptionRequired => 'Description is required';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get contentRequired => 'Content is required';

  @override
  String get addImage => 'Add Image';

  @override
  String get feedIdHelperText =>
      'Only lowercase letters, numbers, and underscores';

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
  String get selectNewAdmin => '';

  @override
  String get confirmDeleteFeed =>
      'No other members remain. Leaving will delete this feed. Continue?';

  @override
  String get ok => 'OK';

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
  String get descriptionTooLong =>
      'Description must be less than 1000 characters';

  @override
  String get rulesTooLong => 'Rules must be less than 1000 characters';

  @override
  String get feedSettings => 'Feed settings';

  @override
  String get feedUpdatedSuccess => 'Feed updated successfully';

  @override
  String get failedToLoadFeedMembers => 'Failed to load feed members';

  @override
  String get currentAdmin => 'Admin';

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

  @override
  String get myVolunteerSchedule => 'My Volunteer Schedule';

  @override
  String get createVolunteerOpportunity => 'Create New';

  @override
  String get organizer => 'Organizer';

  @override
  String get attachments => 'Attachments';

  @override
  String get volunteerReflections => 'Reflections';

  @override
  String get recentReflection => 'Recent reflection';

  @override
  String get newReflection => 'New';

  @override
  String get readFullReflection => 'Read full reflection';

  @override
  String get manageReflections => 'Manage reflections';

  @override
  String get shareReflection => 'Share reflection';

  @override
  String get noReflectionsYet => 'No reflections yet';

  @override
  String get noReflectionsHint =>
      'Admins can post a recap with photos so participants can look back.';

  @override
  String get saveReflection => 'Save reflection';

  @override
  String get updateReflection => 'Update reflection';

  @override
  String get reflectionTitleLabel => 'Headline';

  @override
  String get reflectionBodyLabel => 'Reflection';

  @override
  String get reflectionBodyRequired =>
      'Please write a reflection before saving.';

  @override
  String get reflectionSaved => 'Reflection saved';

  @override
  String get saveReflectionFirst => 'Save the reflection before adding photos.';

  @override
  String get reflectionImages => 'Reflection images';

  @override
  String get reflectionAutoBody =>
      'This activity is now complete. Great job, everyone!';

  @override
  String get noReflectionImages => 'No reflection images yet';

  @override
  String get reflectionImageUploaded => 'Image added';

  @override
  String get reflectionImageRemoved => 'Image removed';

  @override
  String get addPhotos => 'Add photos';

  @override
  String get draft => 'Draft';

  @override
  String get activityDetails => 'Activity details';

  @override
  String get manage => 'Manage';

  @override
  String get manageVolunteerOpportunity => 'Manage Opportunity';

  @override
  String get approveParticipant => 'Approve';

  @override
  String get rejectParticipant => 'Reject';

  @override
  String get editOpportunity => 'Edit Opportunity';

  @override
  String get participants => 'Participants';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get date => 'Date';

  @override
  String get reapply => 'Reapply';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get statusUnknown => 'UNKNOWN';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleCoordinator => 'Coordinator';

  @override
  String get roleMember => 'Member';

  @override
  String get hoursUnit => 'h';

  @override
  String get participantStatusUpdated => 'Participant status updated';

  @override
  String get pleaseSelectDate => 'Please select a date';

  @override
  String get pleaseSelectTimes => 'Please select start and end times';

  @override
  String get volunteerOpportunityCreated =>
      'Volunteer opportunity created successfully!';

  @override
  String get enterOpportunityTitle => 'Enter opportunity title';

  @override
  String get describeOpportunity => 'Describe the volunteer opportunity';

  @override
  String get enterLocation => 'Enter location';

  @override
  String get locationRequired => 'Location is required';

  @override
  String get eventDate => 'Event Date';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get leaveEmptyForUnlimited => 'Leave empty for unlimited';

  @override
  String get optionalLabel => '(Optional)';

  @override
  String get addFiles => 'Add files';

  @override
  String get attachmentsHelperText => 'Images or PDFs to share extra details.';

  @override
  String fileSizeKilobytes(int size) {
    return '$size KB';
  }

  @override
  String failedToUploadFile(String fileName, String error) {
    return 'Failed to upload $fileName: $error';
  }

  @override
  String get calendarTab => 'Calendar';

  @override
  String get listTab => 'List';
}
