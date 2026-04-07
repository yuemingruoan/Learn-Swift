import Testing
@testable import swiftTestingBasics

struct AddTests {
    @Test("add 会返回两个整数的和")
    func addReturnsSum() {
        let result = add(2, 3)

        #expect(result == 5)
    }
}
