import QtQuick 2.0
import "."

BaseDeclaration {
    type: DeclareType.signalType
    property var parameterNames: []

    QtObject {
        id: core

        function genSignalDefinition() {
            var typeNames = [];
            parameterNames.forEach(function(name){
                typeNames.push("variant %1".arg(name));
            });
            return "signal %1(%2);".arg(name).arg(typeNames.join(", "));
        }

        function capitalizeFirstLetter(string) {
            return string.charAt(0).toUpperCase() + string.slice(1);
        }


        function genSignalHandler() {
            var handlerCode = ""
            if (parameterNames.length > 0) {
                handlerCode = "injection.checkCall('%1', {file: testUtil.callerFile(),line: testUtil.callerLine()}, %2);".arg(name).arg(parameterNames.join(", "));
            }
            else {
                handlerCode = "injection.checkCall('%1', {file: testUtil.callerFile(),line: testUtil.callerLine()});".arg(name)
            }

            return "on%1:{ %2 }".arg(core.capitalizeFirstLetter(name)).arg(handlerCode)
        }
    }

    function createSnippet() {
        var signalDef = core.genSignalDefinition();
        var signalHandler = core.genSignalHandler();

        return signalDef + signalHandler;
    }
}
