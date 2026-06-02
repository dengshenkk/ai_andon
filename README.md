# AI Andon

macOS 菜单栏安灯应用，实时监控 Claude Code 会话状态。

## 功能

- **多会话独立监控**：每个 Claude Code 会话对应一个独立指示灯
- **菜单栏状态**：聚合显示所有会话状态
- **浮动窗口**：始终置顶的半透明浮动面板，可拖拽
- **点击聚焦**：点击指示灯直接聚焦对应终端窗口
- **自动启动**：支持开机自启
- **方向切换**：支持垂直/水平布局

## 状态说明

| 会话状态 | 灯光颜色 | 菜单栏图标 |
|---------|---------|-----------|
| 执行中 (busy) | 绿色常亮 | 绿色圆点 |
| 空闲 (idle) | 黄色闪烁 | 黄灰交替 |
| 断开 (inactive) | 红色闪烁 | 红灰交替 |

菜单栏逻辑：任一会话空闲 → 闪黄灯；全部执行中 → 绿灯。

## 安装

1. 下载 `AI-Andon.dmg`
2. 挂载后拖拽到 Applications
3. 首次打开需在系统设置中允许

## 从源码构建

```bash
swiftc \
  Sources/AIAndon/main.swift \
  Sources/AIAndon/AppDelegate.swift \
  Sources/AIAndon/SessionMonitor.swift \
  Sources/AIAndon/StatusLightView.swift \
  Sources/AIAndon/StatusLightWindow.swift \
  Sources/AIAndon/MenuBarIcon.swift \
  -o AIAndon \
  -framework AppKit \
  -framework ServiceManagement
```

## 系统要求

- macOS 12.0+
