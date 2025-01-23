
# Shelify 📚🎧  

**Shelify** is a feature-rich Flutter app that allows users to manage and explore books and audiobooks effortlessly. Whether you're a bibliophile or an audiobook enthusiast, Shelify has you covered with an intuitive and elegant user experience.  

---

## ✨ Features  

### **Books**  
- **Check Availability**: See if your favorite books are available in the library.  
- **Add to Favorites**: Save books to your personal favorites list for easy access.  
- **Search & Filters**: Search for books and filter them by genre.  

### **Audiobooks**  
- **Detailed View**: Access detailed information about audiobooks.  
- **Play Audiobooks Online**: Enjoy streaming your audiobooks seamlessly.  
- **Audio Player Controls**:  
  - Adjust playback speed.  
  - Jump few seconds backward or forward for a smoother listening experience.  
- **Favorites**: Keep track of your favorite audiobooks.  

### **Account Management**  
- **Register & Login**: Create an account or log in securely using Firebase authentication.  
- **Forgot Password**: Reset your password if you forget it.  
- **Change Password**: Update your account password anytime.  
- **Delete Account**: Remove your account and all associated data.  
- **Logout**: Log out with a smooth animation and transition.  

### **Beautiful Animations and Transitions**  
Enjoy a visually stunning app experience with thoughtfully designed animations and transitions that make navigating Shelify delightful.  

### **Cross-Platform Support**  
Shelify is compatible with **Android**, **iOS**, and **Web**, ensuring a seamless experience across multiple platforms.  

---

## 🛠️ Setup Guide  

To get started with **Shelify**, follow these steps:  

### **1. Clone the Repository**  
```bash  
git clone https://github.com/TheDharmarajsinh/Shelify.git  
cd Shelify  
```  

### **2. Setup Firebase**  
Shelify uses Firebase for authentication and data storage.  

#### **Firebase Configuration**  
1. Go to the [Firebase Console](https://console.firebase.google.com/).  
2. Create a Firebase project for your app.  
3. Add your platforms (Android, iOS, Web) and download the respective configuration files:  
   - `google-services.json` for Android  
   - `GoogleService-Info.plist` for iOS  
   - Firebase configuration snippet for Web  
4. Place these files in the appropriate locations:  
   - **Android**: Place `google-services.json` in the `android/app` directory.  
   - **iOS**: Place `GoogleService-Info.plist` in the `ios/Runner` directory.  
   - **Web**: Add the configuration snippet in `web/index.html`.  

#### **Enable Firebase Authentication**  
1. In the Firebase Console, go to **Authentication > Sign-In Methods**.  
2. Enable Email/Password authentication.  

#### **Create Firestore Collections**  
1. Go to **Firestore Database** in the Firebase Console.  
2. Create the following collections:  

##### **Books Collection**  
- **Collection Name**: `books`  
- **Document IDs**: `1`, `2`, `3`... (for more books, prefix the ID with `b-`)  
- **Fields**:  
  - `author` (String)  
  - `available` (Boolean)  
  - `cover` (String - URL of the book cover)  
  - `description` (String)  
  - `genre` (String)  
  - `id` (String)  
  - `title` (String)  

##### **Audiobooks Collection**  
- **Collection Name**: `audiobooks`  
- **Document IDs**: `1`, `2`, `3`... (for more audiobooks, prefix the ID with `a-`)  
- **Fields**:  
  - `audio_url` (String - URL of the audiobook file)  
  - `author` (String)  
  - `cover` (String - URL of the audiobook cover)  
  - `description` (String)  
  - `duration` (Number)  
  - `genre` (String)  
  - `id` (String)  
  - `title` (String)  

### **3. Install Dependencies**  
Run the following command to install the required Flutter dependencies:  
```bash  
flutter pub get  
```  

### **4. Run the App**  
To run the app on your preferred platform:  
```bash  
flutter run  
```  

---

## 🖼️ Screenshots  
![01 SS](https://github.com/user-attachments/assets/f1e5d7db-c5a7-46e5-a57f-a1538fb9c321)
![02 SS](https://github.com/user-attachments/assets/40533269-14e3-4c66-9535-35f6e8afc7a4)
![03 SS](https://github.com/user-attachments/assets/c0c8439d-d898-47d3-9b7d-e7f1d4a380e9)
![04 SS](https://github.com/user-attachments/assets/e1490c1f-64c8-4688-b2e0-1e9d681081c1)
![05 SS](https://github.com/user-attachments/assets/78bfcfba-722b-41ac-910d-4d172ec71517)
![06 SS](https://github.com/user-attachments/assets/386df959-d33a-49b5-a7f8-4d3a08019ed2)
![07 SS](https://github.com/user-attachments/assets/9bda889a-aa64-45f5-910e-fce731021915)
![08 SS](https://github.com/user-attachments/assets/9bcb52b6-6963-41b1-a1a9-7c69d0033506)
![09 SS](https://github.com/user-attachments/assets/ea025107-f2f4-4f58-82b0-5c90777644dd)

---

## 🚀 Technologies Used  
- **Flutter**: Cross-platform app development.  
- **Firebase**: Backend services for authentication and data storage.  

---

## 🤝 Contributing  
Contributions are welcome! If you'd like to contribute to Shelify, please follow these steps:  
1. Fork the repository.  
2. Create a feature branch:  
   ```bash  
   git checkout -b feature-name  
   ```  
3. Commit your changes:  
   ```bash  
   git commit -m "Add a new feature"  
   ```  
4. Push to the branch:  
   ```bash  
   git push origin feature-name  
   ```  
5. Open a Pull Request.   

---  

Thanks for using *Shelify*.
