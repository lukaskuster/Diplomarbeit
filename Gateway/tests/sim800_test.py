from gateway.io import Sim800, PINStatus
import sys
import asyncio


def check_error(event, message):
    if event.error:
        print(message)
        exit(-1)


async def test(number):
    sim = Sim800()
    event = await sim.request_pin_status()
    check_error(event, "Failed to request pin status!")
    pin_status = event.data

    if pin_status != PINStatus.Ready:
        print("Sim is locked!")
        code = input("Enter Code: ")
        code = code.replace("\n", "")
        code = code.replace("\r", "")

        event = await sim.enter_pin(code)
        check_error(event, "Failed to set pin code!")

    event = await sim.request_pin_status()
    check_error(event, "Failed to request pin status!")

    pin_status = event.data

    if pin_status != PINStatus.Ready:
        print("Sim still locked!")
        exit(-1)

    print("Sim is ready!")

    event = await sim.dial_number(number)
    check_error(event, "Failed to dial number!")

    print("Dialed number successfully!")

    await asyncio.sleep(10)

    event = await sim.hang_up_call()
    check_error(event, "Failed to hang up call!")

    sim.close()
    print("Working perfectly!")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Number as argument is required!")
        exit(-2)

    n = sys.argv[1]
    asyncio.get_event_loop().run_until_complete(test(n))
