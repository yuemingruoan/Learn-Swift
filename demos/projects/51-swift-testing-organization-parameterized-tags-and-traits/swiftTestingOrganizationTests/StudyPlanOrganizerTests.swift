import Foundation
import Testing
@testable import swiftTestingOrganization

extension Tag {
    @Tag static var organization: Self
    @Tag static var filtering: Self
    @Tag static var sorting: Self
    @Tag static var traits: Self
}

enum TraitExamples {
    static var sortingExamplesEnabled: Bool {
        ProcessInfo.processInfo.environment["DISABLE_SORTING_TRAIT_EXAMPLES"] == nil
    }

    static var optionalTraitExamplesEnabled: Bool {
        ProcessInfo.processInfo.environment["RUN_OPTIONAL_TRAIT_EXAMPLES"] == "1"
    }
}

private let reviewDays = [-2, 0, 3, 8]
private let reviewBuckets: [ReviewBucket] = [.today, .today, .thisWeek, .later]

struct FilterScenario: Sendable {
    let query: String
    let onlyIncomplete: Bool
    let expectedTitles: [String]
}

@Suite("Filtering and sorting", .tags(.organization))
struct StudyPlanOrganizerTests {
    private let tasks = DemoFixtures.tasks

    @Test("reviewBucket 把不同的天数映射到固定分桶", .tags(.filtering), arguments: zip(reviewDays, reviewBuckets))
    func reviewBucketMapping(daysUntilReview: Int, expectedBucket: ReviewBucket) {
        #expect(StudyPlanOrganizer.reviewBucket(for: daysUntilReview) == expectedBucket)
    }

    @Test("filter 可以复用同一套断言覆盖多组输入", .tags(.filtering), arguments: [
        FilterScenario(query: "Swift", onlyIncomplete: false, expectedTitles: ["Swift Testing 基础"]),
        FilterScenario(query: "52", onlyIncomplete: false, expectedTitles: ["XCTest 迁移清单", "整理异步测试笔记"]),
        FilterScenario(query: "", onlyIncomplete: true, expectedTitles: ["Swift Testing 基础", "参数化测试设计", "整理异步测试笔记"]),
    ])
    func filterScenarios(scenario: FilterScenario) {
        let result = StudyPlanOrganizer.filter(
            tasks,
            searchText: scenario.query,
            onlyIncomplete: scenario.onlyIncomplete
        )

        #expect(result.map(\.title) == scenario.expectedTitles)
    }

    @Test("不同排序策略产生不同顺序", .tags(.sorting), .timeLimit(.minutes(1)), arguments: SortStrategy.allCases)
    func sortStrategies(strategy: SortStrategy) {
        let result = StudyPlanOrganizer.sorted(tasks, strategy: strategy).map(\.title)

        switch strategy {
        case .recommended:
            #expect(result == ["Swift Testing 基础", "整理异步测试笔记", "参数化测试设计", "XCTest 迁移清单"])
        case .shortestFirst:
            #expect(result == ["XCTest 迁移清单", "整理异步测试笔记", "Swift Testing 基础", "参数化测试设计"])
        case .chapterOrder:
            #expect(result == ["Swift Testing 基础", "参数化测试设计", "XCTest 迁移清单", "整理异步测试笔记"])
        }
    }

    @Test("enabled trait 可以在需要时关闭整组示例", .tags(.traits), .enabled(if: TraitExamples.sortingExamplesEnabled))
    func enabledTraitExample() {
        let bookmarkedIncomplete = StudyPlanOrganizer
            .sorted(tasks.filter { !$0.isCompleted && $0.isBookmarked }, strategy: .chapterOrder)
            .map(\.title)

        #expect(bookmarkedIncomplete == ["Swift Testing 基础", "整理异步测试笔记"])
    }

    @Test("disabled trait 适合默认跳过的演示", .tags(.traits), .disabled(if: !TraitExamples.optionalTraitExamplesEnabled, "默认关闭，仅在显式设置环境变量时启用"))
    func disabledTraitExample() {
        let swiftOnly = StudyPlanOrganizer.filter(tasks, searchText: "Swift", onlyIncomplete: true)
        #expect(swiftOnly.map(\.title) == ["Swift Testing 基础"])
    }
}

@Suite("Serialized suite demo", .serialized, .tags(.traits))
struct SerializedTraitExamples {
    @Test("serialized suite 里的测试仍然是普通测试函数")
    func serializedSuiteStillUsesOrdinaryAssertions() {
        let orderedChapters = StudyPlanOrganizer
            .sorted(DemoFixtures.tasks, strategy: .chapterOrder)
            .map(\.chapter)

        #expect(orderedChapters == [50, 51, 52, 52])
    }
}
