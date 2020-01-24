## Speed Up Your Python Program With Concurrency



#### What Is Concurrency?

The dictionary definition of concurrency is simultaneous occurrence. In Python, the things that are occurring simultaneously are called by different names (thread, task, process) but at a high level, they all refer to a sequence of instructions that run in order. only `multiprocessing` actually runs these trains of thought at literally the same time. `Threading` and `asyncio` both run on a single processor and therefore only run one at a time. They just cleverly find ways to take turns to speed up the overall process. Even though they don’t run different trains of thought simultaneously, we still call this concurrency.

The way the threads or tasks take turns is the big difference between `threading` and `asyncio`. In `threading`, the operating system actually knows about each thread and can interrupt it at any time to start running a different thread. This is called pre-emptive multitasking since the operating system can pre-empt your thread to make the switch.

Pre-emptive multitasking is handy in that the code in the thread doesn’t need to do anything to make the switch. It can also be difficult because of that “at any time” phrase. This switch can happen in the middle of a single Python statement, even a trivial one like `x = x + 1`.

`Asyncio`, on the other hand, uses cooperative multitasking. The tasks must cooperate by announcing when they are ready to be switched out. That means that the code in the task has to change slightly to make this happen.

#### What Is Parallelism?

With `multiprocessing`, Python creates new processes. A process here can be thought of as almost a completely different program, though technically they’re usually defined as a collection of resources where the resources include memory, file handles and things like that. One way to think about it is that each process runs in its own Python interpreter.

Because they are different processes, each of your trains of thought in a multiprocessing program can run on a different core. Running on a different core means that they actually can run at the same time, which is fabulous. There are some complications that arise from doing this, but Python does a pretty good job of smoothing them over most of the time.

#### When Is Concurrency Useful?

Concurrency can make a big difference for two types of problems. These are generally called CPU-bound and I/O-bound.

I/O-bound problems cause your program to slow down because it frequently must wait for input/output (I/O) from some external resource. They arise frequently when your program is working with things that are much slower than your CPU.

Examples of things that are slower than your CPU are legion, but your program thankfully does not interact with most of them. The slow things your program will interact with most frequently are the file system and network connections.

Let’s see what that looks like:



![i](https://files.realpython.com/media/IOBound.4810a888b457.png)



On the flip side, there are classes of programs that do significant computation without talking to the network or accessing a file. These are the CPU-bound programs, because the resource limiting the speed of your program is the CPU, not the network or the file system.

Here’s a corresponding diagram for a CPU-bound program:



![i](https://files.realpython.com/media/CPUBound.d2d32cb2626c.png)



#### How to Speed Up an I/O-Bound Program

example 1: lets download some web pages.



##### Synchronous Version

```
import requests
import time


def download_site(url, session):
    with session.get(url) as response:
        print(f"Read {len(response.content)} from {url}")


def download_all_sites(sites):
    with requests.Session() as session:
        for url in sites:
            download_site(url, session)


if __name__ == "__main__":
    sites = [
        "https://www.jython.org",
        "http://olympus.realpython.org/dice",
    ] * 80
    start_time = time.time()
    download_all_sites(sites)
    duration = time.time() - start_time
    print(f"Downloaded {len(sites)} in {duration} seconds")
```

**Advantages**

The great thing about this version of code is that, well, it’s easy. It was comparatively easy to write and debug. It’s also more straight-forward to think about. There’s only one train of thought running through it, so you can predict what the next step is and how it will behave.

**Disadvantages**

The big problem here is that it’s relatively slow compared to the other solutions we’ll provide. Here’s an example of what the final output gave on my machine:  

```
Downloaded 160 in 14.289619207382202 seconds
```

##### threading Version

```
import concurrent.futures
import requests
import threading
import time


thread_local = threading.local()


def get_session():
    if not hasattr(thread_local, "session"):
        thread_local.session = requests.Session()
    return thread_local.session


def download_site(url):
    session = get_session()
    with session.get(url) as response:
        print(f"Read {len(response.content)} from {url}")


def download_all_sites(sites):
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        executor.map(download_site, sites)


if __name__ == "__main__":
    sites = [
        "https://www.jython.org",
        "http://olympus.realpython.org/dice",
    ] * 80
    start_time = time.time()
    download_all_sites(sites)
    duration = time.time() - start_time
    print(f"Downloaded {len(sites)} in {duration} seconds")
```

**Advantages**

It’s fast! Here’s the fastest run of my tests. Remember that the non-concurrent version took more than 14 seconds:

```
Downloaded 160 in 3.7238826751708984 seconds
```

It uses multiple threads to have multiple open requests out to web sites at the same time, allowing your program to overlap the waiting times and get the final result faster! Yippee! That was the goal.



![w](https://files.realpython.com/media/Threading.3eef48da829e.png)



**Disadvantages**

it takes a little more code to make this happen, and you really have to give some thought to what data is shared between threads.

Threads can interact in ways that are subtle and hard to detect. These interactions can cause race conditions that frequently result in random, intermittent bugs that can be quite difficult to find. Those of you who are unfamiliar with the concept of race conditions might want to expand and read the section below.

**Race Condition**: Race conditions are an entire class of subtle bugs that can and frequently do happen in multi-threaded code. Race conditions happen because the programmer has not sufficiently protected data accesses to prevent threads from interfering with each other. You need to take extra steps when writing threaded code to ensure things are thread-safe.

What’s going on here is that the operating system is controlling when your thread runs and when it gets swapped out to let another thread run. This thread swapping can occur at any point, even while doing sub-steps of a Python statement.

#### asyncio Version

The general concept of `asyncio` is that a single Python object, called the event loop, controls how and when each task gets run. The event loop is aware of each task and knows what state it’s in. In reality, there are many states that tasks could be in, but for now let’s imagine a simplified event loop that just has two states.

The ready state will indicate that a task has work to do and is ready to be run, and the waiting state means that the task is waiting for some external thing to finish, such as a network operation.

Your simplified event loop maintains two lists of tasks, one for each of these states. It selects one of the ready tasks and starts it back to running. That task is in complete control until it cooperatively hands the control back to the event loop.

When the running task gives control back to the event loop, the event loop places that task into either the ready or waiting list and then goes through each of the tasks in the waiting list to see if it has become ready by an I/O operation completing. It knows that the tasks in the ready list are still ready because it knows they haven’t run yet.

Once all of the tasks have been sorted into the right list again, the event loop picks the next task to run, and the process repeats. Your simplified event loop picks the task that has been waiting the longest and runs that. This process repeats until the event loop is finished.

```
import asyncio
import time
import aiohttp


async def download_site(session, url):
    async with session.get(url) as response:
        print("Read {0} from {1}".format(response.content_length, url))


async def download_all_sites(sites):
    async with aiohttp.ClientSession() as session:
        tasks = []
        for url in sites:
            task = asyncio.ensure_future(download_site(session, url))
            tasks.append(task)
        await asyncio.gather(*tasks, return_exceptions=True)


if __name__ == "__main__":
    sites = [
        "https://www.jython.org",
        "http://olympus.realpython.org/dice",
    ] * 80
    start_time = time.time()
    asyncio.get_event_loop().run_until_complete(download_all_sites(sites))
    duration = time.time() - start_time
    print(f"Downloaded {len(sites)} sites in {duration} seconds")
```

**Advantages**

It’s really fast! In the tests on my machine, this was the fastest version of the code by a good margin:

```
Downloaded 160 in 2.5727896690368652 seconds
```

The scaling issue also looms large here. Running the `threading` example above with a thread for each site is noticeably slower than running it with a handful of threads. Running the `asyncio` example with hundreds of tasks didn’t slow it down at all.



![d](https://files.realpython.com/media/Asyncio.31182d3731cf.png)



**Disadvantages**

There are a couple of issues with `asyncio` at this point. You need special async versions of libraries to gain the full advantage of `asycio`. Had you just used `requests` for downloading the sites, it would have been much slower because `requests` is not designed to notify the event loop that it’s blocked. This issue is getting smaller and smaller as time goes on and more libraries embrace `asyncio`.

Another, more subtle, issue is that all of the advantages of cooperative multitasking get thrown away if one of the tasks doesn’t cooperate. A minor mistake in code can cause a task to run off and hold the processor for a long time, starving other tasks that need running. There is no way for the event loop to break in if a task does not hand control back to it.

#### multiprocessing Version

```
import requests
import multiprocessing
import time

session = None


def set_global_session():
    global session
    if not session:
        session = requests.Session()


def download_site(url):
    with session.get(url) as response:
        name = multiprocessing.current_process().name
        print(f"{name}:Read {len(response.content)} from {url}")


def download_all_sites(sites):
    with multiprocessing.Pool(initializer=set_global_session) as pool:
        pool.map(download_site, sites)


if __name__ == "__main__":
    sites = [
        "https://www.jython.org",
        "http://olympus.realpython.org/dice",
    ] * 80
    start_time = time.time()
    download_all_sites(sites)
    duration = time.time() - start_time
    print(f"Downloaded {len(sites)} in {duration} seconds")
```

**Advantages**

The `multiprocessing` version of this example is great because it’s relatively easy to set up and requires little extra code. It also takes full advantage of the CPU power in your computer. The execution timing diagram for this code looks like this:



![i](https://files.realpython.com/media/MProc.7cf3be371bbc.png)



**Disadvantages**

This version of the example does require some extra setup, and the global `session` object is strange. You have to spend some time thinking about which variables will be accessed in each process.

```
Downloaded 160 in 5.718175172805786 seconds
```

#### How to Speed Up a CPU-Bound Program

For the purposes of our example, we’ll use a function to create something that takes a long time to run on the CPU. This function computes the sum of the squares of each number from 0 to the passed-in value:

```
def cpu_bound(number):
    return sum(i * i for i in range(number))
```

##### Synchronous Version

```
import time


def cpu_bound(number):
    return sum(i * i for i in range(number))


def find_sums(numbers):
    for number in numbers:
        cpu_bound(number)


if __name__ == "__main__":
    numbers = [5_000_000 + x for x in range(20)]

    start_time = time.time()
    find_sums(numbers)
    duration = time.time() - start_time
    print(f"Duration {duration} seconds")
```

Unlike the I/O-bound examples, the CPU-bound examples are usually fairly consistent in their run times. This one takes about 7.8 seconds on my machine:

```
Duration 7.834432125091553 seconds
```

##### threading and asyncio Versions

In your I/O-bound example above, much of the overall time was spent waiting for slow operations to finish. `threading` and `asyncio` sped this up by allowing you to overlap the times you were waiting instead of doing them sequentially.

On a CPU-bound problem, however, there is no waiting. The CPU is cranking away as fast as it can to finish the problem. In Python, both threads and tasks run on the same CPU in the same process. That means that the one CPU is doing all of the work of the non-concurrent code plus the extra work of setting up threads or tasks. It takes more than 10 seconds:

```
Duration 10.407078266143799 seconds
```

### multiprocessing Version

```
import multiprocessing
import time


def cpu_bound(number):
    return sum(i * i for i in range(number))


def find_sums(numbers):
    with multiprocessing.Pool() as pool:
        pool.map(cpu_bound, numbers)


if __name__ == "__main__":
    numbers = [5_000_000 + x for x in range(20)]

    start_time = time.time()
    find_sums(numbers)
    duration = time.time() - start_time
    print(f"Duration {duration} seconds")
```

**Advantages**

The `multiprocessing` version of this example is great because it’s relatively easy to set up and requires little extra code. It also takes full advantage of the CPU power in your computer.

Hey, that’s exactly what I said the last time we looked at `multiprocessing`. The big difference is that this time it is clearly the best option. It takes 2.5 seconds on my machine:

```
Duration 2.5175397396087646 seconds
```

**Disadvantages**

There are some drawbacks to using `multiprocessing`. They don’t really show up in this simple example, but splitting your problem up so each processor can work independently can sometimes be difficult.

Also, many solutions require more communication between the processes. This can add some complexity to your solution that a non-concurrent program would not need to deal with.



Source: [https://realpython.com/](https://realpython.com/)


