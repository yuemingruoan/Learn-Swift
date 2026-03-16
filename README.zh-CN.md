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
