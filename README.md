# Sleep Talk Recorder

夜间低功耗梦话自动监测 APP

[![Build and Release](https://github.com/Ht13142003/sleep-talk/actions/workflows/ci.yml/badge.svg)](https://github.com/Ht13142003/sleep-talk/actions/workflows/ci.yml)

## 功能特点

- **系统级后台保活**：Android 前台服务常驻 + iOS 后台音频模式，锁屏熄屏不断监听
- **超低功耗 VAD 触发**：智能人声检测算法，仅检测到说话时启动录音
- **录音完整管理**：列表展示、播放控制（0.5x-2.0x 变速）、批量删除
- **本地离线存储**：sqflite 数据库存储元数据，无需网络
- **深色护眼 UI**：深蓝/深灰夜间配色，夜间使用不刺眼

## 下载

从 [Releases](https://github.com/Ht13142003/sleep-talk/releases) 页面下载最新版本：

| 平台 | 文件 | 说明 |
|------|------|------|
| Android | `app-release.apk` | 直接安装到 Android 设备 |
| Android | `app-release.aab` | Google Play 商店发布用 |
| iOS | `sleep-talk-unsigned.ipa` | 未签名 IPA，需使用 AltStore/SideStore 侧载安装 |
| iOS | `Runner.app` | iOS 原始应用包 |

## 技术栈

- **Flutter** 3.44.0 (Dart SDK ^3.12.0)
- **音频录制**: `record` 插件 (AAC, 44.1kHz, 128kbps)
- **音频播放**: `audioplayers` (支持 0.5x-2.0x 变速)
- **本地数据库**: `sqflite`
- **后台服务**: `flutter_background_service`
- **权限管理**: `permission_handler`

## 本地开发

### 环境要求

- Flutter SDK 3.44.0+
- Android Studio (Android 开发)
- Xcode (iOS 开发，仅 macOS)

### 运行

```bash
# 获取依赖
flutter pub get

# 运行测试
flutter test

# 运行静态分析
flutter analyze

# 运行应用
flutter run

# 构建 Android APK
flutter build apk --release

# 构建 iOS (需 macOS)
flutter build ios --release --no-codesign
```

## 自动化构建

每次推送到 `main` 分支会自动触发 GitHub Actions 构建：
1. 运行测试和静态分析
2. 构建 Android APK + AppBundle
3. 构建 iOS .app + 未签名 IPA
4. 创建 GitHub Release 并上传构建产物

## 项目结构

```
lib/
├── main.dart                    # 入口文件
├── database/
│   └── database_helper.dart     # 数据库操作
├── models/
│   └── recording_model.dart     # 录音数据模型
├── pages/
│   ├── home_page.dart           # 首页
│   ├── recordings_page.dart     # 录音列表页
│   └── settings_page.dart       # 设置页
├── services/
│   ├── audio_player_service.dart   # 音频播放服务
│   ├── audio_recorder_service.dart # 音频录制服务
│   ├── monitoring_service.dart     # 后台监测服务
│   └── vad_service.dart            # VAD 人声检测
├── utils/
│   └── app_theme.dart           # 主题配置
└── widgets/
    ├── recording_tile.dart      # 录音列表项
    ├── status_indicator.dart    # 状态指示器
    └── waveform_indicator.dart  # 波形指示器
```

## 权限说明

### Android
- `RECORD_AUDIO` - 录音权限
- `FOREGROUND_SERVICE` - 前台服务权限
- `FOREGROUND_SERVICE_MICROPHONE` - 麦克风前台服务
- `POST_NOTIFICATIONS` - 通知权限 (Android 13+)

### iOS
- `NSMicrophoneUsageDescription` - 麦克风使用权限
- `UIBackgroundModes` (audio) - 后台音频模式

## 许可

MIT License