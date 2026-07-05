import Foundation
import WrapperKit

var s = AppSettings()
s.brightness = 250
print("brightness = \(s.brightness)")
print("brightness raw = \(s.$brightness)")

s.nickname = "   Tim Cook  "
print("nickname = [\(s.nickname)]")

let store = UserDefaults.standard
store.removeObject(forKey: "settings.theme")
store.removeObject(forKey: "settings.fontSize")

print("theme = \(s.theme)")
s.theme = "dark"
print("theme after = \(s.theme)")
print("theme persisted? \(store.string(forKey: "settings.theme") ?? "nil")")

s.$theme.reset()
print("theme after reset = \(s.theme)")
