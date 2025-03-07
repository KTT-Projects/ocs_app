<?php
class Mailer
{
  private $from = "noreply@osakikamijima-student.com";
  private $fromName = "Osakikamijima Student Community";
  private $apiUrl = "https://ocs.kttprojects.com";
  private $frontendUrl = "https://ocs.kttprojects.com";

  public function sendVerificationEmail($to, $otp)
  {
    try {
      $subject = "Verify Your Email Address";

      // Create HTML message with OTP
      $message = "
            <html>
            <head>
                <title>Email Verification</title>
                <meta charset='utf-8'>
            </head>
            <body>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
                    <h2>Welcome to Osakikamijima Student Community!</h2>
                    <p>Thank you for signing up. Please use the following code to verify your email address:</p>
                    <div style='margin: 25px 0; text-align: center;'>
                        <div style='font-size: 32px; letter-spacing: 5px; font-weight: bold;
                                  background-color: #f5f5f5; padding: 15px;
                                  border-radius: 5px; font-family: monospace;'>
                            {$otp}
                        </div>
                    </div>
                    <p>This verification code will expire in 10 minutes.</p>
                    <p>If you did not create an account, no further action is required.</p>
                </div>
            </body>
            </html>
            ";

      // Headers with proper encoding
      $headers = array(
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=utf-8',
        'From: =?UTF-8?B?' . base64_encode($this->fromName) . '?= <' . $this->from . '>',
        'Reply-To: ' . $this->from,
        'X-Mailer: PHP/' . phpversion()
      );

      // Try to send email
      if (!mail($to, $subject, $message, implode("\r\n", $headers))) {
        error_log("Failed to send verification email to: " . $to);
        throw new Exception("Failed to send verification email");
      }

      return true;
    } catch (Exception $e) {
      error_log("Email sending error: " . $e->getMessage());
      return false;
    }
  }
}
