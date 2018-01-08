describe('Messager', function () {
    var msgr;
    var verb;
    var id;
    var date;
    var source;
    var payload;
    var simpleMessage;
    var fullMessage;
    beforeEach(function () {
        msgr = new Messager({
            targetWindow: window.parent,
            targetOrigin: '*',
            messageSource: source,
            mustLogInfo: false,
            mustLogError: false
        });
        verb = 'TESTVERB';
        id = '123';
        date = new Date(2018, 1, 1);
        source = 'TestSource';
        payload = { test: 'abc' };
        simpleMessage = {
            payload: 'abc'
        };
        fullMessage = {
            origin: '*',
            data: {
                verb: verb,
                id: id,
                date: date,
                source: source,
                payload: payload
            }
        };
    });
    it('sendMessage without verb throws error', function () {
        expect(function () { msgr.sendMessage(null); })
            .toThrowError('Invalid verb parameter');
    });
    it('sendMessage creates a Guid', function () {
        spyOn(msgr, 'createGuid');
        msgr.sendMessage(verb, payload);
        expect(msgr.createGuid).toHaveBeenCalledWith();
    });
    it('sendMessage creates a message', function () {
        spyOn(msgr, 'createGuid').and.returnValue(id);
        spyOn(msgr, 'createMessage');
        msgr.sendMessage(verb, payload);
        expect(msgr.createMessage).toHaveBeenCalledWith(verb, id, MessageType.Request, payload);
    });
    it('sendMessage creates a promise function', function () {
        spyOn(msgr, 'createPromiseFunction');
        msgr.sendMessage(verb, payload);
        expect(msgr.createPromiseFunction).toHaveBeenCalled();
    });
    it('sendMessage posts a message', function () {
        spyOn(msgr, 'createMessage').and.returnValue(simpleMessage);
        spyOn(msgr, 'postMessage');
        msgr.sendMessage(verb, payload);
        expect(msgr.postMessage).toHaveBeenCalledWith(simpleMessage);
    });
    it('sendMessage returns a Promise', function () {
        expect(msgr.sendMessage(verb, payload)).toEqual(jasmine.any(Promise));
    });
    it('validateMessage with a missing property should return error', function () {
        var structure = {
            mandatory: 'string'
        };
        var errors = msgr.validateMessage(simpleMessage, structure);
        //console.log(errors);
        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain('Missing message property mandatory');
    });
    it('validateMessage with an invalid type should return error', function () {
        var structure = {
            payload: 'number'
        };
        var errors = msgr.validateMessage(simpleMessage, structure);
        //console.log(errors);
        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain('Message property payload is a string instead of a number');
    });
    it('validateMessage with an invalid array value should return error', function () {
        var message = {
            type: 'REQUESt'
        };
        var structure = {
            type: ['REQUEST', 'RESPONSE']
        };
        var errors = msgr.validateMessage(message, structure);
        //console.log(errors);
        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain('Message property type with a value of REQUESt is not a valid value for REQUEST,RESPONSE');
    });
    it('validateMessage with an invalid sub-object properties should return error', function () {
        var message = {
            test: 'abc',
            subObject: {
                testBoolean: 'true',
                testNumber: '123',
                testString: 'def',
                testFunkyType: 'xyz'
            }
        };
        var structure = {
            test: 'string',
            subObject: {
                testBoolean: 'boolean',
                testNumber: 'number',
                testString: 'string',
                testFunkyType: null
            }
        };
        var errors = msgr.validateMessage(message, structure);
        // console.log(errors);
        expect(errors.length).toEqual(2);
        expect(errors[0]).toContain('Message property testBoolean is a string instead of a boolean');
        expect(errors[1]).toContain('Message property testNumber is a string instead of a number');
    });
    it('receiveMessage with no message throws error', function () {
        expect(function () { msgr.receiveMessage(null); })
            .toThrowError('Invalid message received');
    });
    it('receiveMessage with no origin throws error', function () {
        expect(function () { msgr.receiveMessage(simpleMessage); })
            .toThrowError('The message has no origin');
    });
    it('receiveMessage with no data throws error', function () {
        expect(function () {
            msgr.receiveMessage({
                origin: '*'
            });
        }).toThrowError('The message has no data');
    });
    it('receiveMessage with no verb throws error', function () {
        expect(function () {
            msgr.receiveMessage({
                origin: '*',
                data: {}
            });
        }).toThrowError('The message has no verb');
    });
    it('receiveMessage with no id throws error', function () {
        expect(function () {
            msgr.receiveMessage({
                origin: '*',
                data: {
                    verb: verb
                }
            });
        }).toThrowError('The message has no id');
    });
    it('receiveMessage with REQUEST message does not invoke promise function', function () {
        spyOn(msgr, 'invokePromiseFunction');
        var msg = fullMessage;
        fullMessage.data.type = MessageType.Request;
        msgr.receiveMessage(msg);
        expect(msgr.invokePromiseFunction).not.toHaveBeenCalled();
    });
    // it('receiveMessage rejects promise', () => {        
    // });
    it('receiveMessage resolves promise', function () {
        spyOn(msgr, 'createGuid').and.returnValue(id);
        spyOn(msgr, 'invokePromiseFunction');
        var msg = fullMessage;
        fullMessage.data.type = MessageType.Response;
        msgr.sendMessage(verb, payload)
            .then(function (data) { return console.log(data); });
        msgr.receiveMessage(msg);
        expect(msgr.invokePromiseFunction).toHaveBeenCalled();
    });
    // it('receiveMessage sends error message', () => {        
    // });
    // it('receiveMessage does not invoke received callback', () => {        
    // });
    // it('receiveMessage invokes received callback', () => {        
    // });
});
//# sourceMappingURL=messager.spec.js.map