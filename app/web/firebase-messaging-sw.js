const firebaseConfig = {
  apiKey: "AIzaSyC629rx4zPZOF_WsShGUW219UZyYE5kZdQ",
  authDomain: "shineportal-ktt.firebaseapp.com",
  projectId: "shineportal-ktt",
  storageBucket: "shineportal-ktt.appspot.com",
  messagingSenderId: "299843107216",
  appId: "1:299843107216:web:e06d18c6e193209491db15",
  measurementId: "G-6YRL4BN758",
};

function hasFirebaseConfig(config) {
  return [
    config.apiKey,
    config.projectId,
    config.messagingSenderId,
    config.appId,
  ].every((value) => value && !value.startsWith("__"));
}

if (hasFirebaseConfig(firebaseConfig)) {
  importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
  importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

  firebase.initializeApp(firebaseConfig);
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log("FCM background message received", payload);
    const notification = payload.notification || {};
    const data = payload.data || {};
    const title = notification.title || data.title || "KamiLander";
    const options = {
      body: notification.body || data.body || "",
      icon: notification.icon || "/icons/Icon-192.png",
      data,
    };
    self.registration.showNotification(title, options);
  });

  self.addEventListener("notificationclick", (event) => {
    event.notification.close();
    const data = event.notification.data || {};
    const targetUrl = data.web_link || "/";

    event.waitUntil(
      clients
        .matchAll({ type: "window", includeUncontrolled: true })
        .then((clientList) => {
          for (const client of clientList) {
            if ("focus" in client) {
              client.navigate(targetUrl);
              return client.focus();
            }
          }
          if (clients.openWindow) {
            return clients.openWindow(targetUrl);
          }
          return undefined;
        })
    );
  });
} else {
  console.warn("Firebase Messaging service worker is not configured.");
}
