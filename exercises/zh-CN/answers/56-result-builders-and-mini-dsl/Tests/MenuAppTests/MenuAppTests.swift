import Testing
@testable import MenuApp

@Test("MenuBuilder 处理顺序拼接")
func menuSequential() {
    let m = menu(title: "M") {
        item("a")
        item("b")
    }
    let s = m.render()
    #expect(s.contains("- a"))
    #expect(s.contains("- b"))
}

@Test("MenuBuilder 处理 if-else")
func menuIfElse() {
    func make(isPro: Bool) -> MenuNode {
        menu(title: "M") {
            if isPro {
                item("Pro Feature")
            } else {
                item("Upgrade")
            }
        }
    }
    #expect(make(isPro: true).render().contains("Pro Feature"))
    #expect(make(isPro: false).render().contains("Upgrade"))
}

@Test("MenuBuilder 处理 for-in")
func menuForIn() {
    let m = menu(title: "M") {
        for n in ["x", "y", "z"] {
            item(n)
        }
    }
    let s = m.render()
    #expect(s.contains("- x"))
    #expect(s.contains("- y"))
    #expect(s.contains("- z"))
}

@Test("MenuBuilder 处理嵌套 submenu")
func menuNested() {
    let m = menu(title: "M") {
        submenu(title: "S") {
            item("inner")
        }
    }
    let s = m.render()
    #expect(s.contains("+ S"))
    #expect(s.contains("- inner"))
}
