# TinyThreads porting for Intel (Altera) Nios II processors

This is a porting of TinyThreads for soft core processor Nios II by Intel (Altera) FPGAs.

## Specifications

* Target processor
    * Nios II/e
    * Nios II/f (without MPU)
        * Shadow registers also supported with some limitations
* Target IDE
    * Nios II SBT for eclipse (17.1 or newer)
* Supported features
    * TinyThreads core
    * Mutexes
    * Condition variables
    * Semaphores
    * Once controls
    * Sleep functions
    * newlib support (re-entrant)

## Usage

Please see wiki pages:
* [(en) Nios II Support](https://github.com/kimushu/tinythreads/wiki/Nios-II-Support)
* [(ja) Nios II サポート](https://github.com/kimushu/tinythreads/wiki/Nios-II-%E3%82%B5%E3%83%9D%E3%83%BC%E3%83%88)
