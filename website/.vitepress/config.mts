import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vitepress";

const currentFile = fileURLToPath(import.meta.url);
const currentDir = path.dirname(currentFile);
const websiteRoot = path.resolve(currentDir, "..");
const repoRoot = path.resolve(websiteRoot, "..");
const websiteNodeModules = path.join(websiteRoot, "node_modules");
const generatedDir = path.join(currentDir, "generated");
const generatedSidebarDataPath = path.join(generatedDir, "sidebar-data.mjs");
const defaultThemeSidebarComposablePath = path.join(
  websiteNodeModules,
  "vitepress",
  "dist",
  "client",
  "theme-default",
  "composables",
  "sidebar.js",
);
const defaultThemePrevNextComposablePath = path.join(
  websiteNodeModules,
  "vitepress",
  "dist",
  "client",
  "theme-default",
  "composables",
  "prev-next.js",
);
const customSidebarComposablePath = path.join(
  websiteRoot,
  ".vitepress",
  "theme",
  "composables",
  "sidebar.ts",
);
const customPrevNextComposablePath = path.join(
  websiteRoot,
  ".vitepress",
  "theme",
  "composables",
  "prev-next.ts",
);

const chaptersDir = path.join(repoRoot, "docs", "zh-CN", "chapters");
const answersDir = path.join(repoRoot, "exercises", "zh-CN", "answers");
const repositoryWebBase =
  process.env.WEBSITE_REPO_URL ?? "https://github.com/yuemingruoan/Learn-Swift";
const repositoryBranch = process.env.WEBSITE_REPO_BRANCH ?? "main";

const filenameCollator = new Intl.Collator("zh-CN", {
  numeric: true,
  sensitivity: "base",
});

function getMarkdownFiles(targetDir: string) {
  if (!existsSync(targetDir)) {
    return [];
  }

  return readdirSync(targetDir)
    .filter((name) => name.endsWith(".md"))
    .sort((left, right) => filenameCollator.compare(left, right));
}

function getTitleFromMarkdown(filePath: string, fallback: string) {
  const content = readFileSync(filePath, "utf8");
  const titleLine = content
    .split(/\r?\n/)
    .find((line) => line.startsWith("# "));

  return titleLine ? titleLine.slice(2).trim() : fallback;
}

function toSidebarItems(targetDir: string, basePath: string) {
  return getMarkdownFiles(targetDir).map((filename) => {
    const absolutePath = path.join(targetDir, filename);
    const title = getTitleFromMarkdown(
      absolutePath,
      filename.replace(/\.md$/, ""),
    );

    return {
      text: title,
      link: `${basePath}${filename.replace(/\.md$/, "")}`,
    };
  });
}

function createSidebarConfig() {
  return {
    "/zh-CN/chapters/": [
      {
        text: "教程章节",
        items: [
          {
            text: "章节总览",
            link: "/zh-CN/chapters/",
          },
          ...toSidebarItems(chaptersDir, "/zh-CN/chapters/"),
        ],
      },
    ],
    "/zh-CN/answers/": [
      {
        text: "练习答案",
        items: [
          {
            text: "答案总览",
            link: "/zh-CN/answers/",
          },
          ...toSidebarItems(answersDir, "/zh-CN/answers/"),
        ],
      },
    ],
    "/zh-CN/": [
      {
        text: "中文内容",
        items: [
          {
            text: "中文导航",
            link: "/zh-CN/",
          },
          {
            text: "章节总览",
            link: "/zh-CN/chapters/",
          },
          {
            text: "练习答案总览",
            link: "/zh-CN/answers/",
          },
        ],
      },
    ],
  };
}

function generateSidebarModuleSource() {
  return `export const sidebarConfig = ${JSON.stringify(createSidebarConfig(), null, 2)};\n`;
}

function writeGeneratedSidebarData() {
  mkdirSync(generatedDir, { recursive: true });
  const nextContent = generateSidebarModuleSource();
  const currentContent = existsSync(generatedSidebarDataPath)
    ? readFileSync(generatedSidebarDataPath, "utf8")
    : null;

  if (currentContent !== nextContent) {
    writeFileSync(generatedSidebarDataPath, nextContent, "utf8");
  }
}

function isSidebarSourceFile(filePath: string) {
  const normalizedFilePath = path.resolve(filePath);
  const chaptersPrefix = `${chaptersDir}${path.sep}`;
  const answersPrefix = `${answersDir}${path.sep}`;

  return (
    normalizedFilePath.endsWith(".md") &&
    (normalizedFilePath.startsWith(chaptersPrefix) ||
      normalizedFilePath.startsWith(answersPrefix))
  );
}

function syncSidebarDataPlugin() {
  return {
    name: "learn-swift-sync-sidebar-data",
    configureServer(server: any) {
      const syncSidebarData = (filePath: string) => {
        if (!isSidebarSourceFile(filePath)) {
          return;
        }

        writeGeneratedSidebarData();
      };

      server.watcher.on("add", syncSidebarData);
      server.watcher.on("unlink", syncSidebarData);
      server.watcher.on("change", syncSidebarData);
    },
    buildStart() {
      writeGeneratedSidebarData();
    },
  };
}

writeGeneratedSidebarData();

function inferBase() {
  const explicitBase = process.env.WEBSITE_BASE?.trim();
  if (explicitBase) {
    return explicitBase;
  }

  const repository = process.env.GITHUB_REPOSITORY;
  if (!repository) {
    return "/";
  }

  const repoName = repository.split("/")[1] ?? "";
  return repoName.endsWith(".github.io") ? "/" : `/${repoName}/`;
}

function normalizeTarget(rawTarget: string) {
  return rawTarget.replace(/\\/g, "/").replace(/^\.\//, "");
}

function extractRepoRelativePath(target: string) {
  const markers = [
    "docs/zh-CN/chapters/",
    "exercises/zh-CN/answers/",
    "demos/",
    "assets/",
    "templates/",
  ];

  for (const marker of markers) {
    const index = target.indexOf(marker);
    if (index >= 0) {
      return target.slice(index);
    }
  }

  return null;
}

function toRepositoryUrl(repoRelativePath: string) {
  const normalizedPath = repoRelativePath.replace(/^\/+/, "");
  const isTreeTarget =
    normalizedPath.endsWith(".xcodeproj") ||
    path.posix.extname(normalizedPath) === "";
  const mode = isTreeTarget ? "tree" : "blob";

  return `${repositoryWebBase}/${mode}/${repositoryBranch}/${normalizedPath}`;
}

function transformMarkdownTarget(rawTarget: string) {
  const target = normalizeTarget(rawTarget);
  const repoRootPosix = repoRoot.replace(/\\/g, "/");
  const embeddedRepoPath = extractRepoRelativePath(target);

  if (
    target.startsWith("http://") ||
    target.startsWith("https://") ||
    target.startsWith("mailto:") ||
    target.startsWith("#")
  ) {
    return target;
  }

  if (target.startsWith("../../../exercises/zh-CN/answers/")) {
    return target.replace("../../../exercises/zh-CN/answers/", "../answers/");
  }

  if (target.startsWith("../../../docs/zh-CN/chapters/")) {
    return target.replace("../../../docs/zh-CN/chapters/", "../chapters/");
  }

  if (target.startsWith("../../../demos/")) {
    return toRepositoryUrl(target.replace("../../../", ""));
  }

  if (embeddedRepoPath?.startsWith("docs/zh-CN/chapters/")) {
    return embeddedRepoPath.replace("docs/zh-CN/chapters/", "../chapters/");
  }

  if (
    embeddedRepoPath?.startsWith("exercises/zh-CN/answers/") &&
    embeddedRepoPath.endsWith(".md")
  ) {
    return embeddedRepoPath.replace("exercises/zh-CN/answers/", "../answers/");
  }

  if (embeddedRepoPath) {
    return toRepositoryUrl(embeddedRepoPath);
  }

  if (target.startsWith(`${repoRootPosix}/`)) {
    return toRepositoryUrl(target.slice(repoRootPosix.length + 1));
  }

  return target;
}

function rewriteMarkdownLinks(content: string) {
  return content.replace(/\[([^\]]+)\]\(([^)]+)\)/g, (_, label, rawTarget) => {
    return `[${label}](${transformMarkdownTarget(rawTarget)})`;
  });
}

function rewriteMarkdownLinksPlugin() {
  return {
    name: "learn-swift-rewrite-markdown-links",
    enforce: "pre" as const,
    transform(code: string, id: string) {
      if (!id.endsWith(".md")) {
        return null;
      }

      const normalizedId = id.replace(/\\/g, "/");
      const rootDocsPrefix = `${repoRoot.replace(/\\/g, "/")}/`;

      if (!normalizedId.startsWith(rootDocsPrefix)) {
        return null;
      }

      return rewriteMarkdownLinks(code);
    },
  };
}

export default defineConfig({
  srcDir: "..",
  srcExclude: [
    "README*.md",
    "docs/en/**",
    "docs/zh-CN/appendix/**",
    "exercises/en/**",
    "exercises/zh-CN/projects/**",
    "assets/**",
    "demos/**",
    "templates/**",
    "website/README.md",
    "website/docs/**",
    "website/dist/**",
    "website/node_modules/**",
    "website/package-lock.json",
    "website/package.json",
    "website/scripts/**",
    "**/.DS_Store",
    "**/.gitkeep",
  ],
  rewrites: {
    "website/pages/index.md": "index.md",
    "website/pages/zh-CN/index.md": "zh-CN/index.md",
    "website/pages/zh-CN/chapters/index.md": "zh-CN/chapters/index.md",
    "website/pages/zh-CN/answers/index.md": "zh-CN/answers/index.md",
    "docs/zh-CN/chapters/:page*": "zh-CN/chapters/:page*",
    "exercises/zh-CN/answers/:page*": "zh-CN/answers/:page*",
  },
  title: "Learn Swift",
  description: "面向学习者的 Swift 教程网站",
  lang: "zh-CN",
  base: inferBase(),
  cleanUrls: true,
  lastUpdated: true,
  outDir: "./dist",
  vite: {
    // `srcDir` points at the repository root, so we need to pin the public
    // asset directory back to `website/public`.
    publicDir: path.join(websiteRoot, "public"),
    plugins: [rewriteMarkdownLinksPlugin(), syncSidebarDataPlugin()],
    resolve: {
      alias: [
        {
          find: /^vue$/,
          replacement: path.join(
            websiteNodeModules,
            "vue",
            "dist",
            "vue.runtime.esm-bundler.js",
          ),
        },
        {
          find: /^vue\/server-renderer$/,
          replacement: path.join(
            websiteNodeModules,
            "vue",
            "server-renderer",
            "index.js",
          ),
        },
        {
          find: defaultThemeSidebarComposablePath,
          replacement: customSidebarComposablePath,
        },
        {
          find: defaultThemePrevNextComposablePath,
          replacement: customPrevNextComposablePath,
        },
      ],
    },
  },
  themeConfig: {
    nav: [
      { text: "首页", link: "/" },
      {
        text: "教程",
        link: "/zh-CN/chapters/01-environment-setup",
      },
      {
        text: "参考答案",
        link: "/zh-CN/answers/08-optional-basics",
      },
    ],
    socialLinks: [{ icon: "github", link: repositoryWebBase }],
    sidebar: createSidebarConfig(),
    search: {
      provider: "local",
    },
    outline: {
      level: [2, 3],
      label: "本页目录",
    },
    docFooter: {
      prev: "上一页",
      next: "下一页",
    },
    editLink: {
      pattern: `${repositoryWebBase}/edit/${repositoryBranch}/:path`,
      text: "在 GitHub 上编辑此页",
    },
    returnToTopLabel: "回到顶部",
    sidebarMenuLabel: "菜单",
    darkModeSwitchLabel: "主题",
    lightModeSwitchTitle: "切换到浅色模式",
    darkModeSwitchTitle: "切换到深色模式",
    lastUpdated: {
      text: "最后更新于",
      formatOptions: {
        dateStyle: "short",
        timeStyle: "short",
      },
    },
    footer: {
      message: "Learn Swift",
      copyright: "Built with VitePress",
    },
  },
});
