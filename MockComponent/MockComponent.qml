import QtQuick 2.0
import QtTest 1.1
import "."
import "./js/ExpectedObject.js" as ExpectedObject
import "./js/UninterestingObject.js" as UninterestingObject
import "./js/underscore.js" as Underscore

Item {
    id: root

    default property alias declarationList: core.declarationList
    property bool ignoreCallFromTest: true
    property bool strict: false // if true, test case will failure when warning occur
    readonly property string _: "__dont_care__"

    Component.onCompleted: {
        var codeSnippet = "";
        for (var i = 0; i < declarationList.length; i++) {
            codeSnippet += declarationList[i].createSnippet() + "\n";
        }
        core.mockObject = Qt.createQmlObject(core.template.arg(codeSnippet), root);
        core.initProperties();
        core.connectTestCaseXSignals();
    }

    TestUtil { id: testUtil }

    TestResult { id: testResults }

    QtObject {
        id: injection

        function checkCall() {
            if (!core.startDetect)
            {
                return core.getTestCaseFinalExpectedReturnValue(arguments[0]);
            }

            var targetCallerInfo = arguments[1];
            if (ignoreCallFromTest && targetCallerInfo.file.indexOf("tst_") >= 0) {
                return undefined;
            }

            var name = arguments[0];
            var parameters = core.arguments2Array(arguments, 2);
            var checkResult = false;
            var returnVal = undefined;
            for (var i = 0; i < core.expectedObjects.length; i++) {
                checkResult = core.expectedObjects[i].check(name, parameters);
                if (checkResult) {
                    returnVal = core.expectedObjects[i].getReturnValue();
                    var actionFunction = core.expectedObjects[i].getActionFunction();
                    if (actionFunction !== undefined && actionFunction !== null) {
                        actionFunction(parameters);
                    }

                    break;
                }
            }

            if (!checkResult) {
                // this call is not interest call
                core.uninterestingObjects.push(new UninterestingObject.UninterestingObject(name, parameters, targetCallerInfo));
            }

            return returnVal;
        }
    }

    QtObject {
        id: core
        property bool startDetect: false
        property list<BaseDeclaration> declarationList
        property string template: '
            import QtQuick 2.0;
            import QtTest 1.1
            Item {
                TestUtil { id: testUtil }
                %1
            }';
        property var mockObject: null
        property var expectedObjects: []
        property var uninterestingObjects: []

        function arguments2Array(arguments, start, length) {
            var argumentsArray = Array.prototype.slice.call(arguments);
            if (typeof start !== "undefined") {
                if (typeof length !== "undefined") {
                    return argumentsArray.slice(start, start + length);
                }
                else {
                    return argumentsArray.slice(start);
                }
            }
        }

        function initProperties() {
            for (var i = 0; i < declarationList.length; i++) {
                var declaration = declarationList[i];
                if (declaration.type !== DeclareType.propertyType) {
                    continue;
                }

                var propertyInitFunc = "mock_initial_property_%1".arg(declaration.name);
                core.mockObject[propertyInitFunc](declaration.initialValue);
            }
        }

        function createMockObject() {
            var codeSnippet = "";
            for (var i = 0; i < declarationList.length; i++) {
                codeSnippet += declarationList[i].createSnippet() + "\n";
            }
            core.mockObject = Qt.createQmlObject(core.template.arg(codeSnippet), root);
            core.initProperties();
        }

        function findRoot(object) {
            if (object.parent) {
                return findRoot(object.parent);
            }

            return object;
        }

        function findTestCaseObj(object, result) {
            if (object.objectName.indexOf("__TEST_CASEX__") === 0) {
                result.push(object);
            }

            for (var i = 0; i < object.children.length; i++) {
                findTestCaseObj(object.children[i], result);
            }
        }

        function connectTestCaseXSignals() {
            var testCaseObjs = [];
            findTestCaseObj(findRoot(root), testCaseObjs);
            if (testCaseObjs.length === 0) {
                testResults.fail("Can not find TestCaseX, MockComponent must to be used with TestCaseX.qml which in MockComponent folder", testUtil.callerFile(), testUtil.callerLine());
                return;
            }

            for (var i = 0; i < testCaseObjs.length; i++) {
                if (typeof testCaseObjs[i].beginTestCase !== "undefined") {
                    testCaseObjs[i].beginTestCase.connect(function(){
                        core.startDetect = true;
                    });
                }
                if (typeof testCaseObjs[i].endTestCase !== "undefined") {
                    testCaseObjs[i].endTestCase.connect(function(){
                        core.verify();
                    });
                }
            }
        }

        function getTestCaseFinalExpectedReturnValue(objectName)
        {
            var foundObj = Qt._.find(core.expectedObjects, function(obj){
                return obj.getName() === objectName;
            });

            if (foundObj)
            {
                return foundObj.getReturnValue();
            }

            return;
        }

        function verify() {
            if (!testResults.failed) {
                // if test case already failed, we ignore the checking or it will show too much error message
                core.expectedObjects.forEach(function(obj){
                    if (!obj.success(testResults))
                    {
                        var callerInfo = obj.getCallerInfo();
                        testResults.fail(obj.errorMessage(), callerInfo.file, callerInfo.line);
                    }
                });

                core.uninterestingObjects.forEach(function(obj){
                    var callerInfo = obj.getCallerInfo();
                    if (strict) {
                        testResults.fail(obj.errorMessage(), callerInfo.file, callerInfo.line);
                    }
                    else {
                        testResults.warn(obj.errorMessage(), callerInfo.file, callerInfo.line);
                    }
                });
            }

            // clean all
            core.startDetect = false;
            core.expectedObjects.length = 0;
            core.uninterestingObjects.length = 0;
            core.initProperties();
        }
    }

    function instance() {
        return core.mockObject;
    }

    function expectCall(name) {
        // can not extract to core or sub-function, otherwise file and line information will be incorrect
        var callerInfo = {
            file: testUtil.callerFile(),
            line: testUtil.callerLine()
        };
        // can not extract to core or sub-function, otherwise arguments will be incorrect
        var parameters = core.arguments2Array(arguments, 1);
        var expectedObj = new ExpectedObject.ExpectedObject(name, parameters, callerInfo, root._);
        core.expectedObjects.push(expectedObj);

        return expectedObj;
    }

    function tryExpectCall(name) {
        var defTimeout = 5000;
        // can not extract to core or sub-function, otherwise file and line information will be incorrect
        var callerInfo = {
            file: testUtil.callerFile(),
            line: testUtil.callerLine()
        };
        // can not extract to core or sub-function, otherwise arguments will be incorrect
        var parameters = core.arguments2Array(arguments, 1);
        var expectedObj = new ExpectedObject.ExpectedObject(name, parameters, callerInfo, root._);
        expectedObj.timeout(defTimeout);
        core.expectedObjects.push(expectedObj);

        return expectedObj;
    }
}
