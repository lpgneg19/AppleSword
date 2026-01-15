# AppleSword (Native macOS)

<p align="center">
  <img src="AppleSword/Assets.xcassets/AppIcon.appiconset/icon.png" width="128" height="128" alt="AppleSword Logo">
  <br>
  <b>A powerful, native download manager for macOS, built with SwiftUI.</b>
</p>

AppleSword is a native rewrite of the popular [Motrix](https://motrix.app) download manager, designed specifically for the macOS ecosystem. By leveraging the power of SwiftUI and the robustness of the `aria2` engine, AppleSword delivers a fast, efficient, and deeply integrated download experience.

[English] | [简体中文](./README-CN.md)

---

## 🚀 Key Features

- **Pure Native UI**: Built entirely with SwiftUI for a smooth, responsive interface that matches the macOS aesthetic.
- **Versatile Protocol Support**: Effortlessly handle HTTP, FTP, BitTorrent, Magnet links, and more.
- **High Performance**: Powered by a highly optimized `aria2` core, ensuring maximum speed with minimal memory footprint.
- **Smart Engine Management**: Automatically handles the lifecycle of the download engine—just open the app and start downloading.
- **Deep System Integration**:
  - **Menu Bar Extra**: Monitor real-time download/upload speeds and manage tasks directly from the menu bar.
  - **Dark Mode & Accent Colors**: Full support for system-wide appearance settings.
  - **Safari Extension**: Integrated Safari Web Extension for seamless download capturing.
- **Apple Silicon Native**: Optimized for both M-series and Intel-based Macs.

## 📦 Installation & Development

AppleSword is currently in active development. You can build it from source to try the latest features.

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Build Instructions
1. **Clone the repository**:
   ```bash
   git clone https://github.com/agalwood/Motrix.git
   cd Motrix
   ```
2. **Generate the Xcode Project**:
   ```bash
   xcodegen generate
   ```
3. **Open and Run**:
   Open `AppleSword.xcodeproj` and run the `AppleSword` target.

## 🛠 Technology Stack

- **Frontend**: SwiftUI & Combine
- **Backend Engine**: [aria2](https://aria2.github.io/)
- **Communication**: [Aria2Kit](https://github.com/baptistecdr/Aria2Kit) (RPC)
- **Networking**: Alamofire
- **Project Management**: XcodeGen

## 🩺 Troubleshooting

If you encounter engine connection issues:
1. **Reset Engine**: Force quit any residual `aria2c` processes:
   ```bash
   pkill -9 aria2c
   ```
2. **Clear Data**: If configuration files are corrupted, try clearing the app data:
   ```bash
   rm -rf ~/Library/Application\ Support/AppleSword
   ```
3. **Check Logs**:
   - **App Logs**: `~/Library/Application Support/AppleSword/applesword.log`
   - **Engine Logs**: `~/Library/Application Support/AppleSword/aria2.log`

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome! Please check the [Contributing Guidelines](./CONTRIBUTING.md) for more information.

## 📜 License

AppleSword is released under the [MIT License](./LICENSE).

---
*Inspired by Motrix. Reborn for macOS.*
