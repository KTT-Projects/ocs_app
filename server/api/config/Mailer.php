<?php
class Mailer
{
  private $from = "noreply@kttprojects.com";
  private $fromName = "Osakikamijima Student Community";
  private $apiUrl = "https://kamilander.com";
  private $frontendUrl = "https://kamilander.com";

  public function sendVerificationEmail($to, $otp, $lang = 'en')
  {
    try {
      $subject = $lang === 'ja' ? "メールアドレスの確認" : "Verify Your Email Address";

      // Create HTML message with OTP
      $message = "
            <!DOCTYPE html>
            <html>
            <head>
                <title>Email Verification</title>
                <meta charset='utf-8'>
                <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                <meta name='color-scheme' content='light dark'>
                <meta name='supported-color-schemes' content='light dark'>
            </head>
            <body style='margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f7f7f7;'>
                <div style='max-width: 600px; margin: 0 auto; padding: 40px 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>
                    <div style='text-align: center; margin-bottom: 30px;'>
                        <h1 style='color: #333333; margin: 0; font-size: 24px;'>" .
        ($lang === 'ja' ? "大崎上島学生コミュニティへようこそ！" : "Welcome to Osakikamijima Student Community!") .
        "</h1>
                    </div>
                    <p style='color: #555555; font-size: 16px; line-height: 1.5; margin-bottom: 25px;'>" .
        ($lang === 'ja' ?
          "ご登録ありがとうございます。メールアドレスを確認するために、以下の認証コードをご使用ください：" :
          "Thank you for signing up. To verify your email address, please use the following verification code:") .
        "</p>
                    <div style='margin: 30px 0; text-align: center; background-color: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <div style='font-size: 32px; letter-spacing: 8px; font-weight: bold; color: #333333; font-family: monospace;'>
                            {$otp}
                        </div>
                    </div>
                    <p style='color: #555555; font-size: 14px; line-height: 1.5; margin-bottom: 25px;'>" .
        ($lang === 'ja' ?
          "この認証コードは10分後に期限切れとなります。" :
          "This verification code will expire in 10 minutes for security purposes.") .
        "</p>
                    <hr style='border: none; border-top: 1px solid #eeeeee; margin: 30px 0;'>
                    <p style='color: #999999; font-size: 12px; text-align: center;'>" .
        ($lang === 'ja' ?
          "アカウントを作成していない場合は、このメールを無視してください。" :
          "If you did not create an account, please disregard this email.") .
        "</p>
                </div>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px; text-align: center;'>
                    <p style='color: #999999; font-size: 12px; margin: 0;'>" .
        ($lang === 'ja' ?
          "これは自動送信メールです。返信はできませんのでご了承ください。" :
          "This is an automated message, please do not reply to this email.") .
        "</p>
                </div>
            </body>
            </html>
            ";

      // Headers with proper encoding and authentication
      $headers = array(
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=utf-8',
        'From: =?UTF-8?B?' . base64_encode($this->fromName) . '?= <' . $this->from . '>',
        'Reply-To: ' . $this->from,
        'Return-Path: ' . $this->from,
        'Message-ID: <' . time() . '-' . md5($to . time()) . '@' . parse_url($this->apiUrl, PHP_URL_HOST) . '>',
        'X-Mailer: PHP/' . phpversion(),
        'X-Sender: ' . $this->from,
        'X-Priority: 3',
        'List-Unsubscribe: <mailto:' . $this->from . '?subject=unsubscribe>',
        'Auto-Submitted: auto-generated',
        'Precedence: bulk',
        'X-Auto-Response-Suppress: All'
      );

      // Try to send email
      if (!mail($to, $subject, $message, implode("\r\n", $headers), '-f ' . $this->from)) {
        error_log("Failed to send verification email to: " . $to);
        throw new Exception("Failed to send verification email");
      }

      return true;
    } catch (Exception $e) {
      error_log("Email sending error: " . $e->getMessage());
      return false;
    }
  }

  public function sendPasswordResetEmail($to, $otp, $lang = 'en')
  {
    try {
      $subject = $lang === 'ja' ? "パスワードリセットのご依頼" : "Password Reset Request";

      // Create HTML message with OTP based on language
      $message = "
            <!DOCTYPE html>
            <html>
            <head>
                <title>" . ($lang === 'ja' ? "パスワードリセット" : "Password Reset") . "</title>
                <meta charset='utf-8'>
                <meta name='viewport' content='width=device-width, initial-scale=1.0'>
                <meta name='color-scheme' content='light dark'>
                <meta name='supported-color-schemes' content='light dark'>
            </head>
            <body style='margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f7f7f7;'>
                <div style='max-width: 600px; margin: 0 auto; padding: 40px 20px; background-color: #ffffff; border-radius: 8px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);'>
                    <div style='text-align: center; margin-bottom: 30px;'>
                        <h1 style='color: #333333; margin: 0; font-size: 24px;'>" .
        ($lang === 'ja' ? "パスワードリセットのご依頼" : "Password Reset Request") .
        "</h1>
                    </div>
                    <p style='color: #555555; font-size: 16px; line-height: 1.5; margin-bottom: 25px;'>" .
        ($lang === 'ja' ?
          "パスワードリセットのご依頼を受け付けました。以下の認証コードをご使用ください：" :
          "We received a request to reset your password. To proceed with the password reset, please use the following code:") .
        "</p>
                    <div style='margin: 30px 0; text-align: center; background-color: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <div style='font-size: 32px; letter-spacing: 8px; font-weight: bold; color: #333333; font-family: monospace;'>
                            {$otp}
                        </div>
                    </div>
                    <p style='color: #555555; font-size: 14px; line-height: 1.5; margin-bottom: 25px;'>" .
        ($lang === 'ja' ?
          "このコードは10分後に期限切れとなります。このパスワードリセットをリクエストしていない場合は、このメールを無視してください。" :
          "This code will expire in 10 minutes for security purposes. If you did not request a password reset, please ignore this email.") .
        "</p>
                    <hr style='border: none; border-top: 1px solid #eeeeee; margin: 30px 0;'>
                    <p style='color: #999999; font-size: 12px; text-align: center;'>" .
        ($lang === 'ja' ?
          "セキュリティ上の理由により、このコードは他の人と共有しないでください。" :
          "For security reasons, never share this code with anyone.") .
        "</p>
                </div>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px; text-align: center;'>
                    <p style='color: #999999; font-size: 12px; margin: 0;'>" .
        ($lang === 'ja' ?
          "これは自動送信メールです。返信はできませんのでご了承ください。" :
          "This is an automated message, please do not reply to this email.") .
        "</p>
                </div>
            </body>
            </html>
            ";

      // Headers with proper encoding and authentication
      $headers = array(
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=utf-8',
        'From: =?UTF-8?B?' . base64_encode($this->fromName) . '?= <' . $this->from . '>',
        'Reply-To: ' . $this->from,
        'Return-Path: ' . $this->from,
        'Message-ID: <' . time() . '-' . md5($to . time()) . '@' . parse_url($this->apiUrl, PHP_URL_HOST) . '>',
        'X-Mailer: PHP/' . phpversion(),
        'X-Sender: ' . $this->from,
        'X-Priority: 3',
        'List-Unsubscribe: <mailto:' . $this->from . '?subject=unsubscribe>',
        'Auto-Submitted: auto-generated',
        'Precedence: bulk',
        'X-Auto-Response-Suppress: All'
      );

      // Try to send email
      if (!mail($to, $subject, $message, implode("\r\n", $headers))) {
        error_log("Failed to send password reset email to: " . $to);
        throw new Exception("Failed to send password reset email");
      }

      return true;
    } catch (Exception $e) {
      error_log("Email sending error: " . $e->getMessage());
      return false;
    }
  }
}
