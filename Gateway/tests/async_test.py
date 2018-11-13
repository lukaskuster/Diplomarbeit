from sim800 import Sim800
import asyncio
import utils.logger
import threading

utils.logger.level = utils.Level.DEBUG


async def other():
    while True:
        await asyncio.sleep(3)
        print("Do other task async!")


async def get_network_status(s):
    event = await s.request_network_status()
    print(event.data)

if __name__ == '__main__':
    loop = asyncio.get_event_loop()

    sim = Sim800(debug=True)

    @sim.on('ring')
    async def ring():
        print(threading.current_thread().getName())

        event = await sim.hang_up_call()
        print(event)

    asyncio.ensure_future(other())
    loop.run_forever()
