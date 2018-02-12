import QtQuick 2.0
import "."

BaseDeclaration {
    type: DeclareType.propertyType
    property var initialValue

    function createSnippet() {
        return "property var %1;function mock_initial_property_%1(value){ %1=value; }".arg(name);
    }
}
