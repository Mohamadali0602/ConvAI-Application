# iOS AI Speech-to-Speech Application  01/06/2025

This is my **first fully working iOS application**. During development, I used AI tools for about 50% of the time, mainly to optimize my code and explore alternative solutions. My learning came from **official documentation, online courses, and YouTube**, which I highly recommend to anyone learning to code.

The main goal of this project was to create a solution that **didn’t exist in the App Store** at the time: providing **real-time speech-to-speech AI app** for iOS users.

---

## Technology Overview

- **Speech-to-Speech AI** powered by the **Gemini API**  
  Gemini’s speech-to-speech functionality was **not fully developed for iOS** at the time of this project like the live api and ephemeral tokens for ios. Google did not provide an official iOS SDK for Gemini, so I built the **necessary iOS functionality** myself.
  
- **WebSockets** for real-time communication  
  A **direct client-AI connection** required ephemeral tokens, which I implemented from scratch.

- **Audio optimization on iPhone**  
  I fine-tuned the audio pipeline to ensure the **best audio quality**, with **no interruptions, lag, or buzzing**, even during prolonged usage.



---

## Development Journey

1. **Design Phase**  
   I started by creating a **Figma design** to visualize the app’s interface and workflow. This helped me clarify the concept.

2. **Prototype Phase**  
   Though I faced many failures, I built a **working AI conversation prototype** without any backend or additional functionalities. This allowed me to focus on core interactions first.

3. **Backend & Features Integration**  
   After the prototype was successful, I added backend functionality, ephemeral token handling, and full integration with Gemini API.

- **Time invested:** ~2.5 months  
- **Hours per week:** 70+  
- **Tech stack:** Xcode / Swift, Firebase, Firestore, Google Cloud, Gemini API, WebSockets  

---

## Challenges and Solutions

- **Gemini API iOS support**: Not available at the time → implemented manually
- **Ephemeral token for IOS**: Custom solution to connect to AI via WebSocket which requires ephemeral token
- **Real-time audio stability**: Optimized iPhone audio pipeline → smooth, high-quality speech output  

---

## Lessons Learned

- I thrive on **challenging problems**  
- I don’t give up, even after **failing for several days and weeks in a row**  
- Persistence and iteration are more valuable than early success  
- Learned hands-on about **AI integration, WebSockets, real-time audio processing, and fullstack software development**

---

## Reflection

This project is **one of my proudest achievements**. However, the only downside is that it's not profitable because the cost can vary from 10 to 30 dollars per user per month if used daily and heavily and my aim was to make the app for 20$/month for heavy usage. So I kept the app under the radar.

Despite being non-profitable due to high per-user costs, it demonstrates that a single dedicated developer can build a **highly functional, cutting-edge iOS app** from scratch.  
