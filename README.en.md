# Learn-Swift

A Swift tutorial repository for learners.

This repository is designed for reading tutorials, exploring example projects, and practicing with exercises while learning Swift.

## Who This Repository Is For

- Readers who want to learn Swift systematically
- Beginners who prefer learning through runnable Xcode demos
- Users who want tutorials, demos, and exercises in one place

## What You Can Find Here

- Tutorial content
- Runnable Xcode demo projects
- Language-specific exercises and reference answers
- Images and diagrams used by the tutorial

## How To Use This Repository

1. Open the tutorial content in your preferred language
2. Run the matching Xcode demo projects as you read
3. Finish the exercises before checking the reference answers

## Repository Structure

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

## Directory Guide

- `docs/`: Tutorial content. `zh-CN/` and `en/` contain the Chinese and English versions.
- `docs/*/chapters/`: Main tutorial chapters.
- `docs/*/appendix/`: Appendix content such as extra notes, glossary items, or references.
- `demos/`: Demo project directory.
- `demos/projects/`: Independent Xcode demo projects.
- `demos/shared/`: Shared code or resources reused by multiple demos.
- `exercises/`: Exercise content grouped by language.
- `exercises/*/answers/`: Reference answers for each language.
- `assets/`: Images and diagrams used by the tutorial.
- `assets/shared/`: Shared assets.
- `assets/zh-CN/` and `assets/en/`: Language-specific assets.

## Website Preview And Development

This repository includes a VitePress website project in [website](./website).
That directory is used to keep the website code and configuration out of the repository root.

### If You Are Developing Content

If you are writing tutorial content or adjusting the website itself, use the VitePress dev server for realtime preview with hot reload:

```bash
cd website
npm install
npm run docs:dev
```

Then open the local address shown by the VitePress dev server in your browser.

During development, the website reads the original source content directly instead of maintaining duplicated copies:

- `docs/zh-CN/chapters/`
- `exercises/zh-CN/answers/`
- `assets/`

That lets you edit the tutorial Markdown and immediately preview the result in the browser.

### If You Are Deploying The Website

If you want to deploy the site to GitHub Pages, your own server, or let other users run it locally, build the static site first:

```bash
cd website
npm install
npm run docs:build
```

The generated static output is written to:

- `website/dist/`

If you want to verify the built result locally before deployment, run:

```bash
cd website
npm run docs:preview
```

That starts a local static preview server so you can inspect the deployed version of the site.

You can then deploy it in several ways:

- GitHub Pages: use the repository GitHub Actions workflow to build and publish `website/dist/`
- Self-hosted server: serve `website/dist/` with Nginx, Caddy, or any other static file server
- Local user deployment: run `website/dist/` with any static server, for example `npx serve website/dist`

If you want to serve the built static files locally yourself, you can also run:

```bash
npx serve website/dist
```

### If You Are A Learner

If you only want to study the tutorial in a browser and do not need to contribute content, use a deployed version of the static website.

Learners do not need to:

- install a Markdown renderer
- understand the repository structure
- run VitePress development commands

They only need to open the deployed site URL and read the chapters, answers, and images in the browser.

If you already cloned the repository and only want to run the website locally for reading, use:

```bash
cd website
npm install
npm run docs:build
npm run docs:preview
```

Then open the local address shown in the terminal and start reading in the browser.
