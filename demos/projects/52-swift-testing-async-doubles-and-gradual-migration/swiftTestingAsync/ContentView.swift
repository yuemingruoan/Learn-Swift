import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Swift Testing 异步与替身 Demo")
                .font(.title2)
                .fontWeight(.semibold)

            Text("本章示例重点不在 UI，而在 ArticleService 的异步测试。")
            Text("请打开 swiftTestingAsyncTests target 观察 fake / stub / spy 的写法。")
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview {
    ContentView()
}
