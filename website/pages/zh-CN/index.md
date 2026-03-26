---
sidebar: false
outline: [2, 3]
title: 中文导航
---

# 中文导航

这个站点当前以中文教程为主。为了避免在首页直接堆满章节链接，这里把入口拆成三类：开始学习、练习答案、内容开发。

## 开始学习

<div class="landing-grid">
  <a class="landing-card" href="/zh-CN/chapters/01-environment-setup">
    <strong>从第一章开始</strong>
    <span>适合第一次系统学习 Swift，从环境搭建和 Xcode 基础开始。</span>
  </a>
  <a class="landing-card" href="/zh-CN/chapters/">
    <strong>章节总览</strong>
    <span>先看全部章节，再决定顺序阅读还是按主题跳读。</span>
  </a>
  <a class="landing-card" href="/zh-CN/answers/">
    <strong>练习答案总览</strong>
    <span>完成练习后从这里进入答案页，不必手动找 Markdown 文件。</span>
  </a>
</div>

## 当前包含哪些内容

- 中文教程正文
- 中文练习答案
- 教程配图资源

## 内容开发

如果你要修改教程内容，并实时预览网页效果：

```bash
cd website
npm install
npm run docs:dev
```

开发服务器会直接读取仓库中的原始内容目录：

- `docs/zh-CN/chapters/`
- `exercises/zh-CN/answers/`
- `assets/`

这意味着你修改 Markdown 后，可以在浏览器中立即看到更新结果。
