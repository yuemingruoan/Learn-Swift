//
//  main.swift
//  42-filemanager-url-and-local-file-io
//
//  Created by Codex on 2026/3/31.
//

import Foundation

func printDivider(_ title: String) {
    print("\n======== \(title) ========")
}

func standardDirectories(using fm: FileManager) throws -> (documents: URL, caches: URL, temp: URL) {
    let documents = try fm.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )

    let caches = try fm.url(
        for: .cachesDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
    )

    return (documents: documents, caches: caches, temp: fm.temporaryDirectory)
}

func describeExistence(of url: URL, using fm: FileManager) {
    var isDirectory: ObjCBool = false
    let exists = fm.fileExists(atPath: url.path, isDirectory: &isDirectory)

    if exists && isDirectory.boolValue {
        print("存在目录: \(url.path)")
    } else if exists {
        print("存在文件: \(url.path)")
    } else {
        print("不存在: \(url.path)")
    }
}

func runDemo() {
    let fm = FileManager.default

    do {
        let dirs = try standardDirectories(using: fm)

        printDivider("标准目录 URL")
        print("Documents: \(dirs.documents.absoluteString)")
        print("Caches:    \(dirs.caches.absoluteString)")
        print("tmp:       \(dirs.temp.absoluteString)")

        printDivider("准备演示目录")
        let demoRoot = dirs.temp
            .appendingPathComponent("learn-swift", isDirectory: true)
            .appendingPathComponent("42-file-io-demo", isDirectory: true)
        let notesFolder = demoRoot.appendingPathComponent("notes", isDirectory: true)

        try fm.createDirectory(at: notesFolder, withIntermediateDirectories: true)
        print("已创建或确认目录：\(notesFolder.path)")
        describeExistence(of: notesFolder, using: fm)

        printDivider("String 写入与读取")
        let noteFileURL = notesFolder.appendingPathComponent("note.txt")
        let noteText = "Hello, File IO!\nChapter 42 demo is running."

        try noteText.write(to: noteFileURL, atomically: true, encoding: .utf8)
        let readBackText = try String(contentsOf: noteFileURL, encoding: .utf8)

        print("文件：\(noteFileURL.lastPathComponent)")
        print("读回内容：")
        print(readBackText)

        printDivider("Data 写入与读取")
        let binaryFileURL = demoRoot.appendingPathComponent("bytes.bin")
        let bytes = Data([0x48, 0x69, 0x21]) // Hi!

        try bytes.write(to: binaryFileURL, options: [.atomic])
        let readBackData = try Data(contentsOf: binaryFileURL)

        print("文件：\(binaryFileURL.lastPathComponent)")
        print("字节数：\(readBackData.count)")
        print("UTF-8 解释：\(String(decoding: readBackData, as: UTF8.self))")

        printDivider("JSON 文本落盘与读回")
        let jsonFileURL = demoRoot.appendingPathComponent("profile.json")
        let jsonText = """
        {
          "name": "Alice",
          "score": 95
        }
        """

        try jsonText.write(to: jsonFileURL, atomically: true, encoding: .utf8)
        let readBackJSON = try String(contentsOf: jsonFileURL, encoding: .utf8)
        print(readBackJSON)

        printDivider("文件缺失分支")
        let missingFileURL = demoRoot.appendingPathComponent("missing.txt")
        if fm.fileExists(atPath: missingFileURL.path) {
            print("意外：missing.txt 已存在")
        } else {
            print("file not found: \(missingFileURL.lastPathComponent)")
        }

        printDivider("Demo 完成")
        print("演示根目录：\(demoRoot.path)")
        print("你可以在 Finder 或终端里查看这些文件。")
    } catch {
        print("Demo 运行失败：\(error)")
    }
}

runDemo()
