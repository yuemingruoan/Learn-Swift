# Learn-Swift Website

这个目录承载教程网站工程，避免把前端脚手架和构建配置堆到仓库根目录。
开发时直接读取仓库根目录下的原始 Markdown，因此能保留 Vite / VitePress 的热更新体验。

## 常用命令

```bash
npm install
npm run docs:dev
npm run docs:build
```

## 开发体验

- 在仓库根目录的 `docs/`、`exercises/` 中修改 Markdown
- VitePress 开发服务器会直接感知这些文件变化并刷新页面
- 不需要额外的“复制内容后再预览”步骤

## 目录说明

- `.vitepress/`：VitePress 配置与主题
- `pages/`：站点专用页面，例如首页和中文站入口页

## 内容来源

网站不会复制原始教程内容，源文件仍然维护在仓库根目录：

- `docs/zh-CN/chapters/`
- `exercises/zh-CN/answers/`
- `assets/`
