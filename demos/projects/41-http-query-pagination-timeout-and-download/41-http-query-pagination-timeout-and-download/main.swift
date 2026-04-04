//
//  main.swift
//  41-http-query-pagination-timeout-and-download
//
//  Created by Codex on 2026/4/4.
//

import Foundation

func printDivider(_ title: String) {
    print("")
    print("======== \(title) ========")
}

func printUser(_ user: UserProfileDTO) {
    print("用户：\(user.name) (@\(user.username))")
    print("偏好主线：\(user.preferredTrack)")
}

func printPage(_ page: PageDTO<LearningResourceDTO>) {
    print("page=\(page.page) limit=\(page.limit) total=\(page.total) hasMore=\(page.hasMore)")
    for item in page.items {
        print("- [\(item.category.rawValue)] \(item.title) / \(item.durationMinutes) 分钟 / 下载标识 \(item.downloadSlug)")
    }
}

func bodyPreview(from data: Data?) -> String {
    guard
        let data,
        !data.isEmpty,
        let text = String(data: data, encoding: .utf8)
    else {
        return "<empty>"
    }

    return text.replacingOccurrences(of: "\n", with: " ")
}

func printError(_ error: Error) {
    switch error {
    case NetworkError.notLoggedIn:
        print("错误：当前请求需要登录态。")
    case NetworkError.timeout:
        print("错误：请求超时。它属于 transport 失败，不是状态码错误。")
    case NetworkError.urlConstructionFailed:
        print("错误：URL 构造失败。")
    case let NetworkError.requestBodyEncodingFailed(underlying):
        print("错误：请求体编码失败 -> \(underlying)")
    case let NetworkError.transportFailed(underlying):
        print("错误：发送阶段失败 -> \(underlying)")
    case NetworkError.nonHTTPResponse:
        print("错误：响应不是 HTTPURLResponse。")
    case let NetworkError.badStatusCode(code, body):
        print("错误：状态码异常 -> \(code)")
        print("响应体预览：\(bodyPreview(from: body))")
    case let NetworkError.decodingFailed(underlying, body):
        print("错误：响应体解码失败 -> \(underlying)")
        print("原始响应体：\(bodyPreview(from: body))")
    default:
        print("错误：\(error)")
    }
}

func printRequestURL(_ request: URLRequest, label: String) {
    print("\(label)：\(request.url?.absoluteString ?? "<invalid>")")
    if let timeoutInterval = request.timeoutInterval as TimeInterval?, timeoutInterval > 0 {
        print("timeoutInterval：\(timeoutInterval)s")
    }
}

func previewDownloadedFile(_ downloadedFile: DownloadedFile) {
    print("临时文件：\(downloadedFile.temporaryFileURL.path)")
    print("Content-Type：\(downloadedFile.contentType ?? "<none>")")
    print("建议文件名：\(downloadedFile.suggestedFilename ?? "<none>")")

    if let text = try? String(contentsOf: downloadedFile.temporaryFileURL, encoding: .utf8) {
        let previewLines = text.split(separator: "\n").prefix(4).joined(separator: "\n")
        print("文件预览：")
        print(previewLines)
    }
}

func runDemo() async {
    let authState = AuthState()
    let client = NetworkClient(baseURL: APIConfig.baseURL, authState: authState)
    let downloadClient = DownloadClient(baseURL: APIConfig.baseURL, authState: authState)
    let api = LearningResourcesAPI(client: client, downloadClient: downloadClient, authState: authState)

    printDivider("先登录，沿用第 40 章的 Bearer Token 建模")
    do {
        let user = try await api.loginDemoUser()
        printUser(user)
    } catch {
        printError(error)
        return
    }

    let firstQuery = ResourceQuery(
        keyword: nil,
        category: .networking,
        page: 1,
        limit: 3,
        sort: .publishedAt,
        order: .desc
    )

    printDivider("查询参数：把筛选、分页、排序都收进 ResourceQuery")
    do {
        let request = try client.previewRequest(for: .learningResources(query: firstQuery))
        printRequestURL(request, label: "最终 URL")
        let page = try await api.listResources(query: firstQuery)
        printPage(page)
    } catch {
        printError(error)
    }

    printDivider("分页：只改 page，仍走同一个 endpoint 组装过程")
    do {
        let secondPageQuery = ResourceQuery(
            keyword: nil,
            category: .networking,
            page: 2,
            limit: 3,
            sort: .publishedAt,
            order: .desc
        )
        let request = try client.previewRequest(for: .learningResources(query: secondPageQuery))
        printRequestURL(request, label: "最终 URL")
        let secondPage = try await api.listResources(query: secondPageQuery)
        printPage(secondPage)
    } catch {
        printError(error)
    }

    printDivider("搜索词可选：只在需要时才出现在 queryItems")
    do {
        let keywordQuery = ResourceQuery(
            keyword: "接口",
            category: .networking,
            page: 1,
            limit: 5,
            sort: .publishedAt,
            order: .asc
        )
        let request = try client.previewRequest(for: .learningResources(query: keywordQuery))
        printRequestURL(request, label: "最终 URL")
        let keywordPage = try await api.listResources(query: keywordQuery)
        printPage(keywordPage)
    } catch {
        printError(error)
    }

    printDivider("timeout：失败发生在发送阶段，不会走状态码分支")
    do {
        let request = try client.previewRequest(for: .slowSummary(delayMs: 2000, timeoutInterval: 1.0))
        printRequestURL(request, label: "超时请求 URL")
        let _: SlowSummaryDTO = try await api.fetchSlowSummary(delayMs: 2000, timeoutInterval: 1.0)
    } catch {
        printError(error)
    }

    printDivider("下载：不再解码 JSON，而是走 DownloadClient")
    do {
        let request = try downloadClient.previewRequest(for: .downloadGuide(slug: "endpoint-modeling-checklist"))
        printRequestURL(request, label: "下载 URL")
        let downloadedFile = try await api.downloadGuide(slug: "endpoint-modeling-checklist")
        previewDownloadedFile(downloadedFile)
    } catch {
        printError(error)
    }

    printDivider("这一章的收益")
    print("JSON 请求继续走 NetworkClient，下载请求改走 DownloadClient，二者共享 Endpoint 和鉴权状态。")
    print("ResourceQuery、PageDTO、DownloadedFile 把查询、分页、超时、下载分别放回自己的模型里。")
}

let demoSemaphore = DispatchSemaphore(value: 0)

Task {
    await runDemo()
    demoSemaphore.signal()
}

demoSemaphore.wait()
