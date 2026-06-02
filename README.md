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
| iOS | `.ipa` | 未签名 iOS 应用（需个人签名） |
| iOS | `framework/` | iOS Framework 格式（高级用户） |

### 云端自动构建说明（🎉 无需本地环境！）

本项目使用 **GitHub Actions** 实现全自动云端打包，推送到 `main` 分支后会自动构建并发布 Release。

#### 构建产物
- **Android APK**: 可直接安装的安装包
- **Android AAB**: Google Play 发布用
- **iOS IPA**: 未签名 IPA 文件，可通过爱思助手等工具签名安装
- **iOS Framework**: Framework 格式，签名后可用

#### 查看构建状态
1. 点击上方 badge 查看 Actions: [![Build and Release](https://github.com/Ht13142003/sleep-talk/actions/workflows/ci.yml/badge.svg)](https://github.com/Ht13142003/sleep-talk/actions/workflows/ci.yml)
2. 点击 "Actions" 标签页查看构建历史
3. 点击具体构建查看构建日志

#### 手动触发构建
1. 进入项目仓库，点击 "Actions" 标签页
2. 选择 "Build and Release" 工作流
3. 点击 "Run workflow"
4. 选择分支，点击 "Run workflow"

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
3. 构建 iOS IPA + Framework
4. 创建 GitHub Release 并上传构建产物

## iOS 安装指南（无需 Mac！）

### 方法一：爱思助手（推荐，最简单）

#### 步骤 1：下载 IPA 文件
1. 进入项目的 [Releases](https://github.com/Ht13142003/sleep-talk/releases) 页面
2. 下载带有 `.ipa` 文件的版本
3. 解压下载的压缩包（如果是 .zip 格式）

#### 步骤 2：使用爱思助手签名安装
1. 在电脑上安装 [爱思助手](https://www.i4.cn/)
2. 用数据线连接 iPhone 到电脑
3. 打开爱思助手，等待识别到设备
4. 点击左侧菜单的"应用游戏"
5. 点击"导入应用"，选择下载的 `.ipa` 文件
6. 选择签名方式：
   - **免费签名（推荐）**: 使用你的 Apple ID 签名（需要关闭双重认证）
   - **已购签名**: 如果你有付费开发者账号
7. 点击"开始签名"
8. 签名完成后，点击"安装"

#### 步骤 3：在 iPhone 上信任证书
1. 安装完成后，打开 APP，会提示"不受信任的企业级开发者"
2. 进入 iPhone **设置** → **通用** → **VPN 与设备管理**
3. 找到你的 Apple ID 邮箱，点击信任
4. 返回主屏幕，打开 APP
5. 首次打开时会请求麦克风权限，点击"允许"

### 方法二：TrollStore（永久安装，无需签名）

#### 前提条件
- iPhone 已越狱并安装 TrollStore
- 如果未安装 TrollStore，需要先通过其他方式安装一次 APP

#### 步骤
1. 从 Releases 下载 `.ipa` 文件
2. 使用文件 App 或 AirDrop 将 IPA 发送到 iPhone
3. 点击 IPA 文件，选择"用 TrollStore 打开"
4. APP 会自动安装并永久保存

### 方法三：Mac + Xcode（传统方式）

```bash
# 1. 克隆项目
git clone https://github.com/Ht13142003/sleep-talk.git
cd sleep-talk

# 2. 获取依赖
flutter pub get

# 3. 打开 Xcode 项目
open ios/Runner.xcworkspace

# 4. 在 Xcode 中：
#    - Signing & Capabilities > Team > 选择你的 Apple ID（免费即可）
#    - Bundle ID 改成唯一的

# 5. 直接运行
flutter run --release
```

### 常见问题

#### Q: 为什么 iOS APP 需要签名？
A: Apple 要求所有安装的 APP 必须有有效的签名。免费 Apple ID 签名的 APP 有效期为 7 天，过期后需要重新签名。

#### Q: 爱思助手签名失败怎么办？
A: 
- 确保关闭了 Apple ID 的双重认证
- 尝试使用不同的 Apple ID
- 检查网络连接
- 可能是爱思助手服务器问题，稍后再试

#### Q: 签名后 APP 无法安装？
A: 
- 检查 iPhone 存储空间是否充足
- 尝试重启 iPhone
- 确保设备管理中已信任该证书

#### Q: APP 打开后闪退？
A: 
- 检查是否已信任开发者证书
- 确认麦克风权限已开启
- 查看 Xcode 控制台的具体错误信息

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