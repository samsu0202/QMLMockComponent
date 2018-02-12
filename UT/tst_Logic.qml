import QtQuick 2.7
import QtTest 1.1
import ".."
import "../MockComponent"

Item {
    width: 100
    height: 100


    Logic {
        id: logic
    }

    TestCase {
        when: windowShown
        name: "Test by old method"

        Item {
            id: mockFooOld

            property var func1RetVals: [] // 定義boo被呼叫後的回傳值
            property int func1CallTimes: 0 // 記錄boo被呼叫的次數

            signal signal1()
            signal signal2(string v1, int v2);
            signal func2(string v1, int v2); // func2不會用到return value, 所以可用signal代替function

            function func1(){
                func1CallTimes++;
                return func1RetVals[func1CallTimes - 1]
            }

            function reset() {
                func1RetVals = [];
                func1CallTimes = 0;
            }
        }

        SignalSpy {
            id: spy1
            target: mockFooOld
            signalName: "signal1"
        }

        SignalSpy {
            id: spy2
            target: mockFooOld
            signalName: "signal2"
        }

        SignalSpy {
            id: spy3
            target: mockFooOld
            signalName: "func2"
        }

        function init() {
            logic.foo = mockFooOld;
        }

        function cleanup() {
            // mock object記得要還原原本狀態
            mockFooOld.reset();
        }

        function test_checkAll_old() {
            // arrange, 設定func1被呼叫後的回傳值, 兩次分別傳true跟false
            mockFooOld.func1RetVals.push(true);
            mockFooOld.func1RetVals.push(false);

            // action, 呼叫兩次分別帶不同參數
            logic.testMethod("a", 123);
            logic.testMethod("b", 234);

            // assert
            /// check signal1, 沒有參數所以只測呼叫次數
            compare(spy1.count, 2);

            /// check signal2, 除了呼叫次數來必須檢查參數
            compare(spy2.count, 2);
            var args = spy2.signalArguments[0];
            compare(args[0], "a");
            compare(args[1], 123);
            args = spy2.signalArguments[1];
            compare(args[0], "b");
            compare(args[1], 234);

            /// check func1, 利用mockFooOld的func1CallTimes檢查呼叫次數
            compare(mockFooOld.func1CallTimes, 2);

            /// check func2, 由於func1RetVals在arrange分別各傳true(第一次呼叫)跟false(第二次呼叫), 所以次數是1, 參數是"a",123
            compare(spy3.count, 1);
            args = spy3.signalArguments[0];
            compare(args[0], "a");
            compare(args[1], 123);

            // 以上只是一個極端的例子, 原則上一個測項只能測一件事,
            // 接著往下看相同的檢查用新方法是如何
        }
    }

    TestCase {
        when: windowShown
        name: "Similar with google mock"

        MockComponent {
            id: mockFoo

            Signal { name: "signal1" }
            Signal { name: "signal2"; parameterNames: ['v1', 'v2'] }

            Function { name: "func1" }
            Function { name: "func2"; parameterNumber: 2 }
        }

        function init() {
            // 記得是傳instance
            logic.foo = mockFoo.instance();
        }

        function cleanup() {
            // 最後要呼叫verify, 除了跟舊方法有reset mock object的功能外, 還會執行檢查的動作
            mockFoo.verify();
        }

        function test_checkAll() {
            // arrange
            /// signal1會被呼叫2次
            mockFoo.expectCall("signal1").times(2);

            /// signal2當參數是"a",123時會被忽叫一次
            mockFoo.expectCall("signal2", "a", 123);

            /// signal2當參數是"b",234時會被忽叫一次
            mockFoo.expectCall("signal2", "b", 234);

            /// func1會被忽叫兩次, 第一次回傳true, 第二次回傳false
            mockFoo.expectCall("func1").return(true).return(false);

            /// func2會被忽叫一次, 參數是"a",123
            /// 如果需要, 當此func2被呼叫到後, 可以利用action帶入的functor做額外的處理
            mockFoo.expectCall("func2", "a", 123).action(function(parameters){
                console.log(parameters); // parameters會是["a", 123]
                // do nothing
            });
            /// [optional] 可額外檢查func2當參數是"b",234時, 是否真的沒有被呼叫到
            mockFoo.expectCall("func2", "b", 234).times(0);

            // action
            logic.testMethod("a", 123);
            logic.testMethod("b", 234);

            // 如果看到這還有興趣的話, 可以打開tst_MockComponentDoc.qml看完整的使用方法跟文件
        }
    }
}
