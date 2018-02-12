.pragma library
Qt.include("./underscore.js")

function ExpectedObject(name, parameters, callerInfo, dontCareParaDef) {
    // ================ internal private ================
    var _name = name;
    var _parameters = parameters;
    var _callInfo = callerInfo;
    var _expectedTimes = 1;
    var _actualTimes = 0;
    var _errorMessage = "";
    var _returnList = [];
    var _invokeList = [];
    var _dontCareParaDef = dontCareParaDef;

    // ================ internal public ================
    this.getCallerInfo = function() {
        return _callInfo;
    }

    this.check = function(actualName, actualParameters) {
        if (_name !== actualName) {
            return false;
        }

        if (_parameters.length !== actualParameters.length) {
            return false;
        }

        for (var i = 0; i < _parameters.length; i++) {
            if (_parameters[i] === _dontCareParaDef) {
                continue;
            }

            if (!Qt._.isEqual(_parameters[i], actualParameters[i])) {
                return false;
            }

            /*if (_parameters[i] !== actualParameters[i]) {
                return false;
            }*/
        }

        _actualTimes++;
        return true;
    }

    this.success = function() {
        if (_expectedTimes < 0) {
            // don't care times
            return true;
        }

        var expectedTimes = Math.max(_expectedTimes, _returnList.length, _invokeList.length);
        var success = expectedTimes === _actualTimes;
        if (!success) {
            _errorMessage = "Compared values are not the same\n   Actual   (): %1\n   Expected (): %2".arg(_actualTimes).arg(expectedTimes);
        }

        return success;
    }

    this.fail = function() {
        var expectedTimes = Math.max(_expectedTimes, _returnList.length, _invokeList.length);
        var fail = expectedTimes !== _actualTimes;
        if (!fail) {
            _errorMessage = "Compared values are the same\n   Actual   (): %1\n   Expected (): %2".arg(_actualTimes).arg(expectedTimes);
        }

        return fail;
    }

    this.errorMessage = function() {
        return _errorMessage;
    }

    this.getReturnValue = function() {
        var retIdx = Math.min(_returnList.length - 1, _actualTimes - 1);
        return _returnList[retIdx];
    }

    this.getActionFunction = function() {
        var retIdx = Math.min(_invokeList.length - 1, _actualTimes - 1);
        return _invokeList[retIdx];
    }

    // ================ interface for unit test usage =================

    this.times = function(times) {
        _expectedTimes = times;
        return this;
    }

    this.return = function(value) {
        _returnList.push(value);
        return this;
    }

    this.action = function(func) {
        _invokeList.push(func);
        return this;
    }
}
