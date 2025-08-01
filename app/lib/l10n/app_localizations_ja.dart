// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

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
  String get displayNameTooLong => '表示名は30文字以内にしてください';

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
  String get studyFeature => '学習';

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
  String get feed => '掲示板';

  @override
  String get failedToUpdateProfile => 'プロフィールの更新に失敗しました';

  @override
  String get role => '役割';

  @override
  String get cancel => 'キャンセル';

  @override
  String get gradeInputHint => '1-6の数字またはOBを入力';

  @override
  String get invalidGrade => '1-6の数字またはOBを入力してください';

  @override
  String get noName => '名前未設定';

  @override
  String get failedToLoadFeeds => 'フィードの読み込みに失敗しました';

  @override
  String get failedToLoadPosts => '投稿の読み込みに失敗しました';

  @override
  String get failedToJoinFeed => 'フィードへの参加に失敗しました';

  @override
  String get failedToCreateFeed => 'フィードの作成に失敗しました';

  @override
  String get failedToCreatePost => '投稿の作成に失敗しました';

  @override
  String get failedToVote => '投票に失敗しました';

  @override
  String get createFeed => 'フィードを作成';

  @override
  String get createPost => '投稿を作成';

  @override
  String get feedId => 'フィードID（一意の識別子）';

  @override
  String get feedDisplayName => '表示名';

  @override
  String get feedDescription => '説明';

  @override
  String get feedRules => 'ルール（任意）';

  @override
  String get feedIdRequired => 'フィードIDは必須です';

  @override
  String get feedIdInvalid => '小文字、数字、アンダースコアのみ使用可能です';

  @override
  String get descriptionRequired => '説明は必須です';

  @override
  String get titleRequired => 'タイトルは必須です';

  @override
  String get contentRequired => '内容は必須です';

  @override
  String get addImage => '画像を追加';

  @override
  String get feedIdHelperText => '小文字、数字、アンダースコアのみ使用可能';

  @override
  String get postTitle => 'タイトル';

  @override
  String get writePost => '投稿を書く...';

  @override
  String newPostIn(Object feedName) {
    return '$feedName';
  }

  @override
  String get openInFullPage => '全画面で開く';

  @override
  String get post => '投稿';

  @override
  String get discover => '発見';

  @override
  String get home => 'ホーム';

  @override
  String get sortBy => '並び替え';

  @override
  String get latest => '最新';

  @override
  String get popular => '人気';

  @override
  String get defaultSort => 'おすすめ';

  @override
  String get feedOptions => 'フィードオプション';

  @override
  String get createNewFeed => '新しいフィードを作成';

  @override
  String get reorderFeeds => 'フィードを並び替え';

  @override
  String get leaveFeed => 'フィードを離脱';

  @override
  String get selectNewAdmin => '新しい管理者を選択';

  @override
  String get confirmDeleteFeed => '他にメンバーがいないため、離脱するとこのフィードは削除されます。続行しますか？';

  @override
  String get ok => 'OK';

  @override
  String get save => '保存';

  @override
  String get searchFeeds => 'フィードを検索...';

  @override
  String get population => '人口';

  @override
  String get latestActivity => '最新のアクティビティ';

  @override
  String get noFeedsFound => 'フィードが見つかりません。';

  @override
  String get join => '参加';

  @override
  String get discoverMoreFeeds => 'もっとフィードを発見';

  @override
  String get newPost => '新しい投稿';

  @override
  String get newPostTo => '投稿先...';

  @override
  String get chooseFeed => 'フィードを選択';

  @override
  String get feedCreatedSuccess => 'フィードが作成されました';

  @override
  String get titleTooLong => 'タイトルは300文字以内で入力してください';

  @override
  String get contentTooLong => '内容は5000文字以内で入力してください';

  @override
  String get descriptionTooLong => '説明は1000文字以内にしてください';

  @override
  String get rulesTooLong => 'ルールは1000文字以内にしてください';

  @override
  String get feedSettings => 'フィード設定';

  @override
  String get feedUpdatedSuccess => 'フィードが更新されました';

  @override
  String get failedToLoadFeedMembers => 'メンバーの読み込みに失敗しました';

  @override
  String get currentAdmin => '現在の管理者';

  @override
  String get change => '変更';

  @override
  String get feedDetails => 'フィード詳細';

  @override
  String get members => 'メンバー';

  @override
  String get showMore => 'もっと見る';

  @override
  String get showLess => '閉じる';
}
