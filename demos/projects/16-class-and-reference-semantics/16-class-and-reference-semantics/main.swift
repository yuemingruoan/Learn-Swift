//
//  main.swift
//  16-class-and-reference-semantics
//
//  Created by 时雨 on 2026/3/20.
//

import Foundation

struct ScoreRecord {
    var score: Int
}

class StudyProfile {
    var name: String
    var currentScore: Int
    var studyHours: Int

    init(name: String, currentScore: Int, studyHours: Int) {
        self.name = name
        self.currentScore = currentScore
        self.studyHours = studyHours
    }

    func printSummary(label: String) {
        print("\(label) -> 姓名：\(name)，分数：\(currentScore)，学习时长：\(studyHours) 小时")
    }
}

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

func increaseScore(profile: StudyProfile, by delta: Int) {
    profile.currentScore += delta
}

printDivider(title: "struct 的值语义")
var recordA = ScoreRecord(score: 80)
var recordB = recordA
recordB.score = 100

print("recordA.score =", recordA.score)
print("recordB.score =", recordB.score)
print("说明：这里修改的是两份独立的值。")

printDivider(title: "class 的引用语义")
let profileA = StudyProfile(name: "小林", currentScore: 82, studyHours: 6)
let profileB = profileA

profileB.currentScore = 95
profileB.studyHours += 2

profileA.printSummary(label: "profileA")
profileB.printSummary(label: "profileB")
print("profileA === profileB 的结果是：", profileA === profileB)
print("说明：这两个变量引用的是同一个实例。")

printDivider(title: "let 和 var 的区别")
let fixedProfile = StudyProfile(name: "小周", currentScore: 70, studyHours: 4)
fixedProfile.currentScore = 73
fixedProfile.printSummary(label: "fixedProfile")
print("说明：let 限制的是变量重新绑定，不是实例内部 var 属性一定不能改。")

var currentProfile = StudyProfile(name: "小王", currentScore: 60, studyHours: 2)
let oldProfile = currentProfile
currentProfile = StudyProfile(name: "小王", currentScore: 88, studyHours: 9)

oldProfile.printSummary(label: "oldProfile")
currentProfile.printSummary(label: "currentProfile")
print("oldProfile === currentProfile 的结果是：", oldProfile === currentProfile)
print("说明：var 变量既可以修改实例属性，也可以重新绑定到另一个实例。")

printDivider(title: "把 class 传给函数")
increaseScore(profile: profileA, by: 3)
profileA.printSummary(label: "profileA")
profileB.printSummary(label: "profileB")
print("说明：函数里改到的是同一个实例，所以外部也能看到变化。")

printDivider(title: "内容相同，不代表同一个实例")
let profileC = StudyProfile(name: "小林", currentScore: 98, studyHours: 8)
profileC.printSummary(label: "profileC")
print("profileA === profileC 的结果是：", profileA === profileC)
print("说明：虽然 profileA 和 profileC 的内容看起来很像，但它们不是同一个实例。")
