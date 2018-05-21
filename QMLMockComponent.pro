TEMPLATE = app
TARGET = testQMLMockComponent
CONFIG += warn_on qmltestcase
SOURCES += main.cpp

DISTFILES += \
    Logic.qml \
    MockComponent/qmldir \
    MockComponent/BaseDeclaration.qml \
    MockComponent/DeclareType.qml \
    MockComponent/ExpectedResult.qml \
    MockComponent/Function.qml \
    MockComponent/MockComponent.qml \
    MockComponent/MockComponentX.qml \
    MockComponent/Property.qml \
    MockComponent/Signal.qml \
    MockComponent/js/ExpectedObject.js \
    MockComponent/js/UninterestingObject.js \
    MockComponent/js/underscore.js \
    UT/tst_Logic.qml \
    UT/tst_MockComponentDoc.qml \
    UT/tst_MockComponentXDoc.qml
