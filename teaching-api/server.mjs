import http from "node:http";

const port = Number(process.env.PORT ?? 3456);
const host = process.env.HOST ?? "127.0.0.1";

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
  }
];

let nextStudyRecordID = 101;
const studyRecords = [];

function sendJSON(response, statusCode, payload) {
  response.writeHead(statusCode, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Content-Type": "application/json; charset=utf-8"
  });
  response.end(JSON.stringify(payload, null, 2));
}

function sendHTML(response, statusCode, html) {
  response.writeHead(statusCode, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Content-Type": "text/html; charset=utf-8"
  });
  response.end(html);
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
    <p>这说明你的本地服务已经可用，可以继续学习后续网络请求章节。后续章节需要的具体接口，会在用到时再逐步说明。</p>
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

const server = http.createServer(async (request, response) => {
  if (!request.url || !request.method) {
    sendJSON(response, 400, {
      error: "bad_request",
      message: "请求缺少 URL 或 Method。"
    });
    return;
  }

  if (request.method === "OPTIONS") {
    response.writeHead(204, {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
    });
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

  if (request.method === "GET" && url.pathname === "/todos/1") {
    sendJSON(response, 200, todos[0]);
    return;
  }

  if (request.method === "GET" && url.pathname === "/todos") {
    const limitText = url.searchParams.get("limit");
    const limit = limitText == null ? todos.length : Number(limitText);

    if (Number.isNaN(limit) || limit <= 0) {
      sendJSON(response, 400, {
        error: "invalid_limit",
        message: "查询参数 limit 必须是大于 0 的数字。"
      });
      return;
    }

    sendJSON(response, 200, todos.slice(0, limit));
    return;
  }

  if (request.method === "POST" && url.pathname === "/study-records") {
    const contentType = request.headers["content-type"] ?? "";

    if (!contentType.includes("application/json")) {
      sendJSON(response, 415, {
        error: "unsupported_media_type",
        message: "POST /study-records 只接受 application/json。"
      });
      return;
    }

    try {
      const rawBody = await readRequestBody(request);
      const payload = JSON.parse(rawBody);

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

  sendJSON(response, 404, {
    error: "not_found",
    message: `找不到 ${request.method} ${url.pathname} 对应的教学接口。`
  });
});

server.listen(port, host, () => {
  console.log(`Learn Swift teaching API listening on http://${host}:${port}`);
});
