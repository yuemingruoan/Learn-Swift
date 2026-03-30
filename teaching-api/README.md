# Learn Swift Teaching API

这是第 `37`、`38` 章配套使用的本地教学 API。

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

- `GET /health`
- `GET /health.json`
- `GET /todos/1`
- `GET /todos?limit=3`
- `POST /study-records`

## 快速验证

```bash
open http://127.0.0.1:3456/health
curl http://127.0.0.1:3456/health.json
curl http://127.0.0.1:3456/todos/1
curl "http://127.0.0.1:3456/todos?limit=3"
curl -X POST http://127.0.0.1:3456/study-records \
  -H "Content-Type: application/json" \
  -d '{"chapter":38,"title":"完成 URLSession POST 练习","durationMinutes":25}'
```
