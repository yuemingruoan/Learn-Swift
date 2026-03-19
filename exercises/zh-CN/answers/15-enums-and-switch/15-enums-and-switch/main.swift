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

enum DrinkType {
    case coffee
    case tea
    case juice
}

enum CupSize {
    case small
    case medium
    case large
}

func drinkFromInput(input: String) -> DrinkType? {
    switch input {
    case "1":
        return .coffee
    case "2":
        return .tea
    case "3":
        return .juice
    default:
        return nil
    }
}

func sizeFromInput(input: String) -> CupSize? {
    switch input {
    case "1":
        return .small
    case "2":
        return .medium
    case "3":
        return .large
    default:
        return nil
    }
}

func drinkName(drink: DrinkType) -> String {
    switch drink {
    case .coffee:
        return "咖啡"
    case .tea:
        return "茶"
    case .juice:
        return "果汁"
    }
}

func sizeName(size: CupSize) -> String {
    switch size {
    case .small:
        return "小杯"
    case .medium:
        return "中杯"
    case .large:
        return "大杯"
    }
}

func drinkBasePrice(drink: DrinkType) -> Int {
    switch drink {
    case .coffee:
        return 18
    case .tea:
        return 14
    case .juice:
        return 16
    }
}

func sizeExtraPrice(size: CupSize) -> Int {
    switch size {
    case .small:
        return 0
    case .medium:
        return 2
    case .large:
        return 4
    }
}

let invalidPrompt = "输入无效，请重新运行并输入菜单中的编号"

func exitWithInvalidInput() -> Never {
    print(invalidPrompt)
    exit(0)
}

func runOrderProgram() {
    print("欢迎使用饮品点单程序")
    print("请选择饮品：")
    print("1. 咖啡")
    print("2. 茶")
    print("3. 果汁")
    printPrompt(message: "请输入饮品编号：")

    guard let drinkInput = readLine(),
          let selectedDrink = drinkFromInput(input: drinkInput) else {
        exitWithInvalidInput()
    }

    print("")
    print("请选择杯型：")
    print("1. 小杯")
    print("2. 中杯")
    print("3. 大杯")
    printPrompt(message: "请输入杯型编号：")

    guard let sizeInput = readLine(),
          let selectedSize = sizeFromInput(input: sizeInput) else {
        exitWithInvalidInput()
    }

    let totalPrice = drinkBasePrice(drink: selectedDrink) + sizeExtraPrice(size: selectedSize)

    print("")
    print("你选择的饮品：", drinkName(drink: selectedDrink))
    print("你选择的杯型：", sizeName(size: selectedSize))
    print("价格：\(totalPrice) 元")
}

runOrderProgram()
