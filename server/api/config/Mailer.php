<?php
class Mailer {
    private $from = "noreply@osakikamijima-student.com";
    private $fromName = "Osakikamijima Student Community";
    private $apiUrl = "https://ocs.kttprojects.com";
    private $frontendUrl = "https://ocs.kttprojects.com";

    public function sendVerificationEmail($to, $token) {
        try {
            $subject = "Verify Your Email Address";
            
            // Create verification URL
            $verifyUrl = $this->frontendUrl . "/verify?token=" . $token;
            
            // Create HTML message
            $message = "
            <html>
            <head>
                <title>Email Verification</title>
                <meta charset='utf-8'>
            </head>
            <body>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px;'>
                    <h2>Welcome to Osakikamijima Student Community!</h2>
                    <p>Thank you for signing up. Please verify your email address to complete your registration.</p>
                    <p style='margin: 25px 0;'>
                        <a href='{$verifyUrl}' 
                           style='background-color: #4CAF50; 
                                  color: white; 
                                  padding: 12px 25px; 
                                  text-decoration: none; 
                                  border-radius: 5px;
                                  display: inline-block;'>
                            Verify Email Address
                        </a>
                    </p>
                    <p>Or copy and paste this link in your browser:</p>
                    <p>{$verifyUrl}</p>
                    <p>This verification link will expire in 24 hours.</p>
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