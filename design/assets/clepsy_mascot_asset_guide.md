

````
# Clepsy Mascot Asset Guide (v1.0)

This folder contains the production-ready assets for **Clepsy**, the accountability mascot for the Clepsy iOS app. These assets use a **Decoupled Layering System** to allow for dynamic state changes (swapping expressions and sand levels) without bloated file sizes.

## 📁 Folder Structure & Naming
All images follow the `prefix_name_value@nX.png` convention. 
- **@2x / @3x**: iOS scale factors for Retina and Super Retina displays.
- **Underscores**: Used for programmatic compatibility in Xcode.

---

## 🛠 Implementation Strategy (The ZStack)
Do **not** combine these images in a design tool. They must be layered programmatically in the app's UI code using a `ZStack` so that the face and body can be updated independently based on user data.

**Canvas Size:** 240 x 320 pt (All layers share this size for perfect alignment).

### SwiftUI Example:
```swift
ZStack {
    // Layer 1: The Body (Sand Level)
    Image("body_level_50") // Logic-driven
        .resizable()
        .scaledToFit()
    
    // Layer 2: The Face (Expression)
    Image("patience_face") // Context-driven
        .resizable()
        .scaledToFit()
}
.frame(width: 240, height: 320)
````

---

## **🧠 Logic & State Mapping**

Use the following table to determine which assets to display based on the app's state and user progress:

| App Context | User Progress | Body Asset | Face Asset |
| :---- | :---- | :---- | :---- |
| **Morning Start** | 0% | body\_level\_0 | patience\_face |
| **Shield Screen (Blocked)** | \< 100% | (Current Progress) | patience\_face |
| **Earning Milestone** | Any | (Current Progress) | encouraging\_face |
| **Unlock Success** | Any | (Current Progress) | encouraging\_face |
| **Daily Goal Met** | 100% | body\_level\_100 | celebrating\_face |
| **Streak Achieved** | 100% | body\_level\_100 | celebrating\_face |

---

## **✨ Animation Requirements**

To bring Clepsy to life, apply a **Subtle Float** animation to the entire ZStack:

* **Type:** Vertical periodic offset (Y-axis).  
* **Amplitude:** 8pt to 10pt.  
* **Duration:** 3.5 seconds (linear loop).  
* **Goal:** Ensure the face and body move together so they don't drift apart.

---

## **🎨 Asset Technical Specs**

* **Format:** Transparent PNG-24.  
* **Color Space:** sRGB.  
* **Master Icon:** app\_store\_icon.png (1024x1024 px) is located in the root for App Store submission; it should NOT be used for in-app layering.

```

---

### **Final PM Checklist for Your Folder**
* [ ] **27 files** total for in-app use (3 faces + 6 body levels, each in @1x, @2x, @3x).
* [ ] **1 master file** for the App Store (1024x1024).
* [ ] **Naming Check:** All files use `_` and lowercase letters only.

**This guide is now complete! Do you need help with the next step, such as drafti
```

