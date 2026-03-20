//
//  main.swift
//  17-optional-to-arc-runtime-rules
//
//  Created by 时雨 on 2026/3/20.
//

import Foundation

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func inspect(number: Int?) {
    switch number {
    case .some(let value):
        print("当前是 .some(\(value))")
    case .none:
        print("当前是 .none")
    }
}

class Tracker {
    let name: String

    init(name: String) {
        self.name = name
        print("\(name) init")
    }

    deinit {
        print("\(name) deinit")
    }
}

printDivider(title: "Optional 和 .some / .none")
let hasValue: Int? = 42
let noValue: Int? = nil

inspect(number: hasValue)
inspect(number: noValue)

printDivider(title: "if let 可以近似理解成安全解包")
if let value = hasValue {
    print("if let 解包成功，得到普通 Int：", value)
}

if let value = noValue {
    print("这一行不会执行：", value)
} else {
    print("noValue 当前没有值，所以不会进入成功分支。")
}

printDivider(title: "?? 和默认值")
let fallback = noValue ?? -1
print("noValue ?? -1 的结果是：", fallback)

printDivider(title: "class 赋值复制的是引用")
var firstTracker: Tracker? = Tracker(name: "学习记录")
var secondTracker = firstTracker

print("firstTracker === secondTracker 的结果是：", firstTracker === secondTracker)
print("说明：两个变量当前引用的是同一个实例。")

printDivider(title: "变量生命周期和实例生命周期不是一回事")
firstTracker = nil
print("firstTracker 已经设为 nil。")
print("如果 secondTracker 还在，实例就还活着。")

secondTracker = nil
print("secondTracker 也设为 nil。")
print("到这里最后一份强引用消失，实例会被释放。")

printDivider(title: "局部作用域结束时会发生什么")
do {
    let scopedTracker = Tracker(name: "作用域内实例")
    print("scopedTracker.name =", scopedTracker.name)
    print("当前作用域还没结束，所以实例仍然存在。")
}

print("do 代码块结束后，如果没有别的强引用持有它，就会触发 deinit。")
