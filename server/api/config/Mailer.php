<?php
class Mailer
{
    public static function send($to, $subject, $body)
    {
        // Email headers
        $headers = [
            'MIME-Version: 1.0',
            'Content-type: text/plain; charset=UTF-8',
            'From: OCS System <no-reply@ocs.kttprojects.com>',
            'Reply-To: no-reply@ocs.kttprojects.com',
            'X-Mailer: PHP/' . phpversion()
        ];

        // Encode subject for UTF-8
        $encodedSubject = '=?UTF-8?B?' . base64_encode($subject) . '?=';

        try {
            // Send email using PHP mail function
            $result = mail(
                $to,
                $encodedSubject,
                $body,
                implode("\r\n", $headers)
            );

            if (!$result) {
                error_log("Failed to send email to: $to");
                return false;
            }

            return true;
        } catch (Exception $e) {
            error_log("Error sending email: " . $e->getMessage());
            return false;
        }
    }

    public static function sendBilingual($to, $subjectEn, $subjectJa, $bodyEn, $bodyJa)
    {
        $subject = "$subjectEn / $subjectJa";
        $body = "English:\n\n$bodyEn\n\n\n日本語:\n\n$bodyJa";
        return self::send($to, $subject, $body);
    }

    public static function getPasswordResetEmail($resetLink)
    {
        $bodyEn = "Hello,\n\n" .
                  "You have requested to reset your password. Please click the link below to reset your password:\n\n" .
                  "$resetLink\n\n" .
                  "This link will expire in 1 hour.\n\n" .
                  "If you did not request this password reset, please ignore this email.\n\n" .
                  "Best regards,\n" .
                  "OCS Team";

        $bodyJa = "こんにちは、\n\n" .
                  "パスワードの再設定がリクエストされました。以下のリンクをクリックしてパスワードを再設定してください：\n\n" .
                  "$resetLink\n\n" .
                  "このリンクは1時間後に期限切れとなります。\n\n" .
                  "このパスワード再設定をリクエストしていない場合は、このメールを無視してください。\n\n" .
                  "よろしくお願いいたします。\n" .
                  "OCSチーム";

        return [
            'en' => $bodyEn,
            'ja' => $bodyJa,
            'subject_en' => 'Password Reset Request',
            'subject_ja' => 'パスワード再設定のリクエスト'
        ];
    }
}
