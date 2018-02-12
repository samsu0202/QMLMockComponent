function UninterestingObject(name, parameters, callerInfo) {
    // private
    var _name = name;
    var _parameters = parameters;
    var _callInfo = callerInfo;
    var _errorMessage = "";

    // public
    this.getCallerInfo = function() {
        return _callInfo;
    }

    this.errorMessage = function() {
        return "Uninteresting mock call - returning undefined.\n   call: %1(%2)".arg(_name).arg(parameters.join(", "));
    }
}

