<?php
class Response
{
  public static function json($data, $status = 200)
  {
    header('Content-Type: application/json; charset=utf-8');
    http_response_code($status);
    $json_output = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE); // Added flags for better UTF-8 handling

    // Check for JSON encoding errors
    if ($json_output === false) {
      // Log the error internally
      error_log('JSON Encode Error: ' . json_last_error_msg());

      // Send a generic JSON error response
      http_response_code(500); // Internal Server Error
      echo json_encode([
        'status' => 'error',
        'message' => 'Internal server error: Failed to encode JSON response.',
        'json_error_code' => json_last_error(),
        'json_error_message' => json_last_error_msg()
      ]);
    } else {
      echo $json_output;
    }
    exit();
  }

  public static function success($data = null, $message = 'Success')
  {
    return self::json([
      'status' => 'success',
      'message' => $message,
      'data' => $data
    ]);
  }

  public static function error($message = 'Error', $status = 400, $details = null)
  {
    $response = [
      'status' => 'error',
      'message' => $message
    ];

    if ($details) {
      $response['error_details'] = $details;
    }

    return self::json($response, $status);
  }
}
