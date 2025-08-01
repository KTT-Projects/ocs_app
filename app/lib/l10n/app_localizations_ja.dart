// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get onlyGoogleEmailAllowed => '現在、Gmailアカウントのみ対応しています';

  @override
  String get checkSpamJunk => 'メールが届かない場合は迷惑メールフォルダをご確認ください';

  @override
  String get resendOtp => '認証コードを再送信';

  @override
  String get appTitle => '大崎上島コミュニティーサイト';

  @override
  String get welcomeBack => 'おかえりなさい';

  @override
  String get signInToContinue => '続けるにはサインインしてください';

  @override
  String get email => 'メールアドレス';

  @override
  String get password => 'パスワード';

  @override
  String get signIn => 'サインイン';

  @override
  String get newToApp => 'アプリを初めて使用しますか？';

  @override
  String get signUp => '新規登録';

  @override
  String get forgotPassword => 'パスワードをお忘れですか？';

  @override
  String get createAccount => 'アカウントを作成';

  @override
  String get signUpToGetStarted => '始めるには新規登録してください';

  @override
  String get fullName => '氏名（ニックネーム不可）';

  @override
  String get alreadyHaveAccount => 'すでにアカウントをお持ちですか？';

  @override
  String get studentId => '卒業する学年';

  @override
  String get selectInstitution => '教育機関を選択';

  @override
  String get loading => '読み込み中...';

  @override
  String errorMessage(Object message) {
    return 'エラー: $message';
  }

  @override
  String get passwordRequirements => 'パスワードは8文字以上である必要があります';

  @override
  String get invalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get invalidStudentId => '有効な卒業する学年を入力してください';

  @override
  String get pleaseSelectInstitution => '教育機関を選択してください';

  @override
  String get grade => '学年';

  @override
  String get pleaseSelectGrade => '学年を選択してください';

  @override
  String get verifyEmail => 'メールアドレスを確認してください';

  @override
  String get enterOtp => '6桁の認証コードを入力';

  @override
  String get verify => '確認';

  @override
  String get backToLogin => 'ログインに戻る';

  @override
  String get verifyEmailTitle => 'メールアドレスの確認';

  @override
  String verificationCodeSent(Object email) {
    return '$emailに確認コードを送信しました';
  }

  @override
  String get enterVerificationCode => 'アカウントを確認するために6桁のコードを入力してください：';

  @override
  String get enterSixDigitCode => '6桁のコードを入力';

  @override
  String get later => '後で';

  @override
  String get invalidVerificationCode => '6桁の有効なコードを入力してください';

  @override
  String get emailVerifiedSuccess => 'メールアドレスが確認されました！';

  @override
  String get passwordHelper => '8文字以上である必要があります';

  @override
  String get registrationFailed => '登録に失敗しました';

  @override
  String get verificationFailed => '確認に失敗しました';

  @override
  String get loginFailed => 'ログインに失敗しました';

  @override
  String get loginSuccessful => 'ログインしました';

  @override
  String get failedToLoadInstitutions => '教育機関の読み込みに失敗しました';

  @override
  String errorDetailsText(
      Object errorType, Object errorFile, Object errorLine, Object stackTrace) {
    return '詳細:\n$errorType at $errorFile:$errorLine\n\nスタックトレース:\n$stackTrace';
  }

  @override
  String get unknownErrorType => '不明なエラータイプ';

  @override
  String get unknownFile => '不明なファイル';

  @override
  String get unknownLine => '不明な行';

  @override
  String get noStackTrace => 'スタックトレースは利用できません';

  @override
  String get invalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get backToRegistration => '登録に戻る';

  @override
  String get invalidOrExpiredOtp => '認証コードが無効または期限切れです。新しいコードを発行してください。';

  @override
  String welcomeUser(Object name) {
    return '$nameさん、ようこそ！';
  }

  @override
  String get logout => 'ログアウト';

  @override
  String get failedToLoadProfile => 'プロフィールの読み込みに失敗しました';

  @override
  String get setupProfile => 'プロフィール設定';

  @override
  String get setupProfileSubtitle => 'あなたについて教えてください';

  @override
  String get displayName => '表示名';

  @override
  String get bio => '自己紹介';

  @override
  String get allowDirectMessages => 'ダイレクトメッセージを許可';

  @override
  String get saveProfile => '更新';

  @override
  String get profileSetupFailed => 'プロフィールの設定に失敗しました';

  @override
  String get displayNameRequired => '表示名は必須です';

  @override
  String get displayNameTooLong => '表示名は100文字以内にしてください';

  @override
  String get communityFeatures => 'コミュニティ機能';

  @override
  String get communityHub => '大崎上島コミュニティハブ';

  @override
  String get eventsFeature => 'イベント';

  @override
  String get eventsDescription => '地域のイベントや活動を見つける';

  @override
  String get groupsFeature => 'グループ';

  @override
  String get groupsDescription => 'コミュニティグループや討論に参加';

  @override
  String get businessFeature => '地域ビジネス';

  @override
  String get businessDescription => '地域のビジネスを応援';

  @override
  String get volunteerFeature => 'ボランティア';

  @override
  String get volunteerDescription => 'ボランティア活動の機会を探す';

  @override
  String get localNews => '地域ニュース・更新情報';

  @override
  String get settings => '設定';

  @override
  String get notifications => '通知';

  @override
  String get profile => 'プロフィール';

  @override
  String get retry => '再試行';

  @override
  String get newCommunityCenter => '新コミュニティセンター開設';

  @override
  String get communityCenterDesc => '来週、新しいコミュニティセンターが様々な施設とともにオープンします。';

  @override
  String get beachCleanup => 'ビーチクリーン活動';

  @override
  String get beachCleanupDesc => '毎月のビーチクリーン活動に参加しましょう。';

  @override
  String get summerFestival => '夏祭り企画会議';

  @override
  String get summerFestivalDesc => '今年の夏祭りの企画会議を開催します。';

  @override
  String get resetPasswordTitle => 'パスワードの再設定';

  @override
  String get resetPasswordSubtitle => 'メールアドレスを入力して再設定手順を受け取ってください';

  @override
  String get resetPasswordSent => 'パスワード再設定の手順をメールで送信しました';

  @override
  String get resetPasswordFailed => 'パスワードの再設定に失敗しました';

  @override
  String get newPassword => '新しいパスワード';

  @override
  String get confirmPassword => 'パスワードの確認';

  @override
  String get passwordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get resetPasswordButton => 'パスワードを再設定';

  @override
  String get requestPasswordReset => '認証コードを送信';

  @override
  String get resetPasswordSuccess => 'パスワードが正常に再設定されました';

  @override
  String get errorOccurred => '予期せぬエラーが発生しました。もう一度お試しください。';

  @override
  String get feed => 'Feed';

  @override
  String get failedToUpdateProfile => 'Failed to update profile settings';

  @override
  String get role => 'Role';

  @override
  String get cancel => 'Cancel';

  @override
  String get gradeInputHint => 'Enter a number 1-6 or OB';

  @override
  String get invalidGrade => 'Please enter a number from 1 to 6, or OB';

  @override
  String get noName => 'No Name';

  @override
  String get feedFeature => '掲示板';

  @override
  String get studyFeature => '学習';
}
