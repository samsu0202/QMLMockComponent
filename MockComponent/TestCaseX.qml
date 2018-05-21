import QtQuick 2.0
import QtTest 1.1

TestCase {

    signal beginTestCase()
    signal endTestCase()
    objectName: "__TEST_CASEX__"

    function qtest_runFunction(prop, arg) {
        beginTestCase()
        qtest_runInternal("init")
        if (!qtest_results.skipped) {

            qtest_runInternal(prop, arg)
            qtest_results.finishTestData()
            endTestCase()
            qtest_runInternal("cleanup")
            qtest_results.finishTestDataCleanup()
            // wait(0) will call processEvents() so objects marked for deletion
            // in the test function will be deleted.
            wait(0)
        }
    }
}
