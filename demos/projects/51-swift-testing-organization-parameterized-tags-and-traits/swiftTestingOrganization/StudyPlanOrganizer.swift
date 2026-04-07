import Foundation

struct StudyTask: Equatable, Sendable {
    let title: String
    let chapter: Int
    let estimatedMinutes: Int
    let isCompleted: Bool
    let isBookmarked: Bool
}

enum SortStrategy: String, CaseIterable, Sendable {
    case recommended
    case shortestFirst
    case chapterOrder
}

enum ReviewBucket: String, Equatable, Sendable {
    case today = "today"
    case thisWeek = "thisWeek"
    case later = "later"
}

enum StudyPlanOrganizer {
    static func filter(_ tasks: [StudyTask], searchText: String, onlyIncomplete: Bool) -> [StudyTask] {
        let normalizedSearchText = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return tasks.filter { task in
            let matchesCompletion = !onlyIncomplete || !task.isCompleted

            guard !normalizedSearchText.isEmpty else {
                return matchesCompletion
            }

            let matchesQuery = task.title.lowercased().contains(normalizedSearchText)
                || String(task.chapter).contains(normalizedSearchText)

            return matchesCompletion && matchesQuery
        }
    }

    static func sorted(_ tasks: [StudyTask], strategy: SortStrategy) -> [StudyTask] {
        switch strategy {
        case .recommended:
            return tasks.sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted && rhs.isCompleted
                }

                if lhs.isBookmarked != rhs.isBookmarked {
                    return lhs.isBookmarked && !rhs.isBookmarked
                }

                if lhs.chapter != rhs.chapter {
                    return lhs.chapter < rhs.chapter
                }

                return lhs.title < rhs.title
            }

        case .shortestFirst:
            return tasks.sorted { lhs, rhs in
                if lhs.estimatedMinutes != rhs.estimatedMinutes {
                    return lhs.estimatedMinutes < rhs.estimatedMinutes
                }

                return lhs.title < rhs.title
            }

        case .chapterOrder:
            return tasks.sorted { lhs, rhs in
                if lhs.chapter != rhs.chapter {
                    return lhs.chapter < rhs.chapter
                }

                return lhs.title < rhs.title
            }
        }
    }

    static func reviewBucket(for daysUntilReview: Int) -> ReviewBucket {
        if daysUntilReview <= 0 {
            return .today
        }

        if daysUntilReview <= 7 {
            return .thisWeek
        }

        return .later
    }
}

enum DemoFixtures {
    static let tasks = [
        StudyTask(title: "Swift Testing 基础", chapter: 50, estimatedMinutes: 25, isCompleted: false, isBookmarked: true),
        StudyTask(title: "参数化测试设计", chapter: 51, estimatedMinutes: 35, isCompleted: false, isBookmarked: false),
        StudyTask(title: "XCTest 迁移清单", chapter: 52, estimatedMinutes: 15, isCompleted: true, isBookmarked: false),
        StudyTask(title: "整理异步测试笔记", chapter: 52, estimatedMinutes: 20, isCompleted: false, isBookmarked: true),
    ]
}
