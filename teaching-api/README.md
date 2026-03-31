# Learn Swift Teaching API

这是第 `37`～`41` 章配套使用的本地教学 API。

## 运行要求

- Node.js `20+`

## 启动方式

```bash
cd teaching-api
npm run start
```

开发时也可以用 watch 模式：

```bash
cd teaching-api
npm run dev
```

默认地址：

- `http://127.0.0.1:3456`

## 提供的接口

基础健康检查：

- `GET /health`
- `GET /health.json`

第 38～39 章：

- `GET /todos/:id`
- `GET /todos?limit=3`
- `GET /diagnostics/server-error`
- `GET /diagnostics/bad-todo-json`
- `POST /study-records`

第 40 章：

- `POST /auth/token-login`
- `GET /auth/token-me`
- `GET /auth/admin-report`
- `POST /auth/session-login`
- `GET /auth/session-me`

第 41 章：

- `GET /learning-resources?q=swift&category=networking&page=1&limit=3&sort=publishedAt&order=desc`
- `GET /slow-summary?delayMs=1800`
- `GET /downloads/:slug`

## 快速验证

```bash
open http://127.0.0.1:3456/health
curl http://127.0.0.1:3456/health.json
curl http://127.0.0.1:3456/todos/1
curl "http://127.0.0.1:3456/todos?limit=3"
curl http://127.0.0.1:3456/diagnostics/server-error
curl http://127.0.0.1:3456/diagnostics/bad-todo-json
curl -X POST http://127.0.0.1:3456/study-records \
  -H "Content-Type: application/json" \
  -d '{"chapter":38,"title":"完成 URLSession POST 练习","durationMinutes":25}'

curl -X POST http://127.0.0.1:3456/auth/token-login \
  -H "Content-Type: application/json" \
  -d '{"username":"swift-demo","password":"123456"}'

curl http://127.0.0.1:3456/auth/token-me \
  -H "Authorization: Bearer swift-demo-token"

curl "http://127.0.0.1:3456/learning-resources?q=swift&category=networking&page=1&limit=3&sort=publishedAt&order=desc" \
  -H "Authorization: Bearer swift-demo-token"

curl http://127.0.0.1:3456/slow-summary?delayMs=1800 \
  -H "Authorization: Bearer swift-demo-token"

curl -OJ http://127.0.0.1:3456/downloads/endpoint-modeling-checklist \
  -H "Authorization: Bearer swift-demo-token"
```
