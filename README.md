## ⚠️ Required Setup

Before building and running the app, you **must** generate a `Config.plist` file. This file is required to provide the API key for Coincap.

### 🔧 Generate `Config.plist`

Run the following script and provide your **Coincap API key** when prompted:

```bash
./generate_config.sh
```
This will generate a Config.plist with the following structure:
```
<dict>
    <key>CoincapApiKey</key>
    <string>YOUR_API_KEY</string>
    <key>CoincapApiBaseUrl</key>
    <string>https://rest.coincap.io/v3/assets/bitcoin</string>
</dict>
```
### 📥 Important:
Make sure Config.plist is added to your Xcode project (via drag & drop or File → Add Files to ...).
If this file is missing at runtime, the app will throw a fatal error and crash.

### 🖼️ Launch Screen
Although the entire UI is built programmatically, the project includes one storyboard file: LaunchScreen.storyboard.
This is used only to define the app’s launch screen and ensures proper content rendering on large screen devices like iPads or iPhones with Dynamic Island.
