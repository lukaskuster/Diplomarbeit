import threading
import time


class Task:
    """
    A task is a function that should get executed every x seconds.

    Use 'Scheduler' to schedule a task.
    """

    def __init__(self, interval, func, *args, **kwargs):
        """
        Construct a new 'Task' object.

        :param interval: indicates in which time interval the function should be called (in seconds)
        :param func: function that should be called
        :param args: args that get passed to the function
        :param kwargs: kwargs that get passed to the function
        """

        self.func = func
        self.args = args
        self.kwargs = kwargs
        self.interval = interval
        self.time = time.time()

    def check_time(self):
        """
        Check if the task is ready to be executed.

        :return: boolean that indicates if the task should be executed
        """

        if time.time() - self.time > self.interval:
            return True
        else:
            return False

    def execute(self):
        """
        Execute the function and reset the time.

        :return: nothing
        """

        self.time = time.time()
        self.func(*self.args, **self.kwargs)


class Scheduler(threading.Thread):
    """
    Schedules tasks in a new thead.
    """

    def __init__(self, sleep=1):
        """
        Construct a new 'Scheduler' object.

        :param sleep: indicates how long the scheduler sleeps after tasks are checked for execution
        """

        super().__init__()
        self.daemon = True
        self.tasks = []
        self.sleep = sleep
        self._running = threading.Event()
        self.start()

    def stop(self):
        """
        Stop the scheduler.

        :return: nothing
        """

        self._running.set()

    def stop_task(self, task):
        """
        Stop a task that is hold by the scheduler.

        :param task: 'Task' to stop
        :return: nothing
        """

        self.tasks.remove(task)

    def run(self):
        """

        :return:
        """
        while not self._running.is_set():
            for task in self.tasks:
                if task.check_time():
                    task.execute()

            time.sleep(self.sleep)

    def schedule_task(self, task):
        """
        Schedule a task.

        :param task:
        :return: nothing
        """

        self.tasks.append(task)

    def schedule(self, interval, func, *args, **kwargs):
        """
        Create a task from the given arguments and schedule it.
        Arguments are the same as in 'Task.init()'

        :param interval:
        :param func:
        :param args:
        :param kwargs:
        :return: nothing
        """
        self.tasks.append(Task(interval, func, *args, **kwargs))
