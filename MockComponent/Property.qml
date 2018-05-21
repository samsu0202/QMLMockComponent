import QtQuick 2.0
import "."

BaseDeclaration {
    type: DeclareType.propertyType
    property var initialValue

    Item {
        id: checkExistPropertyObj
    }

    function createSnippet() {
        if (checkExistPropertyObj.hasOwnProperty(name))
        {
            return "function mock_initial_property_%1(value){ %1=value; }".arg(name);
        }
        else
        {
            return "property var %1;function mock_initial_property_%1(value){ %1=value; }".arg(name);
        }
    }
}
