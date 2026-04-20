// =============================================================================
// Firebase Messaging Service Worker (Web)
//
// Gestiona notificaciones push en background para la versión web.
// Las credenciales se rellenan automáticamente tras `flutterfire configure`.
// =============================================================================

importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  // TODO: Rellenar tras ejecutar `flutterfire configure`
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "...",
});

const messaging = firebase.messaging();

// Manejo de mensajes en background (cuando la pestaña no tiene foco)
messaging.onBackgroundMessage((payload) => {
  const { title, body } = payload.notification || {};
  if (title) {
    self.registration.showNotification(title, {
      body: body || "",
      icon: "/icons/Icon-192.png",
      badge: "/icons/Icon-192.png",
    });
  }
});
