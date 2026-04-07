import XCTest
@testable import swiftTestingBasics

final class XCTestComparisonTests: XCTestCase {
    func testSummaryWithXCTestAssertionStyle() {
        let tasks = [
            StudyTask(title: "阅读第 50 章", estimatedMinutes: 20, isCompleted: true),
            StudyTask(title: "运行示例", estimatedMinutes: 30, isCompleted: false),
        ]

        let summary = StudyProgress.summary(for: tasks)

        XCTAssertEqual(summary.completedCount, 1)
        XCTAssertEqual(summary.remainingCount, 1)
        XCTAssertEqual(summary.totalMinutes, 50)
    }
}
