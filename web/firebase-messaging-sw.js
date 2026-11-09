importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCQusAqHenqKzmrERiOVP99UvsEr5mywzQ",
  authDomain: "prep404fcm.firebaseapp.com",
  projectId: "prep404fcm",
  storageBucket: "prep404fcm.firebasestorage.app",
  messagingSenderId: "508019570429",
  appId: "1:508019570429:web:0e3b1014ce9147c2fbf094",
  measurementId: "G-Z79M0EGXFJ"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification?.title || 'Prep404 Notification';
  const notificationOptions = {
    body: payload.notification?.body,
    icon: '/favicon.png',
    data: payload.data
  };
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
