// Import Firebase scripts
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

// Initialize Firebase
firebase.initializeApp({
    apiKey: "AIzaSyAAMaCrbgspznOqKa0pSRb51cYLZOIfGfw",
    authDomain: "mindmentor-bc846.firebaseapp.com",
    databaseURL: "https://mindmentor-bc846-default-rtdb.asia-southeast1.firebasedatabase.app",
    projectId: "mindmentor-bc846",
    storageBucket: "mindmentor-bc846.appspot.com",
    messagingSenderId: "1090721689537",
    appId: "1:1090721689537:web:b17323740f1d7e87474940",
    measurementId: "G-23CR49BMPM"
});

// Retrieve Firebase Messaging instance
const messaging = firebase.messaging();
