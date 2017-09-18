# TinyThreads

TinyThreadsは、Altera Nios II上でPOSIX(pthreads)互換のマルチスレッド環境を構築するライブラリです。
Nios II Eclipse開発環境にてBSP typeの一つとして利用できます。

TinyThreads is POSIX(pthreads) compatible multi-threading library for Altera Nios II.
This library can be used as one of BSP types from Nios II Eclipse environment.

## 使い方 / Usage

1. カスタムIPを置くためのフォルダが用意されていないなら、作成してください。
   なお、このフォルダはあなたの全プロジェクトから共通で利用する場所とするため、プロジェクトフォルダ(qsfファイルなどがあるフォルダ)の外に作ることをお勧めします。  
   Prepare your custom IP folder if you don't have that folder.
   When you creates a new folder, make it in outside of any project folder (which has qsf files etc.) to share this folder in all your projects.

1. QuartusにカスタムIPを置くフォルダを登録してください。Quartusのメニューから、Tool→Options→General→IP Settings→IP Catalog Search Locationsと進み、
   Global IP search directoriesリストにフォルダのパスを登録します。この際、フォルダ内を再帰的に検索できるように、パスの後ろに /\*\*/\* を足してください。  
   Register your custom IP folder to Quartus. From Quartus menu, open Tool -> Options -> General -> IP Settings -> IP Catalog Search Locations and
   add your custom IP folder path to Global IP search directories list. When you write path to the folder, you have to add "/\*\*/\*" to the tail of
   path to make search recursive.

1. カスタムIPを置くフォルダに、tinythreadsをcloneします。  
   Clone tinythreads repository into the your custom IP folder.

   ```
   cd path_to_custom_ip_folder/
   git clone https://github.com/kimushu/tinythreads.git
   ```

1. Nios II Eclipseにて、新規プロジェクトを「Nios II Board Support Package」から作成します。このとき、BSP typeから「TinyThreads」を選んでください。  
   Make a new project by "Nios II Board Support Package" in Nios II Eclipse. Select "TinyThreads" as a BSP type.

1. プリエンプションの間隔など、設定の変更が必要ならBSP Editorを起動してカスタマイズしてください。
   TinyThreadsの設定は Main タブの Settings→Advanced→tinyth の下にあります。  
   You can change settings (preemption interval, etc.) in BSP Editor.
   Settings for TinyThreads are located at Settings -> Advanced -> tinyth in Main tab.

1. あなたのアプリケーションのBSPを、前項で作成したBSPプロジェクトに変更してください。
   まだプロジェクトを作成していないなら、新規プロジェクトを「Nios II Application」から作成します。  
   Change BSP of your application project to the BSP you've created in the previous step.
   If you don't have your application project yet, you can make a new project by "Nios II Application".

1. あなたのアプリケーションをビルドし直して下さい。  
   Re-build your application.

1. 初期化処理などを手動で呼び出す必要はありません。もうあなたのアプリケーションではpthread\_create()で新たなスレッドを生成できる状態です。ようこそTinyThreadsへ！  
   You don't have to call any initialization function manually. Your application is ready to generate a new thread by pthread\_create(). Welcome to TinyThreads!

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

BSP設定(tinyth.feature.enable\_mutex)が有効のときに使用可能です(既定値は有効)。  
This feature is available when BSP setting (tinyth.feature.enable\_mutex) is enabled (default: enable).

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

BSP設定(tinyth.feature.enable\_sem)が有効のときに使用可能です(既定値は有効)。  
This feature is available when BSP setting (tinyth.feature.enable\_sem) is enabled (default: enable).

| Interface | Name           | Conforming to | Remarks |
|:----------|:---------------|:--------------|:--------|
| Type      | sem\_t         | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_destroy() | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_init()    | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_post()    | POSIX.1-2001  | &lt;semaphore.h&gt; Can be used in ISR |
| Function  | sem\_wait()    | POSIX.1-2001  | &lt;semaphore.h&gt; |
| Function  | sem\_trywait() | POSIX.1-2001  | &lt;semaphore.h&gt; |

### 条件付き変数 / Conditional variables

BSP設定(tinyth.feature.enable\_condおよびtinyth.feature.enable\_mutex)の両方が有効のときに使用可能です(既定値は有効)。  
This feature is available when both of BSP setting (tinyth.feature.enable\_cond and tinyth.feature.enable\.mutex) are enabled (default: enable).

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

BSP設定(tinyth.feature.enable\_onceおよびtinyth.feature.enable\_mutex)の両方が有効のときに使用可能です(既定値は有効)。  
This feature is available when both of BSP setting (tinyth.feature.enable\_once and tinyth.feature.enable\.mutex) are enabled (default: enable).

| Interface | Name                | Conforming to | Remarks     |
|:----------|:--------------------|:--------------|:------------|
| Type      | pthread\_once\_t    | POSIX.1-2001  | |
| Macro     | PTHREAD\_ONCE\_INIT | POSIX.1-2001  | |
| Function  | pthread\_once()     | POSIX.1-2001  | |

### pthreads以外の機能 / Features outside of pthreads

以下のAPIは、本来pthreadsのカバーする範囲ではありませんが、マルチスレッド環境に対して効率的な実装をTinyThreadsが提供できるものです。BSP設定(tinyth.feature.enable\_sleep)が有効の時に使用可能です(既定値は有効)。  
The following APIs are outside of pthreads but TinyThreads can provide a more effective implementation for multi-threading environment. This feature is available when BSP setting (tinyth.feature.enable\_sleep) is enabled (default: enable).

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

