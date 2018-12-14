import threading
import time


class Task:
    def __init__(self, interval, func, *args, **kwargs):
        self.func = func
        self.args = args
        self.kwargs = kwargs
        self.interval = interval
        self.time = time.time()

    def check_time(self):
        if time.time() - self.time > self.interval:
            return True
        else:
            return False

    def execute(self):
        self.time = time.time()
        self.func(*self.args, **self.kwargs)


class Scheduler(threading.Thread):
    def __init__(self, sleep=1):
        super().__init__()
        self.tasks = []
        self.sleep = sleep
        self._running = threading.Event()
        self.start()

    def stop(self):
        self._running.set()

    def stop_task(self, task):
        self.tasks.remove(task)

    def run(self):
        while not self._running.is_set():
            for task in self.tasks:
                if task.check_time():
                    task.execute()

            time.sleep(self.sleep)

    def schedule_task(self, task):
        self.tasks.append(task)

    def schedule(self, interval, func, *args, **kwargs):
        self.tasks.append(Task(interval, func, *args, **kwargs))