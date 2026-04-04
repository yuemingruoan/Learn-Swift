import Foundation

actor FakeRemoteAPI {
    private var requestCount = 0

    func fetchTodos() async throws -> [TodoDTO] {
        requestCount += 1
        try await Task.sleep(for: .milliseconds(200))

        return [
            TodoDTO(id: 1, title: "查看今天列表（第 \(requestCount) 次远程请求）", completed: false),
            TodoDTO(id: 2, title: "保留上次成功结果", completed: true),
            TodoDTO(id: 3, title: "判断缓存是否损坏", completed: false)
        ]
    }
}
