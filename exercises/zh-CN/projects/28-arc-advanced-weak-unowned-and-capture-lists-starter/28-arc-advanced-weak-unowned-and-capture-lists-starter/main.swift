//
//  main.swift
//  28-arc-advanced-weak-unowned-and-capture-lists-starter
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

// 这个 starter project 的问题不是“跑不起来”，而是：
// 1. 对象之间的强引用关系写错了。
// 2. 某些对象释放时，deinit 没有触发。
// 3. 闭包强捕获 self，导致 session 一直被留住。
//
// 练习目标：
// - 先画清谁强持有谁。
// - 再判断哪些地方应该用 weak / unowned / [weak self]。
// - 保持当前业务语义不变，但让对象能按预期释放。

class Teacher {
    let name: String
    var classroom: Classroom?

    init(name: String) {
        self.name = name
        print("Teacher \(name) 已创建")
    }

    deinit {
        print("Teacher \(name) 被释放")
    }
}

class Classroom {
    let roomID: String
    var teacher: Teacher?

    init(roomID: String) {
        self.roomID = roomID
        print("Classroom \(roomID) 已创建")
    }

    deinit {
        print("Classroom \(roomID) 被释放")
    }
}

class Chapter {
    let title: String
    var notes: [ChapterNote] = []

    init(title: String) {
        self.title = title
        print("Chapter \(title) 已创建")
    }

    deinit {
        print("Chapter \(title) 被释放")
    }
}

class ChapterNote {
    let content: String
    var chapter: Chapter?

    init(content: String, chapter: Chapter) {
        self.content = content
        self.chapter = chapter
        print("Note \(content) 已创建")
    }

    func summary() -> String {
        if let chapter {
            return "《\(chapter.title)》笔记：\(content)"
        } else {
            return "没有所属章节：\(content)"
        }
    }

    deinit {
        print("Note \(content) 被释放")
    }
}

class StudySession {
    let title: String
    var onFinish: (() -> Void)?

    init(title: String) {
        self.title = title
        print("StudySession \(title) 已创建")
    }

    func setupCallback() {
        onFinish = {
            print("\(self.title) 已完成")
        }
    }

    deinit {
        print("StudySession \(title) 被释放")
    }
}

func runTeacherAndClassroomDemo() {
    var teacher: Teacher? = Teacher(name: "周老师")
    var classroom: Classroom? = Classroom(roomID: "A101")

    teacher?.classroom = classroom
    classroom?.teacher = teacher

    print("把 teacher 变量设为 nil")
    teacher = nil

    print("把 classroom 变量设为 nil")
    classroom = nil

    print("TODO：当前这里没有看到对象释放，请修复这段关系。")
}

func runChapterAndNoteDemo() {
    var chapter: Chapter? = Chapter(title: "ARC 进阶")

    if let chapter {
        let note1 = ChapterNote(content: "先画清持有关系", chapter: chapter)
        let note2 = ChapterNote(content: "再决定 weak 还是 unowned", chapter: chapter)
        chapter.notes.append(note1)
        chapter.notes.append(note2)

        for note in chapter.notes {
            print(note.summary())
        }
    }

    chapter = nil
    print("TODO：思考这里的所属关系到底该不该写成强引用。")
}

func runSessionDemo() {
    var session: StudySession? = StudySession(title: "复盘 ARC 小节")
    session?.setupCallback()
    let callback = session?.onFinish
    callback?()

    print("把 session 变量设为 nil")
    session = nil

    print("再次调用 callback")
    callback?()

    print("TODO：当前闭包会把 session 留住，请修复。")
}

printDivider(title: "对象之间的强引用关系")
runTeacherAndClassroomDemo()

printDivider(title: "所属关系也可能写错")
runChapterAndNoteDemo()

printDivider(title: "闭包也可能把对象留住")
runSessionDemo()
