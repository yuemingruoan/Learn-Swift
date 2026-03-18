# 11. 思考题解析：命令行成绩录入程序

## 阅读导航

- 前置章节：[08. Optional 入门](./08-optional-basics.md)、[09. 命令行输入与输出](./09-command-line-io.md)、[10. 表达式、条件判断与循环](./10-expressions-conditions-and-loops.md)
- 上一章：[10. 表达式、条件判断与循环](./10-expressions-conditions-and-loops.md)
- 建议下一章：[12. 函数与代码复用](./12-functions-and-code-reuse.md)
- 下一章：[12. 函数与代码复用](./12-functions-and-code-reuse.md)
- 适合谁先读：已经完成第十章思考题，或希望系统阅读解题过程的读者

## 本章目标

学完这一章后，你应该能够：

- 将一段自然语言需求拆分为若干明确的编程任务
- 判断哪些位置需要输入，哪些位置需要校验，哪些位置需要循环
- 理解本题中 `while` 与 `for-in` 的分工
- 明确总分、平均分、及格率分别应在何时计算
- 使用更直接的方式处理“保留一位小数并四舍五入”

## 本章对应课件

- `exercises/zh-CN/answers/10-expressions-conditions-and-loops`

本章不再引入新的核心语法，重点是说明如何将前面已经学习过的语法组织成一个完整程序。

## 为什么一定要有这道题？

前几章已经陆续介绍了以下内容：

- `print(...)`
- `readLine()`
- `Optional`
- `if let`
- 比较表达式
- `if / else`
- `for-in`
- `while`

但在综合题中，常见困难并不来自某一条语法本身，而是来自整体组织方式。例如：

- 需求较长时，不容易立即判断编写顺序
- 单个知识点可以理解，但组合后结构容易混乱

因此，本章的重点不是重复介绍语法，而是说明如何将完整需求拆分为若干可以直接落地的代码步骤。

## 第一步：先拆分需求结构

对于这一题，较为清晰的拆分方式如下：

1. 获取学生姓名
2. 获取考试次数
3. 录入每一次成绩
4. 统一计算并输出结果

进一步分析需求可得到：

- 姓名只需要录入一次
- 考试次数只需要录入一次
- 考试成绩需要按次数重复录入

一旦这三个输入层次被区分清楚，后续循环结构就会自然得多。

## 第二步：确定程序需要保存的数据

在动手编写之前，先确定程序中需要长期保存哪些值。

本题最基础的数据有以下这些：

```swift
var name: String
var frequency: Int
var score: Int
var score_sum: Int = 0
var average: Double
var pass_num: Int = 0
var pass_rate: Double
```

这些变量各自承担的职责如下：

- `name`
  保存学生姓名

- `frequency`
  保存考试次数

- `score`
  保存当前这一轮刚刚录入的成绩

- `score_sum`
  累加总分

- `average`
  保存最终计算得到的平均分

- `pass_num`
  统计及格次数

- `pass_rate`
  保存最终计算得到的及格率

这里有两个值得强调的细节。

### 为什么 `score_sum` 和 `pass_num` 需要先初始化为 `0`

因为后续会多次执行：

```swift
score_sum += score
pass_num += 1
```

这一类“累加型变量”如果没有初始值，就无法正确参与后续运算。

## 第三步：确定哪些输入需要重复校验

这道题中的输入不只是“读取成功即可”，而是还必须满足合法性要求。

若输入不合法，我们需要重新获取输入

因此，凡是存在“输入不合法就必须重输”的位置，都适合使用：

```swift
while true {
    ...
}
```

这类结构适合表达下面这层逻辑：

- 持续尝试输入
- 一旦满足条件，就使用 `break` 退出循环

例如，获取学生姓名时可以写成：

```swift
while true {
    print("请输入学生姓名：", terminator: "")
    fflush(stdout)

    if let name_temp = readLine() {
        name = name_temp
        break
    } else {
        print("输入无效，请重新输入")
    }
}
```

这一段代码看起来较为复杂，但这并不代表“姓名输入很复杂”，而是为了：

- 处理Optional类型的变量
- 保证代码的健壮性

你当然也可以像下面这么写：

```swift
var illegal:Bool = true
while illegal
{
    if let temp = readLine(){
        illegal = false
    }else {
        illegal = true
    }
}

```

但代码的可读性会差很多，而且你无法确保你的其它代码是否会在无意间修改这个变量

## 第四步：考试次数的获取与校验

考试次数的获取也是一个重难点，重在它是后续循环的控制条件，难在设计类型转换操作，因此至少要满足两点：

1. 必须能够转换成整数
2. 必须大于等于 `0` 且小于等于 `100`

因此，这一部分应当采用分层校验：

```swift
while true {
    print("请输入考试次数：", terminator: "")
    fflush(stdout)

    if let frequency_String_temp = readLine() {
        if let frequency_Int_temp = Int(frequency_String_temp) {
            if score_Int_temp<=100 && score_Int_temp >= 0  {
                frequency = frequency_Int_temp
                break
            } else {
                print("输入无效，请重新输入")
            }
        } else {
            print("输入无效，请重新输入")
        }
    } else {
        print("输入无效，请重新输入")
    }
}
```

这段代码的判断顺序具有代表性：

1. 先确认是否读到了字符串
2. 再确认该字符串能否转换成整数
3. 再确认该整数是否满足业务要求
4. 全部成立后，才将结果赋给 `frequency`

这种写法体现的是“逐层收窄条件”的思路。

同时这里涉及到了复杂的类型转换和解包操作，让我们一步一步来梳理

1. `readLine()`函数的返回值类型为`Optional<String>`
2. `Int()`函数接受的类型为`String`
3. 显然我们在这里需要第一次解包，将`Optional<String>`类型的返回值解包为`String`类型
4. 正如我们前文所讲的，`Int()`函数的返回值是`Optional<Int>`（因为并非所有字符串都能转换成功）
5. 因而此处我们需要进行第二次解包，将`Optional<Int>`类型解包为普通的`Int`类型

总结一下我们的转换链路便是：

`Optional<String> -> String -> Optional<Int> -> Int`

对于新手而言`Optional`类型的处理较为困难

但也正是因为有它，才能保证Swift的安全性

## 第五步：为什么这里要同时使用 `for-in` 和 `while`

这道题中最容易混淆的部分通常是循环结构。

应当先明确两个循环的职责不同。

### 外层 `for-in`

```swift
for fre_now in 1...frequency {
    ...
}
```

它负责控制：

- 总共需要录入多少次成绩

也就是说，考试次数确定后，这一层循环的执行次数也就确定了。

### 内层 `while true`

```swift
while true {
    ...
}
```

它负责控制：

- 当前这一次成绩录入是否合法

例如：

- 第 2 次考试如果输入错误
- 程序不应该直接进入第 3 次考试
- 而应当停留在第 2 次考试这一轮，直到用户重新输入正确内容

因此，这两层循环并不是重复，而是分别处理两类不同问题：

- `for-in` 控制总次数
- `while` 负责单次输入的反复校验

## 第六步：成绩输入成功后，应立即更新统计量

当一次成绩输入合法时，最合理的做法不是先暂存、后处理，而是立即完成本轮统计更新。

例如：

```swift
score = score_Int_temp
score_sum += score

if score >= 60 {
    pass_num += 1
}

break
```

这里的顺序是明确的：

1. 先保存当前成绩
2. 再累加总分
3. 再判断本次是否及格
4. 最后 `break`，结束当前这一轮输入校验

由于当前阶段尚未引入数组与函数，因此“每成功录入一次就立即更新统计量”是最自然、也最便于理解的方案。

同时当你需要接收上万份考试成绩的时候这些，覆写和累加的方式可以让你的内存空间不被无意义的数据占用

## 第七步：平均分的计算位置与写法

平均分应当在所有成绩录入完成之后再统一计算。

其核心公式为：

```swift
average = Double(score_sum) / Double(frequency)
```

这里最重要的是类型处理：

- `score_sum` 是 `Int`
- `frequency` 也是 `Int`

如果直接相除，就会回到整数除法的规则。

因此，这里必须先转换成 `Double`，再进行运算。

## 第八步：及格率的计算位置与写法

及格率同样应放在所有成绩录入结束之后再统一计算。

基础公式为：

```swift
pass_rate = Double(pass_num) / Double(frequency) * 100
```

这一行代码表达的逻辑非常直接：

- 及格次数
- 除以总考试次数
- 再乘以 `100`

在处理小数保留之前，应先确保这一层业务公式正确无误。

## 第九步：如何更直接地保留一位小数

当前题目要求平均分和及格率保留一位小数，并且进行四舍五入。

如果只保留一位小数，那么真正决定是否进位的，就是第二位小数。

例如：

```text
66.666...
```

这里：

- 第一位小数是 `6`
- 第二位小数也是 `6`

由于第二位小数大于等于 `5`，因此第一位小数需要进位，结果为：

```text
66.7
```

按照这一思路，可以将及格率写成：

```swift
var pass_rate_temp_1: Double = Double(pass_num) / Double(frequency) * 100
var pass_rate_temp_2: Int = Int(pass_rate_temp_1 * 10)
var pass_rate_temp_3: Int = Int(pass_rate_temp_1 * 100) % 10

if pass_rate_temp_3 >= 5 {
    pass_rate_temp_2 += 1
}

pass_rate = Double(pass_rate_temp_2) / 10
```

这几步的含义如下：

1. `pass_rate_temp_1`
   得到原始百分数，例如 `66.666...`

2. `Int(pass_rate_temp_1 * 10)`
   将第一位小数移动到整数部分  
   例如：`66.666... * 10 = 666.66...`  
   取整后得到 `666`

3. `Int(pass_rate_temp_1 * 100) % 10`
   将第二位小数移动到个位  
   例如：`66.666... * 100 = 6666.6...`  
   取整后得到 `6666`  
   再 `% 10`，即可得到第二位小数 `6`

4. 若第二位小数大于等于 `5`
   就让第一位小数对应的整数部分加 `1`

5. 最后除以 `10`
   将小数点还原

平均分可以完全使用同一套思路处理。

我们当前还没学习过对小数的操作，你可以理解为这是一种“成心为难”，但这部分真正的意义是：

- 熟悉各个类型之间的运算逻辑
- 熟悉强制类型转换的使用

## 第十步：输出结果

最终输出建议保持如下顺序：

```swift
print("学生姓名：", name)
print("考试次数：", frequency)
print("总分：", score_sum)
print("平均分：", average)
print("及格率：\(pass_rate)%")
```

同时，及格率应写成：

```swift
print("及格率：\(pass_rate)%")
```

而不是：

```swift
print("及格率：", pass_rate, "%")
```

后者在 `print` 多参数输出时会自动插入空格，结果通常会变成：

```text
80.0 %
```

而题目更希望得到：

```text
80.0%
```

## 整体结构回顾

将整道题抽象成结构后，可以概括为以下步骤：

1. 声明需要保存的数据
2. 用 `while true` 获取学生姓名
3. 用 `while true` 获取考试次数
4. 用 `for-in` 控制总共录入多少次成绩
5. 在 `for-in` 内部再用 `while true` 保证每次成绩输入合法
6. 每次输入成功后，立即更新总分和及格次数
7. 全部录入完成后，统一计算平均分和及格率
8. 最后按固定顺序输出结果

这样回看整道题，就会发现它并不是一个额外的“新题型”，而只是把前面已经学习过的语法按更完整的结构组织起来。

## 完整代码

完整参考代码可以直接查看：

- [main.swift](/Users/shiyu/Documents/Project/Learn-Swift/exercises/zh-CN/answers/10-expressions-conditions-and-loops/10-expressions-conditions-and-loops/main.swift)

更合理的阅读方式通常是：

1. 先独立完成一遍
2. 遇到卡点时再对照本章的分步分析
3. 最后再回到完整答案进行核对

## 本章小结

本章真正要解决的问题，并不是这一道题本身，而是下面这类更普遍的能力：

- 如何拆分需求
- 如何确定程序中需要保存的数据
- 如何为不同输入选择合适的循环结构
- 如何把输入、校验、统计和输出连接成完整流程

如果能够按照本章的思路独立写出这道题，那么后续再学习函数、数组以及更复杂的程序结构时，难度会明显降低。
