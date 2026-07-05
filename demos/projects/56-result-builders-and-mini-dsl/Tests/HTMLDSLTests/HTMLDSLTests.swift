import Testing
@testable import HTMLDSL

@Test("纯顺序拼接生成多个子节点")
func sequentialNodes() {
    let node = div {
        text("a")
        text("b")
    }
    let s = node.render()
    #expect(s.contains("a"))
    #expect(s.contains("b"))
}

@Test("if-else 分支生效")
func ifElseBranches() {
    func make(isAdmin: Bool) -> HTMLNode {
        div {
            if isAdmin {
                text("admin")
            } else {
                text("guest")
            }
        }
    }
    #expect(make(isAdmin: true).render().contains("admin"))
    #expect(!make(isAdmin: true).render().contains("guest"))
    #expect(make(isAdmin: false).render().contains("guest"))
    #expect(!make(isAdmin: false).render().contains("admin"))
}

@Test("单边 if 在条件不成立时被忽略")
func optionalBranchIgnored() {
    func make(showBanner: Bool) -> HTMLNode {
        div {
            text("always")
            if showBanner {
                text("BANNER")
            }
        }
    }
    #expect(make(showBanner: true).render().contains("BANNER"))
    #expect(!make(showBanner: false).render().contains("BANNER"))
}

@Test("for-in 展开为多个子节点")
func forInExpands() {
    let arr = ["A", "B", "C"]
    let node = div {
        for x in arr {
            text(x)
        }
    }
    let s = node.render()
    #expect(s.contains("A"))
    #expect(s.contains("B"))
    #expect(s.contains("C"))
}

@Test("属性会被正确渲染")
func attributesRender() {
    let node = a(href: "https://swift.org") {
        text("link")
    }
    let s = node.render()
    #expect(s.contains("href=\"https://swift.org\""))
    #expect(s.contains("link"))
}
