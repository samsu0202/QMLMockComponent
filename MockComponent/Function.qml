import QtQuick 2.0
import "."

BaseDeclaration {
    type: DeclareType.functionType
    property int parameterNumber: 0

    QtObject {
        id: core

        function genParameterNameList() {
            var parameters = [];
            for (var i = 0; i < parameterNumber; i++) {
                parameters.push("v%1".arg(i));
            }

            return "%1".arg(parameters.join(", "));
        }
    }

    function createSnippet() {
        var funcParameterList = core.genParameterNameList();
        if (funcParameterList.length > 0) {
            return "function %1(%2){ return injection.checkCall('%1', {file: testUtil.callerFile(),line: testUtil.callerLine()}, %2); }".arg(name).arg(funcParameterList);
        }
        else {
            return "function %1(){ return injection.checkCall('%1', {file: testUtil.callerFile(),line: testUtil.callerLine()}); }".arg(name);
        }
    }
}
