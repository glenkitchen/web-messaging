describe('Messager', () => {

    jasmine.DEFAULT_TIMEOUT_INTERVAL = 1000;

    let msgr;
    let verb;
    let id;
    let date;
    let type;
    let source;
    let payload;
    let message;
    let structure;

    beforeEach(() => {

        msgr = new Messager({
            targetWindow: window.parent,
            targetOrigin: '*',
            messageSource: source,
            mustLogError: false,
            mustLogVerbose: false
        });

        verb = 'TESTVERB';
        id = '123';
        date = new Date(2018, 1, 1);
        type = MessageType.Response;
        source = 'TestSource';
        payload = { test: 'abc' };

        const data = JSON.stringify({
            verb: verb,
            id: id,
            date: date,
            type: type,
            source: source,
            payload: payload
        });
        message = {
            origin: '*',
            data: data
        };

        structure = {
            test: 'string',
            subObject: {
                testBoolean: 'boolean',
                testNumber: 'number',
                testString: 'string'
            }
        };

        spyOn(msgr, 'createGuid').and.returnValue(id);

    })

    it('sendMessage called without a verb throws error', () => {
        expect(() => { msgr.sendMessage(null) })
            .toThrowError('Invalid verb parameter in sendMessage');
    });
    
    it('sendMessage creates a promise function', () => {
        spyOn(msgr, 'createPromiseFunction');

        msgr.sendMessage(verb, payload);

        expect(msgr.createPromiseFunction).toHaveBeenCalled();
    });

    it('sendMessage creates a message', () => {
        spyOn(msgr, 'createMessage');

        msgr.sendMessage(verb, payload);

        expect(msgr.createMessage).toHaveBeenCalledWith(verb, id, MessageType.Request, payload, null);
    });

    it('sendMessage posts a message', () => {
        spyOn(msgr, 'createMessage').and.returnValue(message);
        spyOn(msgr, 'postMessage');

        msgr.sendMessage(verb, payload);

        expect(msgr.postMessage).toHaveBeenCalledWith(message);
    });

    it('sendMessage returns a Promise', () => {
        expect(msgr.sendMessage(verb, payload)).toEqual(jasmine.any(Promise));
    });

    it('validateMessage called without a structure should return no errors', () => {
        const errors = msgr.validateMessage(message, null);

        expect(errors.length).toEqual(0);
    });

    it('validateMessage with a missing property should return error', () => {
        const message = {
            payload: 'abc'
        };
        const structure = {
            mandatory: 'string'
        };

        const errors = msgr.validateMessage(message, structure);

        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain('Validate Message. Missing message property mandatory');
    });

    it('validateMessage with an invalid array value should return error', () => {
        const message = {
            type: 'REQUESt'
        };
        const structure = {
            type: ['REQUEST', 'RESPONSE']
        };

        const errors = msgr.validateMessage(message, structure);

        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain(
            'Validate Message. Message property type with value REQUESt does not exist in array [REQUEST,RESPONSE]');
    });

    it('validateMessage with an invalid type should return error', () => {
        const message = {
            payload: 'abc'
        };
        const structure = {
            payload: 'number'
        };

        const errors = msgr.validateMessage(message, structure);

        expect(errors.length).toEqual(1);
        expect(errors[0]).toContain('Validate Message. Message property payload is a string instead of a number');
    });

    it('validateMessage with invalid sub-object properties should return errors', () => {
        const message = {
            test: 'abc',
            subObject: {
                testBoolean: 'true',
                testNumber: '123',
                testString: 'def'
            }
        };

        const errors = msgr.validateMessage(message, structure);

        expect(errors.length).toEqual(2);
        expect(errors[0]).toContain('Validate Message. Message property testBoolean is a string instead of a boolean');
        expect(errors[1]).toContain('Validate Message. Message property testNumber is a string instead of a number');
    });

    it('validateMessage with valid properties should return no errors', () => {
        const message = {
            test: 'abc',
            subObject: {
                testBoolean: true,
                testNumber: 123,
                testString: 'def'
            }
        };

        const errors = msgr.validateMessage(message, structure);

        expect(errors.length).toEqual(0);
    });

    it('receiveMessage with no MessageEvent throws error', () => {
        expect(() => { msgr.receiveMessage(null) })
            .toThrowError('Invalid MessageEvent. The MessageEvent is falsy.');
    });

    it('receiveMessage with no MessageEvent origin throws error', () => {
        expect(() => { msgr.receiveMessage({}) })
            .toThrowError('Invalid MessageEvent. The MessageEvent has no origin.');
    });

    it('receiveMessage with no MessageEvent data throws error', () => {
        expect(() => {
            msgr.receiveMessage({ origin: '*' })
        }).toThrowError('Invalid MessageEvent. The MessageEvent has no data.');
    });

    it('receiveMessage with another origin does not process message', () => {
        spyOn(msgr, 'logVerbose');
        spyOn(msgr, 'createMessageKey');
        const msg = {
            origin: 'anotherorigin ',
            data: {}
        }

        msgr.receiveMessage(msg);

        expect(msgr.logVerbose).toHaveBeenCalled();
        expect(msgr.createMessageKey).not.toHaveBeenCalled();
    });

    it('receiveMessage with invalid JSON data throws error', () => {
        spyOn(msgr, 'logError');

        expect(() => msgr.receiveMessage({
            origin: '*',
            data: {}
        })).toThrowError('SyntaxError: Unexpected token o in JSON at position 1');
    });

    it('receiveMessage with no id logs error', () => {
        spyOn(msgr, 'logError');

        const data = JSON.stringify({ verb: verb });
        msgr.receiveMessage({
            origin: '*',
            data: data
        })

        expect(msgr.logError).toHaveBeenCalledWith([
            'Validate Message. Missing message property id',
            'Validate Message. Missing message property date',
            'Validate Message. Missing message property type',
            'Validate Message. Missing message property source',
            'Validate Message. Missing message property payload']);
    });

    it('receiveMessage creates a message key', () => {
        spyOn(msgr, 'createMessageKey');

        msgr.receiveMessage(message);

        expect(msgr.createMessageKey).toHaveBeenCalledWith(verb, MessageType.Response);
    });

    it('receiveMessage with REQUEST type invokes request callback method', () => {
        spyOn(msgr, 'invokeRequestCallback');
        const data = JSON.stringify({
            verb: verb,
            id: id,
            date: date,
            type: MessageType.Request,
            source: source,
            payload: payload
        });
        const message = {
            origin: '*',
            data: data
        };
        msgr.receiveMessage(message);

        expect(msgr.invokeRequestCallback).toHaveBeenCalled();
    });

    it('receiveMessage with RESPONSE type invokes response promise', () => {
        spyOn(msgr, 'invokeResponsePromise');

        msgr.receiveMessage(message);

        expect(msgr.invokeResponsePromise).toHaveBeenCalledWith(message, null);
    });
});