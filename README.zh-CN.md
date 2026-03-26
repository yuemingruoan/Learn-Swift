# Learn-Swift

一个面向学习者的 Swift 教程仓库。

你可以在这里阅读教程、查看示例工程，并配合练习逐步学习 Swift。

## 这个仓库适合谁

- 想系统学习 Swift 基础语法和常用特性的读者
- 想通过可运行示例理解 Swift 用法的初学者
- 希望结合教程、示例和练习进行学习的用户

## 你可以在这里找到什么

- 教程正文
- 可运行的 Xcode 示例工程
- 对应语言的练习题与参考答案
- 教程配套的图片和图表资源

## 如何使用这个仓库

1. 进入你需要的语言目录阅读教程内容
2. 根据章节打开对应的 Xcode 示例工程
3. 完成练习后再查看参考答案

## 仓库结构

```text
Learn-Swift/
├─ docs/
│  ├─ zh-CN/
│  │  ├─ chapters/
│  │  └─ appendix/
│  └─ en/
│     ├─ chapters/
│     └─ appendix/
├─ demos/
│  ├─ projects/
│  └─ shared/
├─ exercises/
│  ├─ zh-CN/
│  │  └─ answers/
│  └─ en/
│     └─ answers/
├─ assets/
│  ├─ shared/
│  ├─ zh-CN/
│  └─ en/
├─ templates/
│  └─ xcode-demo-template/
└─ .github/workflows/
```

## 目录说明

- `docs/`：教程正文。`zh-CN/` 和 `en/` 分别对应中文与英文内容。
- `docs/*/chapters/`：正式章节内容。
- `docs/*/appendix/`：附录内容，例如补充说明、术语或参考资料。
- `demos/`：示例工程目录。
- `demos/projects/`：独立的 Xcode 示例项目。
- `demos/shared/`：多个示例之间可以复用的代码或资源。
- `exercises/`：练习目录，按语言拆分。
- `exercises/*/answers/`：对应语言的参考答案。
- `assets/`：教程中用到的图片和图表资源。
- `assets/shared/`：通用资源。
- `assets/zh-CN/` 和 `assets/en/`：语言相关资源。

## 网站预览与开发

仓库中包含一个基于 VitePress 的网站工程，目录位于 [website](./website)。
这个目录专门用于放站点配置和前端代码，不会把这些文件堆到仓库根目录。

### 如果你是内容开发者

如果你要编写教程内容、调整页面效果，推荐使用 VitePress 开发服务器进行实时预览：

```bash
cd website
npm install
npm run docs:dev
```

然后在浏览器中打开终端里显示的本地地址。

网站开发时会直接读取下面这些原始内容目录，而不是复制一份单独内容：

- `docs/zh-CN/chapters/`
- `exercises/zh-CN/answers/`
- `assets/`

这意味着你修改教程 Markdown 后，可以在浏览器里立即看到更新效果。

### 如果你是部署者

如果你要把网站部署到 GitHub Pages、自己的服务器，或者交给其他用户本地运行，请先构建静态站点：

```bash
cd website
npm install
npm run docs:build
```

构建完成后，生成的静态文件位于：

- `website/dist/`

如果你想先在本机确认构建结果，可以继续执行：

```bash
cd website
npm run docs:preview
```

这会启动一个本地静态预览服务，让你以“部署后”的方式检查网站。

你可以按下面几种方式部署：

- GitHub Pages：使用仓库中的 GitHub Actions 工作流构建并发布 `website/dist/`
- 自己的服务器：把 `website/dist/` 部署到 Nginx、Caddy 或其他静态文件服务器
- 用户本地部署：把 `website/dist/` 交给任意静态服务器运行，例如 `npx serve website/dist`

如果你想在本地直接把构建后的静态文件跑起来，也可以执行：

```bash
npx serve website/dist
```

### 如果你是学习者

如果你只是想在浏览器中阅读教程，而不参与开发，可以直接使用已经部署好的静态网站。

这类用户不需要：

- 安装 Markdown 渲染器
- 了解仓库目录结构
- 运行 VitePress 开发命令

只需要打开部署后的网页地址，即可按章节阅读教程、查看练习答案和图片资源。

如果你已经把仓库拉到本地，但只想把网站跑起来阅读，不需要热更新开发，可以直接执行：

```bash
cd website
npm install
npm run docs:build
npm run docs:preview
```

执行后，在浏览器打开终端显示的地址即可开始阅读。
