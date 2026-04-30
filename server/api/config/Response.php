<?php
class Response
{
  private static $responded = false;

  public static function registerErrorHandlers()
  {
    ini_set('display_errors', '0');

    set_error_handler(function ($severity, $message, $file, $line) {
      // Convert PHP warnings/notices to exceptions so we can return JSON
      throw new ErrorException($message, 0, $severity, $file, $line);
    });

    set_exception_handler(function ($e) {
      error_log('Unhandled exception: ' . $e->getMessage() . ' in ' . $e->getFile() . ':' . $e->getLine());
      if (!self::$responded) {
        self::error('Internal server error', 500, [
          'error_type' => get_class($e),
          'error_file' => $e->getFile(),
          'error_line' => $e->getLine(),
          'stack_trace' => $e->getTraceAsString()
        ]);
      }
    });

    register_shutdown_function(function () {
      $error = error_get_last();
      if ($error && in_array($error['type'], [E_ERROR, E_PARSE, E_CORE_ERROR, E_COMPILE_ERROR, E_USER_ERROR])) {
        error_log('Fatal error: ' . $error['message'] . ' in ' . $error['file'] . ':' . $error['line']);
        if (!self::$responded) {
          http_response_code(500);
          header('Content-Type: application/json; charset=utf-8');
          echo json_encode([
            'status' => 'error',
            'message' => 'Internal server error',
            'error_details' => [
              'error_type' => 'FatalError',
              'error_file' => $error['file'],
              'error_line' => $error['line'],
              'stack_trace' => $error['message']
            ]
          ]);
        }
      }
    });
  }

  public static function json($data, $status = 200)
  {
    self::$responded = true;
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
    self::$responded = true;
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
