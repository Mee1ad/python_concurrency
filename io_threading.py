import concurrent.futures
import requests
import threading
import time
from io_non_concurrent


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


def test():
    sites = [
        "https://www.jython.org",
        "http://olympus.realpython.org/dice",
    ] * 80
    start_time = time.time()
    download_all_sites(sites)
    duration = time.time() - start_time
    return duration
    print(f"Downloaded {len(sites)} in {duration} seconds")

if __name__ == "__main__":
    a = []
    [a.append(test()) for i in range(2)]
    print(a)


# Pros: its fast
# Cons: hard to debug, share data, race condition