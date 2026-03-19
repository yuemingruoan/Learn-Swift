//
//  main.swift
//  15-enums-and-switch
//
//  Created by 时雨 on 2026/3/19.
//

import Foundation

func printPrompt(message: String) {
    print(message, terminator: "")
    fflush(stdout)
}

enum StudyAction {
    case readChapter
    case runDemo
    case doExercise
    case reviewNotes
    case exit
}

func actionFromInput(input: String) -> StudyAction? {
    switch input {
    case "1":
        return .readChapter
    case "2":
        return .runDemo
    case "3":
        return .doExercise
    case "4":
        return .reviewNotes
    case "0":
        return .exit
    default:
        return nil
    }
}

func actionTitle(action: StudyAction) -> String {
    switch action {
    case .readChapter:
        return "阅读正文"
    case .runDemo:
        return "运行示例"
    case .doExercise:
        return "完成练习"
    case .reviewNotes:
        return "整理笔记"
    case .exit:
        return "退出程序"
    }
}

func actionSuggestion(action: StudyAction) -> String {
    switch action {
    case .readChapter:
        return "先读本章目标，再看关键代码片段。"
    case .runDemo:
        return "打开 Xcode 工程，先运行一次，再回来看 main.swift。"
    case .doExercise:
        return "先自己写，再回头看答案。"
    case .reviewNotes:
        return "把今天卡住的概念重新写成 3 句话。"
    case .exit:
        return "本次学习结束。"
    }
}

let invalidPrompt = "输入无效，请输入菜单中的编号"
var isRunning = true

print("学习任务菜单")
print("1. 阅读正文")
print("2. 运行示例")
print("3. 完成练习")
print("4. 整理笔记")
print("0. 退出")

while isRunning {
    print("")
    printPrompt(message: "请输入选项：")

    if let text = readLine() {
        if let action = actionFromInput(input: text) {
            print("你选择了：\(actionTitle(action: action))")

            switch action {
            case .readChapter, .runDemo, .doExercise, .reviewNotes:
                print(actionSuggestion(action: action))
            case .exit:
                print(actionSuggestion(action: action))
                isRunning = false
            }
        } else {
            print(invalidPrompt)
        }
    } else {
        print(invalidPrompt)
    }
}
