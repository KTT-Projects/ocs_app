<?php
class Response {
    public static function json($data, $status = 200) {
        header('Content-Type: application/json; charset=utf-8');
        http_response_code($status);
        echo json_encode($data);
        exit();
    }

    public static function success($data = null, $message = 'Success') {
        return self::json([
            'status' => 'success',
            'message' => $message,
            'data' => $data
        ]);
    }

    public static function error($message = 'Error', $status = 400) {
        return self::json([
            'status' => 'error',
            'message' => $message
        ], $status);
    }
}