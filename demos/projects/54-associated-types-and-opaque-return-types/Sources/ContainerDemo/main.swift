import ContainerKit

let intStack = IntStack(items: [1, 2, 3, 4])
print("IntStack count = \(intStack.count)")
print("IntStack contains 3? \(intStack.contains(3))")

let stringStack = StringStack(items: ["swift", "ui"])
print("StringStack count = \(stringStack.count)")
print("StringStack contains \"ui\"? \(stringStack.contains("ui"))")

let source = makeUserSource()
let firstPage = try await source.fetch(page: 0)
print("first page count = \(firstPage.count)")
print("first user = \(firstPage.first!.name)")

let heterogeneous: [any Container] = [intStack, stringStack]
print("heterogeneous container count = \(heterogeneous.count)")
for box in heterogeneous {
    print("  - one container has \(box.count) items")
}
