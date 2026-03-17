//
//  main.swift
//  10-expressions-conditions-and-loops
//
//  Created by 时雨 on 2026/3/17.
//

import Foundation

//一般建议在开头集中声明需要的变量
var name:String //姓名
var frequency:Int //考试次数
var score:Int //分数
var score_sum:Int = 0 //总分,提前声明0是因为后续代码需要
var average:Double //平均分
var pass_num:Int = 0 //及格成绩数,提前声明0是因为后续代码需要
var pass_rate:Double //及格率
let invalid_prompt:String = "输入无效，请重新输入"

//获取学生姓名
while true { //显然此时while的判断始终为true,但这不意味这是一个死循环，我们还可以使用break进行跳出
    print("请输入学生姓名：",terminator: "")//获取学生姓名
    fflush(stdout)
    if let name_temp = readLine(){
        name = name_temp
        break //如果成功获取到了name,就跳出循环
    }  else {
        print(invalid_prompt) //因为被死循环包裹，所以运行出if块后会进行下一轮循环
    }
}

//获取考试次数
while true { //同上的获取逻辑
    print("请输入考试次数：",terminator: "")
    fflush(stdout)
    if let frequency_String_temp = readLine(){ //注意：readLine返回值为Optional<String>,解包后类型为String,而不是我们需要的Int
        if let frequency_Int_temp = Int(frequency_String_temp){ //转换后得到的是Optional<Int>,而不是Int,因此需要再次解包
            if frequency_Int_temp > 0 {
                frequency = frequency_Int_temp
                break
            }else {
                print(invalid_prompt)
            }
        } else {
            print(invalid_prompt)
        }
    }  else {
        print(invalid_prompt)
    }
}

//获取考试成绩
for fre_now in 1...frequency {
    while true { //同上的获取逻辑
        print("请输入第",fre_now,"次考试成绩：",terminator: "")
        fflush(stdout)
        if let score_String_temp = readLine(){
            if let score_Int_temp = Int(score_String_temp){
                if score_Int_temp<=100 && score_Int_temp >= 0 {
                    score = score_Int_temp
                    score_sum += score //若sum没有初始化，本行代码会报错Variable 'sum' passed by reference before being initialized
                    if score >= 60 {
                        pass_num += 1 //同理
                    }
                    break
                } else {
                    print(invalid_prompt)
                }
            } else {
                print(invalid_prompt)
            }
        }  else {
            print(invalid_prompt)
        }
    }
}

//获取及格率
//只需要保留一位小数时，可以直接看第二位小数要不要进位
var pass_rate_temp_1:Double = Double(pass_num) / Double(frequency) * 100 //先得到原始百分数，例如 66.6666
var pass_rate_temp_2:Int = Int(pass_rate_temp_1 * 10) //把第一位小数挪到整数部分，例如 666
var pass_rate_temp_3:Int = Int(pass_rate_temp_1 * 100) % 10 //直接取第二位小数，例如 6
if pass_rate_temp_3 >= 5 {
    pass_rate_temp_2 += 1 //如果第二位小数大于等于5，就对第一位小数进位
}
pass_rate = Double(pass_rate_temp_2) / 10 //还原小数点，此时值为66.7，得到答案

//获取平均分（同理）
var average_temp:Double = Double(score_sum)/Double(frequency)
var average_temp_2:Int = Int(average_temp * 10)
var average_temp_3:Int = Int(average_temp * 100) % 10
if average_temp_3 >= 5 {
    average_temp_2 += 1
}
average = Double(average_temp_2) / 10

//打印最终结果
print("学生姓名：",name)
print("考试次数：",frequency)
print("总分：",score_sum)
print("平均分：",average)
print("及格率：\(pass_rate)%")
