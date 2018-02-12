import QtQuick 2.0
import "."

Item {
    property int type: DeclareType.noneType
    property string name: ""

    function createSnippet(injectionName) {
        return "";
    }
}
