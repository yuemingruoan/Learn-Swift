//
//  main.swift
//  28-arc-advanced-weak-unowned-and-capture-lists
//
//  Created by Codex on 2026/3/23.
//

func printDivider(title: String) {
    print("")
    print("======== \(title) ========")
}

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
    weak var teacher: Teacher?

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
    unowned let chapter: Chapter

    init(content: String, chapter: Chapter) {
        self.content = content
        self.chapter = chapter
        print("Note \(content) 已创建")
    }

    func summary() -> String {
        return "《\(chapter.title)》笔记：\(content)"
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
        onFinish = { [weak self] in
            if let currentSession = self {
                print("\(currentSession.title) 已完成")
            } else {
                print("session 已释放，回调不再继续执行")
            }
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

    if let classroom, let teacher = classroom.teacher {
        print("当前教室老师：\(teacher.name)")
    }

    print("步骤 1：把 teacher 变量设为 nil")
    teacher = nil
    if let classroom {
        print("Teacher 释放后，classroom.teacher 是否自动变成 nil：\(classroom.teacher == nil)")
    }

    print("步骤 2：再把 classroom 变量设为 nil")
    classroom = nil
    print("说明：")
    print("- Classroom 对 teacher 使用 weak。")
    print("- 所以 Teacher 先释放后，Classroom 内部那条引用会自动清空。")
    print("- 最后当 classroom 自己也没有强引用时，Classroom 才释放。")
}

func runChapterAndNoteDemo() {
    var chapter: Chapter? = Chapter(title: "ARC 进阶")
    weak var firstObservedNote: ChapterNote?

    if let chapter {
        let note1 = ChapterNote(content: "先画清持有关系", chapter: chapter)
        let note2 = ChapterNote(content: "再决定 weak 还是 unowned", chapter: chapter)
        firstObservedNote = note1
        chapter.notes.append(note1)
        chapter.notes.append(note2)

        for note in chapter.notes {
            print(note.summary())
        }
    }

    print("步骤 1：当前 firstObservedNote 是否还存在：\(firstObservedNote != nil)")
    print("步骤 2：把 chapter 变量设为 nil")
    chapter = nil
    print("步骤 3：Chapter 释放后，firstObservedNote 是否也变成 nil：\(firstObservedNote == nil)")
    print("说明：")
    print("- Chapter 强持有 notes。")
    print("- Note 只用 unowned 引用 chapter，不反向拥有 chapter。")
    print("- 所以 Chapter 释放时，它持有的 notes 也会一起释放。")
}

func runSessionDemo() {
    var session: StudySession? = StudySession(title: "复盘 ARC 小节")
    session?.setupCallback()
    session?.onFinish?()

    let callbackAfterRelease = session?.onFinish
    print("步骤 1：保存一份闭包引用，用来观察 session 释放后的行为")
    print("步骤 2：把 session 变量设为 nil")
    session = nil
    print("步骤 3：再次调用先前保存的闭包")
    callbackAfterRelease?()
    print("说明：")
    print("- StudySession 强持有 onFinish 闭包。")
    print("- 闭包用 [weak self] 捕获 session，自然不会把 session 留住。")
    print("- 所以 session 释放后，闭包还能存在，但里面的 self 已经会变成 nil。")
}

printDivider(title: "完整功能：课程对象关系管理")
runTeacherAndClassroomDemo()

printDivider(title: "unowned 适合始终存在的所属关系")
runChapterAndNoteDemo()

printDivider(title: "闭包也可能形成循环引用")
runSessionDemo()

printDivider(title: "这一章最想演示的差别")
print("说明：")
print("- weak：关系可以为空，被引用对象可以先离开。")
print("- unowned：关系不应为空，但也不该拥有对方。")
print("- [weak self]：闭包需要引用对象，但不该把对象继续强留在内存里。")
