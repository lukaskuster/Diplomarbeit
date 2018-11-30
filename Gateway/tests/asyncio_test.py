# Run task in an task concurently and except exeptions / get return values
import asyncio
import attr


async def task1():
    print("Task1")
    await asyncio.sleep(0.5)


async def task2():
    for i in range(5):
        print("Task2")
        await asyncio.sleep(0.1)
    return None, 3


def done_callback(res):
    print(res.result())


async def main_task():
    task: asyncio.Task = None
    for i in range(10000):
        if i == 5:
            task = asyncio.ensure_future(task2())
            task.add_done_callback(done_callback)

        await asyncio.wait([task1()])


@attr.s
class X:
    a = attr.ib()
    b = attr.ib(default=None)


if __name__ == '__main__':
    asyncio.get_event_loop().run_until_complete(main_task())
    a = X(5)
    b = X(5, 'a')
    print(attr.asdict(a))
    print(attr.asdict(b))