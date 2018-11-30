import sim800.parser as parser


if __name__ == '__main__':
    print(parser.NetworkStatusParser.parse(['+CREG: 2,1']))
    print(parser.NetworkStatusParser.parse(['+CREG: 2,1,"lac","ci"']))
    print(parser.IMEIParser.parse(['990000862471854']))
    print(parser.IMSIParser.parse(['23211892349998423']))
    print(parser.PinStatusParser.parse(['CPIN: READY']))
    print(parser.SignalQualityParser.parse(['+CSQ: 31,5']))
    print(parser.SubscriberNumberParser.parse(['+CNUM: ,"+436503333997",2,324,1']))
    print(parser.SubscriberNumberParser.parse(['+CNUM: 22,"+436503333997",2']))
    print(parser.SMSListParser.parse(
        ['+CMGL: 1,"REC READ","+436503333997",,"07/05/01,08:00:15+32"',
         'First Test Message',
         '+CMGL: 2,"REC UNREAD","+436503333997",,"07/05/01,08:00:16"',
         'Second Message',
         '+CMGL: 3,"STO SENT","+436503333997","Hans"',
         'Last Message!']
    ))

