import QtQuick 2.0
import QtTest 1.1
import "."
import "./js/ExpectedObject.js" as ExpectedObject
import "./js/UninterestingObject.js" as UninterestingObject
import "./js/underscore.js" as Underscore

Item {
    id: root

    default property alias declarationList: core.declarationList
    property bool strict: false // if true, test case will failure when warning occur
    readonly property string _: "__dont_care__"

    Component.onCompleted: {
        var codeSnippet = "";
        for (var i = 0; i < declarationList.length; i++) {
            codeSnippet += declarationList[i].createSnippet() + "\n";
        }
        core.mockObject = Qt.createQmlObject(core.template.arg(codeSnippet), root);
        core.initProperties();
    }

    TestUtil { id: testUtil }

    TestResult { id: testResults }

    QtObject {
        id: injection

        function checkCall() {
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
                var targetCallerInfo = arguments[1];
                core.uninterestingObjects.push(new UninterestingObject.UninterestingObject(name, parameters, targetCallerInfo));
            }

            return returnVal;
        }
    }

    QtObject {
        id: core
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

    function verify(expectedResult) {
        var expectedResultTmp = typeof expectedResult === "undefined" ? ExpectedResult.success : expectedResult;
        core.expectedObjects.forEach(function(obj){
            var valid = false;
            if (expectedResultTmp === ExpectedResult.success) {
                valid = obj.success();
            }
            else {
                valid = obj.fail();
            }

            if (!valid)
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

        // clean all
        core.expectedObjects = [];
        core.uninterestingObjects = [];
        core.initProperties();
    }
}
