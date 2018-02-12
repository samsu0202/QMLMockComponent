import QtQuick 2.0

Item {
    property var foo: null

    Connections {
        target: foo
        ignoreUnknownSignals: true

        onSignal2 : {
            if (foo.func1() === true) {
                foo.func2(v1, v2);
            }
        }
    }

    function testMethod(v1, v2) {
        foo.signal1();
        foo.signal2(v1, v2);
    }
}
