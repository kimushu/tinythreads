# TinyThreads

TinyThreadsは、Altera Nios II上でPOSIX(pthreads)互換のマルチスレッド環境を構築するライブラリです。
Nios II Eclipse開発環境にてBSP typeの一つとして利用できます。

TinyThreads is POSIX(pthreads) compatible multi-threading library for Altera Nios II.
This library can be used as one of BSP types from Nios II Eclipese environment.

## 使い方 / Usage

1. プロジェクト(qsfファイル)があるフォルダ(またはその中のipフォルダ)に、tinythreadsをcloneします。  
   Clone tinythreads repository into the folder (or _ip_ folder) which a project (qsf file) is located in.

   ```
   cd path_to_project/
   git clone https://github.com/kimushu/tinythreads.git
   ```

1. カスタムIPが検索できるようにするため、IPXファイルを作成します。(TODO: Generate BSP / BSP editor で検索にヒットしない問題あり)  
   To ensure development tools can lookup this custom IP, make IPX file.

   ```
   ip-make-ipx --thorough-descent
   ```

1. Nios II Eclipseにて、新規プロジェクトを「Nios II Board Support Package」から作成します。このとき、BSP typeから「TinyThreads」を選んでください。  
   Make a new project by "Nios II Board Support Package" in Nios II Eclipse. Select "TinyThreads" as a BSP type.

1. (未実装) プリエンプションの間隔など、設定の変更が必要ならBSP editorを起動してカスタマイズしてください。  
   (Not implemented yet) You can change settings (preemption interval, etc.) in BSP editor.

1. あなたのアプリケーションのBSPを、前項で作成したBSPプロジェクトに変更してください。
   まだプロジェクトを作成していないなら、新規プロジェクトを「Nios II Application」から作成します。  
   Change BSP of your application project to the BSP you've created in the previous step.
   If you don't have your application project yet, you can make a new project by "Nios II Application".

1. あなたのアプリケーションをビルドし直して下さい。
   Re-build your application.

1. 初期化処理などを手動で呼び出す必要はありません。もうあなたのアプリケーションではpthread_createで新たなスレッドを生成できる状態です。ようこそTinyThreadsへ！  
   You don't have to call any initialization function manually. Your application is ready to generate a new thread by pthread_create. Welcome to TinyThreads!

## ライセンス / License
The MIT License

## 対応している機能 / Supported features

| Category         | Interface                     | Conforming to | Description |
|:-----------------|:------------------------------|:--------------|:------------|
| Thread           | [Type] pthread_t              | POSIX.1-2001  | |
| Thread           | pthread_create()              | POSIX.1-2001  | |
| Thread           | pthread_exit()                | POSIX.1-2001  | |
| Thread           | pthread_join()                | POSIX.1-2001  | |
| Thread           | pthread_detach()              | POSIX.1-2001  | |
| Thread           | pthread_self()                | POSIX.1-2001  | |
| Thread           | pthread_equal()               | POSIX.1-2001  | |
| Thread attribute | [Type] pthread_attr_t         | POSIX.1-2001  | |
| Thread attribute | pthread_attr_init()           | POSIX.1-2001  | |
| Thread attribute | pthread_attr_destroy()        | POSIX.1-2001  | |
| Thread attribute | pthread_attr_setdetachstate() | POSIX.1-2001  | |
| Thread attribute | pthread_attr_getdetachstate() | POSIX.1-2001  | |
| Thread attribute | pthread_attr_setschedparam()  | POSIX.1-2001  | |
| Thread attribute | pthread_attr_getschedparam()  | POSIX.1-2001  | |
| Thread attribute | pthread_attr_setschedpolicy() | POSIX.1-2001  | |
| Thread attribute | pthread_attr_getschedpolicy() | POSIX.1-2001  | |
| Thread attribute | pthread_attr_setstack()       | POSIX.1-2001  | |
| Thread attribute | pthread_attr_getstack()       | POSIX.1-2001  | |
| Thread attribute | pthread_attr_setstacksize()   | POSIX.1-2001  | |
| Thread attribute | pthread_attr_getstacksize()   | POSIX.1-2001  | |
| Scheduler        | sched_get_priority_max()      | POSIX.1-2001  | |
| Scheduler        | sched_get_priority_min()      | POSIX.1-2001  | |
| Scheduler        | shced_yield()                 | POSIX.1-2001  | |
| Mutex            | [Type] pthread_mutex_t        | POSIX.1-2001  | |
| Mutex            | [Macro] PTHREAD_MUTEX_INITIALIZER | POSIX.1-2001  | |
| Mutex            | pthread_mutex_init()          | POSIX.1-2001  | |
| Mutex            | pthread_mutex_destroy()       | POSIX.1-2001  | |
| Mutex            | pthread_mutex_lock()          | POSIX.1-2001  | |
| Mutex            | pthread_mutex_trylock()       | POSIX.1-2001  | |
| Mutex            | pthread_mutex_unlock()        | POSIX.1-2001  | |
