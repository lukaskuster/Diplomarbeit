import pigpio
import argparse


def generate_pwm(connection, frequency, duty_cycle, gpio_pin):
    if frequency > 30 * 10**6:
        raise ValueError('Frequency must be less than 30MHz!')

    if duty_cycle > 1 or duty_cycle < 0:
        raise ValueError('Duty cycle must be in range from 0 to 1!')

    if gpio_pin not in [12, 13, 18, 19, 40, 41, 45, 52, 53]:
        raise ValueError('GPIO is not a valid PWM pin!')

    duty_cycle = int(duty_cycle * 10**6)

    print('PWM Signal is initialized on pin {} with frequency of {}Hz and duty cycle of {}%'.format(gpio_pin, frequency, int(args.duty_cycle * 100)))

    error = connection.hardware_PWM(gpio_pin, frequency, duty_cycle)

    if error != 0:
        raise RuntimeError('Could not create pwm signal with error code: {}'.format(error))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--frequency', '-f', type=int, help='set pwm frequency (default: 1.024.000)', default=1.024 * 10**6)
    parser.add_argument('--duty-cycle', '-d', type=float, help='set duty cycle in percent [0-1] (default: 0.5)', default=0.5)
    parser.add_argument('--gpio', '-g', type=int, help='set gpio pin to output pwm signal (default: 18)', default=18)

    args = parser.parse_args()

    pi = pigpio.pi()

    if not pi.connected:
        raise ConnectionError('Could not connect to pigpio!')

    generate_pwm(pi, args.frequency, args.duty_cycle, args.gpio)

    try:
        while True:
            pass
    except KeyboardInterrupt:
        print('Stopping pwm signal!')
        pi.stop()


