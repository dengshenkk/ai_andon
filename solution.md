# Solution

## 产物
- `AIAndon.app` - macOS 安灯应用
- `AI-Andon.dmg` - 安装包 (58KB)

## 架构
| 文件 | 职责 |
|------|------|
| `SessionMonitor.swift` | 读取 `~/.claude/sessions/*.json`，解析 status 字段，返回 AndonState |
| `StatusLightView.swift` | 绘制三色灯（绿/黄/红），支持闪烁动画 |
| `StatusLightWindow.swift` | 无边框浮动窗口，可拖拽，置顶显示 |
| `MenuBarIcon.swift` | 菜单栏彩色圆点图标，同步闪烁 |
| `AppDelegate.swift` | 协调器，60fps 定时器驱动状态刷新 |

## 状态映射
| Claude 状态 | 窗口灯 | 菜单栏 |
|-------------|--------|--------|
| busy | 🟢 绿灯常亮 | 绿色圆点 |
| idle | 🟡 黄灯闪烁(0.5s) | 黄灰交替 |
| inactive | 🔴 红灯闪烁(0.5s) | 红灰交替 |
| 无 session | ⚫ 全灰 | 灰色圆点 |

## 安装
双击 `AI-Andon.dmg`，将 `AIAndon.app` 拖入 Applications 文件夹即可。
