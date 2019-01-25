from serial import Serial


if __name__ == '__main__':

    serial = Serial("/dev/serial0", 9600, timeout=1)

    try:
        while True:
            s = serial.readline()
            while s:
                print(s)
                s = serial.readline()

            d = input("Command: ")
            if d:
                d = d.replace('\r', '')
                d = d.replace('\n', '')
                e = d.encode() + b'\r\n'
                serial.write(e)

                s = serial.readline()
                while s:
                    print(s)
                    s = serial.readline()

    except KeyboardInterrupt:
        serial.close()
