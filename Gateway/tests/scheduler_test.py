from gateway.utils import Scheduler, Task
import time


if __name__ == '__main__':

    s = Scheduler(sleep=0.1)

    def test():
        print("Schedule", time.time())

    try:
        s.schedule_task(Task(3, test))
        s.join()
    except KeyboardInterrupt:
        s.stop()
