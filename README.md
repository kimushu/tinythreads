# TinyThreads

TinyThreads is POSIX threads (pthreads) compatible tiny multi-threading library for 32-bit microcontrollers.

Currently, following processors are supported:

* Intel(Altera) Nios II
* Microchip PIC32 (MIPS32 Architecture)

## マニュアル / Manuals

See [TinyThreads wiki](https://github.com/kimushu/tinythreads/wiki).

## ライセンス / License
The MIT License

## 対応している機能 / Supported features

ほとんどの機能は &lt;pthread.h&gt; ヘッダファイルで提供されます。  
Most features are provided in &lt;pthread.h&gt; header file.

### スレッド操作とスケジューリング / Thread operation and scheduling

| Interface | Name                            | Conforming to | Remarks |
|:----------|:--------------------------------|:--------------|:--------|
| Type      | pthread\_t                      | POSIX.1-2001  | |
| Function  | pthread\_create()               | POSIX.1-2001  | |
| Function  | pthread\_exit()                 | POSIX.1-2001  | |
| Function  | pthread\_join()                 | POSIX.1-2001  | |
| Function  | pthread\_detach()               | POSIX.1-2001  | |
| Function  | pthread\_self()                 | POSIX.1-2001  | |
| Function  | pthread\_equal()                | POSIX.1-2001  | |
| Type      | pthread\_attr\_t                | POSIX.1-2001  | |
| Function  | pthread\_attr\_init()           | POSIX.1-2001  | |
| Function  | pthread\_attr\_destroy()        | POSIX.1-2001  | |
| Function  | pthread\_attr\_setdetachstate() | POSIX.1-2001  | |
| Function  | pthread\_attr\_getdetachstate() | POSIX.1-2001  | |
| Function  | pthread\_attr\_setschedparam()  | POSIX.1-2001  | |
| Function  | pthread\_attr\_getschedparam()  | POSIX.1-2001  | |
| Function  | pthread\_attr\_setschedpolicy() | POSIX.1-2001  | |
| Function  | pthread\_attr\_getschedpolicy() | POSIX.1-2001  | |
| Function  | pthread\_attr\_setstack()       | POSIX.1-2001  | |
| Function  | pthread\_attr\_getstack()       | POSIX.1-2001  | |
| Function  | pthread\_attr\_setstacksize()   | POSIX.1-2001  | |
| Function  | pthread\_attr\_getstacksize()   | POSIX.1-2001  | |
| Function  | sched\_get\_priority\_max()     | POSIX.1-2001  | &lt;sched.h&gt; |
| Function  | sched\_get\_priority\_min()     | POSIX.1-2001  | &lt;sched.h&gt; |
| Function  | shced\_yield()                  | POSIX.1-2001  | &lt;sched.h&gt; |

### ミューテックス / Mutex

| Interface | Name                        | Conforming to | Remarks |
|:----------|:----------------------------|:--------------|:--------|
| Type      | pthread\_mutex\_t           | POSIX.1-2001  | |
| Macro     | PTHREAD\_MUTEX\_INITIALIZER | POSIX.1-2001  | |
| Function  | pthread\_mutex\_destroy()   | POSIX.1-2001  | |
| Function  | pthread\_mutex\_init()      | POSIX.1-2001  | |
| Function  | pthread\_mutex\_lock()      | POSIX.1-2001  | |
| Function  | pthread\_mutex\_trylock()   | POSIX.1-2001  | |
| Function  | pthread\_mutex\_unlock()    | POSIX.1-2001  | |

### セマフォ / Semaphore

| Interface | Name           | Conforming to | Remarks |
|:----------|:---------------|:--------------|:--------|
| Type      | sem\_t         | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_destroy() | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_init()    | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_post()    | POSIX.1-2001  | &lt;semaphore.h&gt; Can be used in ISR |
| Function  | sem\_wait()    | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_trywait() | POSIX.1-2001  | &lt;semaphore.h&gt; |

### 条件付き変数 / Conditional variables

| Interface | Name                       | Conforming to | Remarks |
|:----------|:---------------------------|:--------------|:--------|
| Type      | pthread\_cond\_t           | POSIX.1-2001  | |
| Macro     | PTHREAD\_COND\_INITIALIZER | POSIX.1-2001  | |
| Function  | pthread\_cond\_destroy()   | POSIX.1-2001  | |
| Function  | pthread\_cond\_init()      | POSIX.1-2001  | |
| Function  | pthread\_cond\_broadcast() | POSIX.1-2001  | |
| Function  | pthread\_cond\_signal()    | POSIX.1-2001  | |
| Function  | pthread\_cond\_wait()      | POSIX.1-2001  | |

### 1回きりの初期化 / Once control

| Interface | Name                | Conforming to | Remarks     |
|:----------|:--------------------|:--------------|:------------|
| Type      | pthread\_once\_t    | POSIX.1-2001  | |
| Macro     | PTHREAD\_ONCE\_INIT | POSIX.1-2001  | |
| Function  | pthread\_once()     | POSIX.1-2001  | |

### pthreads以外の機能 / Features outside of pthreads

以下のAPIは、本来pthreadsのカバーする範囲ではありませんが、マルチスレッド環境に対して効率的な実装をTinyThreadsが提供できるものです。
The following APIs are outside of pthreads but TinyThreads can provide a more effective implementation for multi-threading environment.

| Interface | Name                | Conforming to | Remarks     |
|:----------|:--------------------|:--------------|:------------|
| Function  | sleep()             | POSIX.1-2001  | &lt;unistd.h&gt; |
| Function  | usleep()            | POSIX.1-2001  | &lt;unistd.h&gt; |

## 削除されている機能 / Dropped features

以下に挙げる機能はTinyThreadsが目指す「小さなマルチスレッド環境」に不要と判断され、
削除された機能です。原則として、将来も対応する予定はありません。  
The features below are dropped because they are not useful in "tiny" multi-threading environment.
As a general rule, they have never been supported in the future.

- pthread\_atfork()
- pthread\_cancel()
- pthread\_key\*()
- pthread\_getspecific()
- pthread\_setspecific()
- sem\_open()
- sem\_unlink()
