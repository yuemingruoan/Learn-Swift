import http from "node:http";

const port = Number(process.env.PORT ?? 3456);
const host = process.env.HOST ?? "127.0.0.1";

const demoUser = {
  id: 1,
  username: "swift-demo",
  name: "Swift Learner",
  role: "student",
  preferredTrack: "networking"
};

const demoAccessToken = "swift-demo-token";
const demoSessionID = "swift-demo-session";

const todos = [
  {
    userId: 1,
    id: 1,
    title: "复习 URLSession GET 基本链路",
    completed: false
  },
  {
    userId: 1,
    id: 2,
    title: "检查 HTTP 状态码后再解码",
    completed: true
  },
  {
    userId: 1,
    id: 3,
    title: "把学习记录通过 POST 提交给服务端",
    completed: false
  },
  {
    userId: 2,
    id: 4,
    title: "区分网络错误和 JSON 解码错误",
    completed: false
  },
  {
    userId: 2,
    id: 5,
    title: "把鉴权放进请求构造阶段",
    completed: true
  }
];

const learningResources = [
  {
    id: 101,
    title: "Endpoint 建模实战",
    category: "networking",
    level: "beginner",
    durationMinutes: 18,
    publishedAt: "2026-03-01",
    downloadSlug: "endpoint-modeling-checklist"
  },
  {
    id: 102,
    title: "Authorization Header 清单",
    category: "networking",
    level: "beginner",
    durationMinutes: 12,
    publishedAt: "2026-03-05",
    downloadSlug: "authorization-header-checklist"
  },
  {
    id: 103,
    title: "分页响应与 DTO 设计",
    category: "networking",
    level: "intermediate",
    durationMinutes: 24,
    publishedAt: "2026-03-08",
    downloadSlug: "pagination-dto-notes"
  },
  {
    id: 104,
    title: "Codable 缓存边界",
    category: "persistence",
    level: "intermediate",
    durationMinutes: 20,
    publishedAt: "2026-03-11",
    downloadSlug: "codable-cache-boundaries"
  },
  {
    id: 105,
    title: "SwiftData 最小 CRUD",
    category: "persistence",
    level: "intermediate",
    durationMinutes: 22,
    publishedAt: "2026-03-14",
    downloadSlug: "swiftdata-crud-cheatsheet"
  },
  {
    id: 106,
    title: "协议抽象与依赖注入",
    category: "architecture",
    level: "advanced",
    durationMinutes: 28,
    publishedAt: "2026-03-16",
    downloadSlug: "dependency-injection-workbook"
  },
  {
    id: 107,
    title: "下载接口与文件落盘",
    category: "networking",
    level: "intermediate",
    durationMinutes: 16,
    publishedAt: "2026-03-20",
    downloadSlug: "download-to-disk-guide"
  },
  {
    id: 108,
    title: "查询参数的职责边界",
    category: "networking",
    level: "beginner",
    durationMinutes: 14,
    publishedAt: "2026-03-24",
    downloadSlug: "query-items-reference"
  }
];

let nextStudyRecordID = 101;
const studyRecords = [];

function buildCommonHeaders(extraHeaders = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, Cookie",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    ...extraHeaders
  };
}

function sendJSON(response, statusCode, payload, extraHeaders = {}) {
  response.writeHead(statusCode, buildCommonHeaders({
    "Content-Type": "application/json; charset=utf-8",
    ...extraHeaders
  }));
  response.end(JSON.stringify(payload, null, 2));
}

function sendText(response, statusCode, text, contentType = "text/plain; charset=utf-8", extraHeaders = {}) {
  response.writeHead(statusCode, buildCommonHeaders({
    "Content-Type": contentType,
    ...extraHeaders
  }));
  response.end(text);
}

function sendRaw(response, statusCode, body, contentType, extraHeaders = {}) {
  response.writeHead(statusCode, buildCommonHeaders({
    "Content-Type": contentType,
    ...extraHeaders
  }));
  response.end(body);
}

function sendHTML(response, statusCode, html) {
  sendText(response, statusCode, html, "text/html; charset=utf-8");
}

function makeHealthPayload() {
  return {
    status: "ok",
    service: "learn-swift-teaching-api",
    message: "本地教学 API 已启动，可以继续后续章节。"
  };
}

function makeHealthPage() {
  return `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Learn Swift Teaching API Health</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #f4f1ea;
      --panel: #fffaf2;
      --text: #20201d;
      --muted: #6a675f;
      --ok: #1f7a46;
      --line: #d8cfbf;
      --accent: #c46f2d;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: "SF Pro Text", "PingFang SC", "Helvetica Neue", sans-serif;
      background:
        radial-gradient(circle at top left, #fff6df 0%, transparent 38%),
        linear-gradient(135deg, #f7f2e8 0%, var(--bg) 100%);
      color: var(--text);
      display: grid;
      place-items: center;
      padding: 24px;
    }
    .card {
      width: min(720px, 100%);
      background: rgba(255, 250, 242, 0.92);
      border: 1px solid var(--line);
      border-radius: 24px;
      padding: 28px;
      box-shadow: 0 18px 60px rgba(76, 61, 38, 0.12);
      backdrop-filter: blur(10px);
    }
    .eyebrow {
      color: var(--accent);
      font-size: 13px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      margin: 0 0 12px;
    }
    h1 {
      margin: 0 0 12px;
      font-size: clamp(28px, 5vw, 42px);
      line-height: 1.1;
    }
    p {
      margin: 0;
      color: var(--muted);
      line-height: 1.7;
      font-size: 16px;
    }
    .status {
      margin-top: 22px;
      display: inline-flex;
      align-items: center;
      gap: 10px;
      background: #eef8f0;
      color: var(--ok);
      border: 1px solid #cfe7d6;
      padding: 10px 14px;
      border-radius: 999px;
      font-weight: 700;
    }
    .dot {
      width: 10px;
      height: 10px;
      border-radius: 999px;
      background: var(--ok);
      box-shadow: 0 0 0 6px rgba(31, 122, 70, 0.12);
    }
    .meta {
      margin-top: 24px;
      padding-top: 20px;
      border-top: 1px solid var(--line);
      display: grid;
      gap: 8px;
      font-size: 14px;
      color: var(--muted);
    }
    code {
      font-family: "SF Mono", "Menlo", monospace;
      background: #f3eadb;
      border-radius: 8px;
      padding: 2px 6px;
      color: #5b4322;
    }
    a {
      color: var(--accent);
      text-decoration: none;
    }
  </style>
</head>
<body>
  <main class="card">
    <p class="eyebrow">Learn Swift</p>
    <h1>本地教学 API 已成功启动</h1>
    <p>这说明你的本地服务已经可用，可以继续学习后续网络请求章节。39～41 章 demo 需要的鉴权、分页、下载接口也已经包含在当前服务里。</p>
    <div class="status">
      <span class="dot"></span>
      服务状态正常
    </div>
    <section class="meta">
      <div>访问地址：<code>http://${host}:${port}</code></div>
      <div>浏览器健康检查页：<code>/health</code></div>
      <div>命令行 JSON 检查：<a href="/health.json"><code>/health.json</code></a></div>
    </section>
  </main>
</body>
</html>`;
}

function readRequestBody(request) {
  return new Promise((resolve, reject) => {
    let body = "";

    request.setEncoding("utf8");
    request.on("data", chunk => {
      body += chunk;
    });
    request.on("end", () => {
      resolve(body);
    });
    request.on("error", reject);
  });
}

async function readJSONBody(request) {
  const rawBody = await readRequestBody(request);
  return rawBody.length === 0 ? {} : JSON.parse(rawBody);
}

function sleep(ms) {
  return new Promise(resolve => {
    setTimeout(resolve, ms);
  });
}

function findTodoByID(id) {
  return todos.find(todo => todo.id === id) ?? null;
}

function filterTodos(searchParams) {
  let result = [...todos];
  const keyword = searchParams.get("q");
  const completedText = searchParams.get("completed");
  const limitText = searchParams.get("limit");

  if (keyword) {
    const loweredKeyword = keyword.toLowerCase();
    result = result.filter(todo => todo.title.toLowerCase().includes(loweredKeyword));
  }

  if (completedText != null) {
    if (completedText !== "true" && completedText !== "false") {
      return {
        error: {
          statusCode: 400,
          payload: {
            error: "invalid_completed",
            message: "查询参数 completed 只能是 true 或 false。"
          }
        }
      };
    }

    result = result.filter(todo => String(todo.completed) === completedText);
  }

  if (limitText != null) {
    const limit = Number(limitText);
    if (Number.isNaN(limit) || limit <= 0) {
      return {
        error: {
          statusCode: 400,
          payload: {
            error: "invalid_limit",
            message: "查询参数 limit 必须是大于 0 的数字。"
          }
        }
      };
    }

    result = result.slice(0, limit);
  }

  return { value: result };
}

function getBearerToken(request) {
  const authorization = request.headers.authorization ?? "";

  if (!authorization.startsWith("Bearer ")) {
    return null;
  }

  return authorization.slice("Bearer ".length);
}

function hasDemoSessionCookie(request) {
  const cookieHeader = request.headers.cookie ?? "";
  return cookieHeader
    .split(";")
    .map(part => part.trim())
    .some(part => part === `session_id=${demoSessionID}`);
}

function requireBearerAuth(request, response) {
  const token = getBearerToken(request);

  if (token !== demoAccessToken) {
    sendJSON(response, 401, {
      error: "unauthorized",
      message: "当前接口需要有效的 Bearer Token。"
    });
    return false;
  }

  return true;
}

function requireSessionAuth(request, response) {
  if (!hasDemoSessionCookie(request)) {
    sendJSON(response, 401, {
      error: "unauthorized",
      message: "当前接口需要有效的 session cookie。"
    });
    return false;
  }

  return true;
}

function validateJSONContentType(request, response, routeDescription) {
  const contentType = request.headers["content-type"] ?? "";

  if (!contentType.includes("application/json")) {
    sendJSON(response, 415, {
      error: "unsupported_media_type",
      message: `${routeDescription} 只接受 application/json。`
    });
    return false;
  }

  return true;
}

function compareValues(left, right, order) {
  if (left < right) {
    return order === "desc" ? 1 : -1;
  }

  if (left > right) {
    return order === "desc" ? -1 : 1;
  }

  return 0;
}

function listLearningResources(searchParams) {
  const page = Number(searchParams.get("page") ?? "1");
  const limit = Number(searchParams.get("limit") ?? "3");
  const keyword = searchParams.get("q");
  const category = searchParams.get("category");
  const sort = searchParams.get("sort") ?? "publishedAt";
  const order = searchParams.get("order") ?? "desc";

  if (!Number.isInteger(page) || page <= 0) {
    return {
      error: {
        statusCode: 400,
        payload: {
          error: "invalid_page",
          message: "查询参数 page 必须是大于 0 的整数。"
        }
      }
    };
  }

  if (!Number.isInteger(limit) || limit <= 0 || limit > 20) {
    return {
      error: {
        statusCode: 400,
        payload: {
          error: "invalid_limit",
          message: "查询参数 limit 必须是 1 到 20 之间的整数。"
        }
      }
    };
  }

  const allowedCategories = new Set(["networking", "persistence", "architecture"]);
  if (category && !allowedCategories.has(category)) {
    return {
      error: {
        statusCode: 400,
        payload: {
          error: "invalid_category",
          message: "查询参数 category 必须是 networking、persistence、architecture 之一。"
        }
      }
    };
  }

  const allowedSortFields = new Set(["publishedAt", "durationMinutes", "title"]);
  if (!allowedSortFields.has(sort)) {
    return {
      error: {
        statusCode: 400,
        payload: {
          error: "invalid_sort",
          message: "查询参数 sort 必须是 publishedAt、durationMinutes、title 之一。"
        }
      }
    };
  }

  if (order !== "asc" && order !== "desc") {
    return {
      error: {
        statusCode: 400,
        payload: {
          error: "invalid_order",
          message: "查询参数 order 必须是 asc 或 desc。"
        }
      }
    };
  }

  let items = [...learningResources];

  if (keyword) {
    const loweredKeyword = keyword.toLowerCase();
    items = items.filter(resource => resource.title.toLowerCase().includes(loweredKeyword));
  }

  if (category) {
    items = items.filter(resource => resource.category === category);
  }

  items.sort((left, right) => {
    if (sort === "durationMinutes") {
      return compareValues(left.durationMinutes, right.durationMinutes, order);
    }

    if (sort === "title") {
      return compareValues(left.title, right.title, order);
    }

    return compareValues(left.publishedAt, right.publishedAt, order);
  });

  const total = items.length;
  const start = (page - 1) * limit;
  const pagedItems = items.slice(start, start + limit);

  return {
    value: {
      items: pagedItems,
      page,
      limit,
      total,
      hasMore: start + limit < total
    }
  };
}

function makeDownloadBody(resource) {
  return [
    `# ${resource.title}`,
    "",
    `category: ${resource.category}`,
    `level: ${resource.level}`,
    `durationMinutes: ${resource.durationMinutes}`,
    `publishedAt: ${resource.publishedAt}`,
    "",
    "这是一份用于 41 章下载演示的纯文本资料。",
    "你可以观察 Content-Type、Content-Disposition，以及临时文件 URL 的处理方式。"
  ].join("\n");
}

const server = http.createServer(async (request, response) => {
  if (!request.url || !request.method) {
    sendJSON(response, 400, {
      error: "bad_request",
      message: "请求缺少 URL 或 Method。"
    });
    return;
  }

  if (request.method === "OPTIONS") {
    response.writeHead(204, buildCommonHeaders());
    response.end();
    return;
  }

  const url = new URL(request.url, `http://${request.headers.host ?? `${host}:${port}`}`);

  if (request.method === "GET" && url.pathname === "/health") {
    sendHTML(response, 200, makeHealthPage());
    return;
  }

  if (request.method === "GET" && url.pathname === "/health.json") {
    sendJSON(response, 200, makeHealthPayload());
    return;
  }

  if (request.method === "GET" && url.pathname === "/todos") {
    const result = filterTodos(url.searchParams);

    if (result.error) {
      sendJSON(response, result.error.statusCode, result.error.payload);
      return;
    }

    sendJSON(response, 200, result.value);
    return;
  }

  if (request.method === "GET" && /^\/todos\/\d+$/.test(url.pathname)) {
    const id = Number(url.pathname.split("/")[2]);
    const todo = findTodoByID(id);

    if (!todo) {
      sendJSON(response, 404, {
        error: "todo_not_found",
        message: `找不到 id = ${id} 的任务。`
      });
      return;
    }

    sendJSON(response, 200, todo);
    return;
  }

  if (request.method === "POST" && url.pathname === "/study-records") {
    if (!validateJSONContentType(request, response, "POST /study-records")) {
      return;
    }

    try {
      const payload = await readJSONBody(request);
      const { chapter, title, durationMinutes } = payload;

      if (
        typeof chapter !== "number" ||
        typeof title !== "string" ||
        typeof durationMinutes !== "number"
      ) {
        sendJSON(response, 400, {
          error: "invalid_payload",
          message: "请求体必须包含 number chapter、string title、number durationMinutes。"
        });
        return;
      }

      const record = {
        id: nextStudyRecordID,
        chapter,
        title,
        durationMinutes,
        status: "created"
      };

      nextStudyRecordID += 1;
      studyRecords.push(record);
      sendJSON(response, 201, record);
      return;
    } catch {
      sendJSON(response, 400, {
        error: "invalid_json",
        message: "请求体不是合法 JSON。"
      });
      return;
    }
  }

  if (request.method === "GET" && url.pathname === "/diagnostics/server-error") {
    sendJSON(response, 500, {
      error: "server_error",
      message: "这是用于第 39 章错误建模演示的 500 响应。"
    });
    return;
  }

  if (request.method === "GET" && url.pathname === "/diagnostics/bad-todo-json") {
    sendRaw(
      response,
      200,
      JSON.stringify({
        id: "oops",
        title: 123,
        completed: "maybe"
      }, null, 2),
      "application/json; charset=utf-8"
    );
    return;
  }

  if (request.method === "POST" && url.pathname === "/auth/token-login") {
    if (!validateJSONContentType(request, response, "POST /auth/token-login")) {
      return;
    }

    try {
      const payload = await readJSONBody(request);
      const { username, password } = payload;

      if (username !== "swift-demo" || password !== "123456") {
        sendJSON(response, 401, {
          error: "invalid_credentials",
          message: "用户名或密码错误。"
        });
        return;
      }

      sendJSON(response, 200, {
        accessToken: demoAccessToken,
        tokenType: "Bearer",
        expiresIn: 3600,
        user: demoUser
      });
      return;
    } catch {
      sendJSON(response, 400, {
        error: "invalid_json",
        message: "请求体不是合法 JSON。"
      });
      return;
    }
  }

  if (request.method === "GET" && url.pathname === "/auth/token-me") {
    if (!requireBearerAuth(request, response)) {
      return;
    }

    sendJSON(response, 200, demoUser);
    return;
  }

  if (request.method === "GET" && url.pathname === "/auth/admin-report") {
    if (!requireBearerAuth(request, response)) {
      return;
    }

    sendJSON(response, 403, {
      error: "forbidden",
      message: "你已经登录，但当前角色没有访问管理报表的权限。"
    });
    return;
  }

  if (request.method === "POST" && url.pathname === "/auth/session-login") {
    if (!validateJSONContentType(request, response, "POST /auth/session-login")) {
      return;
    }

    try {
      const payload = await readJSONBody(request);
      const { username, password } = payload;

      if (username !== "swift-demo" || password !== "123456") {
        sendJSON(response, 401, {
          error: "invalid_credentials",
          message: "用户名或密码错误。"
        });
        return;
      }

      sendJSON(response, 200, {
        message: "session_created",
        user: demoUser
      }, {
        "Set-Cookie": `session_id=${demoSessionID}; Path=/; HttpOnly`
      });
      return;
    } catch {
      sendJSON(response, 400, {
        error: "invalid_json",
        message: "请求体不是合法 JSON。"
      });
      return;
    }
  }

  if (request.method === "GET" && url.pathname === "/auth/session-me") {
    if (!requireSessionAuth(request, response)) {
      return;
    }

    sendJSON(response, 200, demoUser);
    return;
  }

  if (request.method === "GET" && url.pathname === "/learning-resources") {
    if (!requireBearerAuth(request, response)) {
      return;
    }

    const result = listLearningResources(url.searchParams);

    if (result.error) {
      sendJSON(response, result.error.statusCode, result.error.payload);
      return;
    }

    sendJSON(response, 200, result.value);
    return;
  }

  if (request.method === "GET" && url.pathname === "/slow-summary") {
    if (!requireBearerAuth(request, response)) {
      return;
    }

    const delayMs = Number(url.searchParams.get("delayMs") ?? "1800");
    if (!Number.isInteger(delayMs) || delayMs < 0 || delayMs > 5000) {
      sendJSON(response, 400, {
        error: "invalid_delay",
        message: "查询参数 delayMs 必须是 0 到 5000 之间的整数。"
      });
      return;
    }

    await sleep(delayMs);
    sendJSON(response, 200, {
      title: "慢接口汇总",
      delayMs,
      note: "这个接口故意延迟响应，用来演示 timeout 归类。"
    });
    return;
  }

  if (request.method === "GET" && /^\/downloads\/[\w-]+$/.test(url.pathname)) {
    if (!requireBearerAuth(request, response)) {
      return;
    }

    const slug = url.pathname.split("/")[2];
    const resource = learningResources.find(item => item.downloadSlug === slug) ?? null;

    if (!resource) {
      sendJSON(response, 404, {
        error: "download_not_found",
        message: `找不到 slug = ${slug} 的下载资源。`
      });
      return;
    }

    sendText(
      response,
      200,
      makeDownloadBody(resource),
      "text/plain; charset=utf-8",
      {
        "Content-Disposition": `attachment; filename="${slug}.txt"`
      }
    );
    return;
  }

  sendJSON(response, 404, {
    error: "not_found",
    message: `找不到 ${request.method} ${url.pathname} 对应的教学接口。`
  });
});

server.listen(port, host, () => {
  console.log(`Learn Swift teaching API listening on http://${host}:${port}`);
});
