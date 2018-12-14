from gateway.utils import Scheduler, Task
import time


if __name__ == '__main__':

    s = Scheduler(sleep=0.1)

    @s.schedule(5)
    def sched_func():
        print(time.time())

    def test():
        print("Schedule", time.time())

    s.schedule_task(Task(3, test))