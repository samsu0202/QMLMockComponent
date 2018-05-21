import QtQuick 2.7
import QtTest 1.1
import "../MockComponent"

Item {
    width: 100
    height: 100

    Timer {
        id: delayAction

        property var func: null
        onTriggered: {
            func();
        }

        function execute(func, timeout) {
            interval = timeout;
            delayAction.func = func;
            start();
        }
    }

    // MockComponent必須搭配TestCaseX使用
    TestCaseX {
        when: windowShown
        name: "How does MockComponent work"

        property var mockObj: mockComp.instance()

        // *************************************************************************
        // 此mock是依照google test為原型針對function跟signal設計的,
        // 主要功能包含:
        // 1. expected call(name, parameters...)
        // 2. times(int)
        // 3. return(variant) (這功能是我為什麼要做這個mock的主要動機)
        // 4. action(functor)
        // 5. timeout(milliseconds)
        // 6. try expected call(name, parameters...)
        // 7. uninteresting call warning detection
        // 8. ignoreCallFromTest property
        //
        // ps. property目前沒想到要怎麼用, 所以只有幫忙在mock instance產生property而已,
        //     所有檢查功能都沒有作用, 之後有想到要怎麼套用在mock上再設計吧
        // *************************************************************************
        MockComponent {
            id: mockComp

            ignoreCallFromTest: false

            // 沒有參數的signal
            Signal { name: "signal1" }
            // 有兩個參數的signal, 參數名稱分別是 v1, v2
            Signal { name: "signal2"; parameterNames: ['v1', 'v2'] }

            // 沒有參數的function
            Function { name: "func1" }
            // 有兩個參數的function
            Function { name: "func2"; parameterNumber: 3 }

            // variant type的property, 初始值是"this is initial value"
            Property { name: "pro1"; initialValue: "this is initial value" }
            // 新增已經存在的property ok
            Property { name: "visible"; initialValue: false }
        }

        function cleanup() {
            // 這裡不需要再呼叫verify,
            // 而是MockComponent會自行判斷甚麼時候要呼叫verify, 因此必須搭配TestCaseX使用
        }

        // *************************************************************************
        // expectCall(name, parameters...)
        // 針對signal, function搭配參數做預期呼叫的偵測, 預設是一次
        // parameters的部分是用物件比較, 所以針對JavaScript的物件基本上都可比較, 例如Date
        // *************************************************************************
        function test_expectCall() {
            mockComp.expectCall("signal1");
            mockComp.expectCall("func2", "a", 1, new Date("2018/02/10 09:29:53"));

            // 模擬mock object signal跟function的呼叫
            mockObj.signal1();
            mockObj.func2("a", 1, new Date("2018/02/10 09:29:53"));
        }

        // *************************************************************************
        // 利用times給定預期呼叫次數
        // *************************************************************************
        function test_times() {
            mockComp.expectCall("signal1").times(2);

            // 模擬mock object signal跟function的呼叫
            mockObj.signal1();
            mockObj.signal1();
        }

        // *************************************************************************
        // 利用times給定-1, 可以不care預期呼叫次數, 跟google mock WillRepeatedly很像
        // *************************************************************************
        function test_dont_care_times() {
            mockComp.expectCall("signal1").times(-1);

            // 模擬mock object signal跟function的呼叫
            mockObj.signal1();
            mockObj.signal1();
            mockObj.signal1();
            mockObj.signal1();
        }

        // *************************************************************************
        // MockComponent有提供"_", 可以不care參數的部分
        // *************************************************************************
        function test_dont_care_parameters() {
            mockComp.expectCall("signal2", mockComp._, mockComp._).times(2);

            // 模擬mock object signal跟function的呼叫
            mockObj.signal2(123, "aaa");
            mockObj.signal2("bbb", 234);
        }

        // *************************************************************************
        // 利用return給定預期呼叫function的回傳值
        // *************************************************************************
        function test_return() {
            mockComp.expectCall("func1").return(123);

            // 模擬mock object signal跟function的呼叫
            compare(mockObj.func1(), 123)
        }

        // *************************************************************************
        // 相同function or signal, 可針對不同參數return不同的回傳值
        // *************************************************************************
        function test_return_different_value_based_on_parameters() {
            // 相同signal, 會針對不同的參數找到對應的return value
            mockComp.expectCall("func2", 123, "a", mockComp._).return(1);
            mockComp.expectCall("func2", 234, "b", mockComp._).return(2);

            // 模擬mock object signal跟function的呼叫
            compare(mockObj.func2(234, "b", ""), 2);
            compare(mockObj.func2(123, "a", ""), 1);
        }

        // *************************************************************************
        // return的次數也可以當做預期呼叫次數
        // *************************************************************************
        function test_returnTimes() {
            // 下例func1預期呼叫兩次
            mockComp.expectCall("func1").return(123).return(234);

            // 模擬mock object signal跟function的呼叫
            compare(mockObj.func1(), 123);
            compare(mockObj.func1(), 234);
        }

        // *************************************************************************
        // 利用times給定return的次數
        // *************************************************************************
        function test_use_times_and_return() {
            // 下例func1預期呼叫兩次, 每次都return 123
            mockComp.expectCall("func1").times(2).return(123);

            /* 上面檢查等同於下面
            mockComp.expectCall("func1").return(123).return(123);
            */

            // 模擬mock object signal跟function的呼叫
            compare(mockObj.func1(), 123);
            compare(mockObj.func1(), 123);
        }

        // *************************************************************************
        // 利用action(functor), 當expected function or signal被呼叫的時候,
        // 可以呼叫你傳進來的functor.
        // 其中functor的參數是被忽叫function或signal的參數"array"
        // *************************************************************************
        function test_action() {
            // signal2被呼叫到時會順便執行action帶入的functor
            var expectArgs = [];
            var result = false;
            mockComp.expectCall("signal2", mockComp._, mockComp._)
                .action(function(parameters){
                    // 範例, 在functor裡面check被呼叫signal的參數, 或是把參數存起來之類的
                    result = (parameters[0] === 123) && (parameters[1] === "aaa");
                    expectArgs.push(parameters[0]);
                    expectArgs.push(parameters[1]);
                });

            // 模擬mock object signal跟function的呼叫
            mockObj.signal2(123, "aaa");
            compare(result, true);

            compare(expectArgs[0], 123);
            compare(expectArgs[1], "aaa");
        }

        // *************************************************************************
        // 利用times給定action的次數
        // *************************************************************************
        function test_use_times_and_action() {
            // 下例signal1預期呼叫兩次, 每次都會順便呼叫functor
            var doFunctorCount = 0;
            mockComp.expectCall("signal1")
                .times(2)
                .action(function(parameters){
                    doFunctorCount++
                });

            /* 上面檢查等同於下面
            mockComp.expectCall("signal1")
                .action(function(parameters){
                    doFunctorCount++
                })
                .action(function(parameters){
                    doFunctorCount++
                });
            */

            // 模擬mock object signal跟function的呼叫
            mockObj.signal1();
            mockObj.signal1();
            compare(doFunctorCount, 2);
        }

        // *************************************************************************
        // 利用timeout給定timeout的時間 (milliseconds)
        // *************************************************************************
        function test_timeout() {
            mockComp.expectCall("signal1").timeout(5000);

            // 模擬mock object signal跟function的呼叫
            delayAction.execute(function(){
                mockObj.signal1();
            }, 100);
        }

        // *************************************************************************
        // tryExpectCall(name, parameters...)
        // 針對signal, function搭配參數做5000 milliseconds內預期呼叫的偵測, 預設是一次
        // parameters的部分是用物件比較, 所以針對JavaScript的物件基本上都可比較, 例如Date
        // 等同於expectCall(name, parameters...).timeout(5000)
        // *************************************************************************
        function test_tryExpectCall() {
            mockComp.tryExpectCall("signal1");
            // 等同於
            // mockComp.expectCall("signal1").timeout(5000);

            // 模擬mock object signal跟function的呼叫
            delayAction.execute(function(){
                mockObj.signal1();
            }, 100);
        }

        // *************************************************************************
        // 針對uninteresting call會發出warning
        // 可以設定MockComponent的strict property成true, warning也會被當作fail
        // *************************************************************************
        function test_uninteresting_call_detection() {
            // 模擬mock object signal跟function的呼叫
            mockObj.signal1();
            mockObj.func2(234, 123, "aaa");

            /* 預期輸出
            WARNING: qmltestrunner::How does MockComponent work::test_uninteresting_call_detection() Uninteresting mock call - returning undefined.
               call: signal1()
            {PATH}\tst_MockComponentDoc.qml(203) : failure location
            WARNING: qmltestrunner::How does MockComponent work::test_uninteresting_call_detection() Uninteresting mock call - returning undefined.
               call: func2(234, 123, aaa)
            {PATH}\tst_MockComponentDoc.qml(204) : failure location

            ps. 此地是因為我的呼叫端也是在test case裡面, 不然正常是會列出被測程式的檔案跟行號
            */
        }

        // *************************************************************************
        // 針對property的部分, 並無實作任何檢查, 只是幫忙在mock instance產生property以供使用
        // 初始值的部分, 會在每次verify後幫忙還原
        // *************************************************************************
        function test_property() {
            // 以下只是驗證產生出來的property功能可以正常運作
            var propertyChangedWork = false;
            var propertyChangedValue = "";
            mockObj.pro1Changed.connect(function() {
                propertyChangedWork = true;
                propertyChangedValue = mockObj.pro1;
            })

            compare(mockObj.pro1, "this is initial value");
            mockObj.pro1 = 1234;
            compare(propertyChangedWork, true);
            compare(propertyChangedValue, 1234);
        }

        // *************************************************************************
        // 新增已經存在的property也ok
        // *************************************************************************
        function test_exist_property() {
            compare(mockObj.visible, false);
        }
    }

    TestCaseX {
        name: "How ignoreCallFromTest work"
        when: windowShown
        MockComponent {
            id: mockCompIgnore

            Signal { name: "signal1" }
        }

        // *************************************************************************
        // ignoreCallFromTest設成true,
        // 所有在test file裡面呼叫mock instance的function跟signal都會被忽略掉
        // *************************************************************************
        function test_ignoreCallFromTest() {
            // 以下即使不呼叫expectCall也不會出現warning
            mockCompIgnore.ignoreCallFromTest = true;
            mockCompIgnore.instance().signal1();

            /* 以下會出現warning
            WARNING: qmltestrunner::How ignoreCallFromTest work::test_ignoreCallFromTest() Uninteresting mock call - returning undefined.
               call: signal1()
            */
            mockCompIgnore.ignoreCallFromTest = false;
            mockCompIgnore.instance().signal1();
        }
    }

//    TestCaseX {
//        when: windowShown
//        name: "How failure look like"
//        property var mockObjFail: mockCompFail.instance()

//        MockComponent {
//            id: mockCompFail

//            Signal { name: "signal1" }
//            Signal { name: "signal2"; parameterNames: ['v1', 'v2'] }

//            Function { name: "func1" }
//            Function { name: "func2"; parameterNumber: 2 }

//            Property { name: "pro1"; initialValue: "this is initial value" }
//        }

//        // *************************************************************************
//        // 不合乎預期呼叫次數
//        // *************************************************************************
//        function test_wrong_times() {
//            mockCompFail.expectCall("signal1");

//            mockObjFail.signal1();
//            mockObjFail.signal1();
//            /* 預期輸出
//            FAIL!  : qmltestrunner::How is unit test failure::test_wrong_times() Compared values are not the same
//               Actual   (): 2
//               Expected (): 1
//            {PATH}\tst_MockComponentDoc.qml(263) : failure location
//            */
//        }

//        // *************************************************************************
//        // 參數不match導致不合乎預期呼叫次數
//        // *************************************************************************
//        function test_wrong_parameters_force_times_not_match() {
//            mockCompFail.expectCall("signal2", 123, "bbb");

//            mockObjFail.signal2(123, "aaa");
//            /* 預期輸出, 以下的意思就是signal2沒有收到預期參數是(123,"bbb")的呼叫, 反而另外接收到參數(123, aaa)的uninteresting call
//            FAIL!  : qmltestrunner::How is unit test failure::test_wrong_parameters_force_times_not_match() Compared values are not the same
//               Actual   (): 0
//               Expected (): 1
//            {PATH}\tst_MockComponentDoc.qml(279) : failure location
//            WARNING: qmltestrunner::How is unit test failure::test_wrong_parameters_force_times_not_match() Uninteresting mock call - returning undefine            d.
//               call: signal2(123, aaa)
//            {PATH}\tst_MockComponentDoc.qml(281) : failure location
//            */
//        }
//    }
}

