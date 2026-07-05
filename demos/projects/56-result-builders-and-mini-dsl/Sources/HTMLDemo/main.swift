import Foundation
import HTMLDSL

let isAdmin = true
let posts = [
    Post(title: "Hello SwiftUI", body: "今天开始学 SwiftUI"),
    Post(title: "Result Builder", body: "原来 DSL 不神秘"),
]

let page = html {
    head {
        title { text("我的博客") }
    }
    body {
        if isAdmin {
            div {
                text("欢迎管理员")
            }
        } else {
            div {
                text("欢迎访客")
            }
        }
        for post in posts {
            article {
                h1 { text(post.title) }
                p { text(post.body) }
            }
        }
        p {
            a(href: "https://swift.org") {
                text("Learn more")
            }
        }
    }
}

print(page.render())
