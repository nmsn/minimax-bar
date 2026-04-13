# minimax-bar Sparkle 更新集成文档

## 密钥信息

- **EdDSA 公钥**: `8n6qpNCw5nnChaXomz88SKWPaYUXfvSo8P9fMpq/6hs=`
  - 此公钥可公开（无安全风险），用于验证更新签名的合法性
- **私钥位置**: Mac Keychain 中（与公钥配对）
- **警告**: 私钥一旦删除将无法解密已有更新，务必妥善保管

## 发布更新步骤

### 1. 构建 Release 版本

```bash
xcodebuild -project minimax-bar.xcodeproj -scheme minimax-bar -configuration Release build
```

### 2. 打包为 .dmg 格式

使用 `Disk Utility` 或命令行创建 .dmg：
```bash
hdiutil create -volname minimax-bar -srcfolder build/Release/minimax-bar.app -ov -format UDZO minimax-bar.dmg
```

### 3. 对 .dmg 进行签名（可选但推荐）

使用 Developer ID 签名：
```bash
codesign --force --sign "Developer ID Application: YOUR_NAME" --deep minimax-bar.dmg
```

### 4. 创建 GitHub Release

1. 访问 GitHub 仓库的 Releases 页面
2. 点击 "Draft a new release"
3. 填写版本号（如 `v1.0.1`）
4. 上传 `.dmg` 文件
5. 发布 Release

### 5. 配置 Appcast（首次）

创建 `appcast.xml` 在 GitHub Pages 或其他托管地址：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>minimax-bar Updates</title>
    <link>https://你的用户名.github.io/minimax-bar/appcast.xml</link>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:releaseNotesLink>https://你的用户名.github.io/minimax-bar/notes.html</sparkle:releaseNotesLink>
      <pubDate>Mon, 13 Apr 2026 12:00:00 +0800</pubDate>
      <enclosure url="https://github.com/你的用户名/minimax-bar/releases/download/v1.0.1/minimax-bar.dmg" sparkle:version="1.0.1" length="1234567" type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

### 6. 在 project.yml 中配置 Appcast URL

```yaml
settings:
  base:
    SUAppcastURL: "https://你的用户名.github.io/minimax-bar/appcast.xml"
```
```

## Sparkle 密钥生成（如果需要重新生成）

```bash
# 路径可能在 DerivedData 中
~/Library/Developer/Xcode/DerivedData/minimax-bar-*/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
```

## 相关文件

- `Services/UpdateService.swift` - Sparkle 更新服务
- `Views/PopoverContentView.swift` - UI 中的"检查更新"按钮
