# Push notifications

The backend sends true background push notifications through Firebase Cloud Messaging HTTP v1. Clients register their FCM token after login and unregister it on logout.

## Database

Apply `server/db/push_notifications.sql`, or rebuild from `server/db/database_setup.sql`.

## Environment

Required:

- `FCM_PROJECT_ID`: Firebase project ID.
- One of:
  - `GOOGLE_APPLICATION_CREDENTIALS`: path to a Firebase service account JSON file.
  - `FCM_SERVICE_ACCOUNT_PATH`: path to a Firebase service account JSON file.
  - `FCM_SERVICE_ACCOUNT_JSON`: raw service account JSON.
  - `FCM_SERVICE_ACCOUNT_JSON_BASE64`: base64-encoded service account JSON.

Recommended:

- `PUSH_FLUSH_SECRET`: shared secret for cron/worker calls to flush queued notifications.

The PHP runtime needs the `curl` and `openssl` extensions enabled.

## API

All endpoints live at `api/push_notifications.php`.

- `POST ?action=register`: authenticated. Body: `platform` (`ios`, `android`, `web`), `token`, optional `device_id`, `app_version`, `locale`.
- `POST ?action=unregister`: authenticated. Body: `token` or `device_id`.
- `GET ?action=devices`: authenticated. Lists registered devices for the current user.
- `POST ?action=test`: authenticated. Sends a test notification to the current user's devices.
- `POST|GET ?action=flush`: processes pending queued notifications. If `PUSH_FLUSH_SECRET` is set, pass it as `X-Push-Secret` or `secret`; otherwise an authenticated request is required.

Recommended cron:

```sh
curl -fsS -H "X-Push-Secret: $PUSH_FLUSH_SECRET" "https://ocs.kttprojects.com/api/push_notifications.php?action=flush&limit=100"
```

The Flutter client setup is documented in `app/FIREBASE_PUSH_SETUP.md`.
