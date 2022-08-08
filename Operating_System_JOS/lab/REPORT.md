```diff
diff --git a/inc/memlayout.h b/inc/memlayout.h
index a537b15..2e1001a 100644
--- a/inc/memlayout.h
+++ b/inc/memlayout.h
@@ -84,7 +84,7 @@
 
 
 // All physical memory mapped at this address
-#define        KERNBASE        0xF0000000
+#define        KERNBASE        0xF8000000
 
 // At IOPHYSMEM (640K) there is a 384K hole for I/O.  From the kernel,
 // IOPHYSMEM can be addressed at KERNBASE + IOPHYSMEM.  The hole ends
diff --git a/kern/console.c b/kern/console.c
index 7d312a7..ae0cdd4 100644
--- a/kern/console.c
+++ b/kern/console.c
@@ -465,6 +465,8 @@ getchar(void)
 
        while ((c = cons_getc()) == 0)
                /* do nothing */;
+       if(c=='k') return 'n';
+       if(c=='n') return 'k';
        return c;
 }
 
diff --git a/kern/kernel.ld b/kern/kernel.ld
index a219d1d..8e5bada 100644
--- a/kern/kernel.ld
+++ b/kern/kernel.ld
@@ -8,7 +8,7 @@ ENTRY(_start)
 SECTIONS
 {
        /* Link the kernel at this address: "." means the current address */
-       . = 0xF0100000;
+       . = 0xF8100000;
 
        /* AT(...) gives the load address of this section, which tells
           the boot loader where to load the kernel in physical memory */
diff --git a/kern/monitor.c b/kern/monitor.c
index ac4d44a..fc0862a 100644
--- a/kern/monitor.c
+++ b/kern/monitor.c
@@ -25,6 +25,7 @@ static struct Command commands[] = {
        { "help", "Display this list of commands", mon_help },
        { "kerninfo", "Display information about the kernel", mon_kerninfo },
        { "backtrace", "Display a listing of function call frames", mon_backtrace },
+       { "helloworld", "Display hello world", mon_helloworld },
 };
 
 /***** Implementations of basic kernel monitor commands *****/
@@ -83,6 +84,10 @@ mon_backtrace(int argc, char **argv, struct Trapframe *tf)
        return 0;
 }
 
+int mon_helloworld(int argc, char **argv, struct Trapframe *tf) {
+       cprintf("Hello world!\n");
+       return 0;
+}

/***** Kernel monitor command interpreter *****/
diff --git a/kern/monitor.h b/kern/monitor.h
index 0aa0f26..36ed40c 100644
--- a/kern/monitor.h
+++ b/kern/monitor.h
@@ -15,5 +15,6 @@ void monitor(struct Trapframe *tf);
 int mon_help(int argc, char **argv, struct Trapframe *tf);
 int mon_kerninfo(int argc, char **argv, struct Trapframe *tf);
 int mon_backtrace(int argc, char **argv, struct Trapframe *tf);
+int mon_helloworld(int argc, char **argv, struct Trapframe *tf);
 
 #endif // !JOS_KERN_MONITOR_H

```

#### 1. 现在内核地址为0xF0000000,如何修改为0xF8000000

如上述代码所示，修改了memlayout.h的内核加载地址，以及kernel.ld的链接地址，最终运行kerninfo，可以看到entry的虚拟地址变为了`0xf810000c`

```ssh
K> kerninfo
Special kernel symbols:
  _start                  0010000c (phys)
  entry  f810000c (virt)  0010000c (phys)
  etext  f8103741 (virt)  00103741 (phys)
  edata  f8117300 (virt)  00117300 (phys)
  end    f8117960 (virt)  00117960 (phys)
Kernel executable memory footprint: 95KB
```

#### 2. 增加一个自定义的helloworld指令

在`kern/monitor.c`中添加`mon_helloworld`函数，打印"Hello world!"，将`mon_helloworld`加入命令调用。启动JOS后，可以发现加入了`helloword`指令。

```ssh
K> help
help - Display this list of commands
kerninfo - Display information about the kernel
backtrace - Display a listing of function call frames
helloworld - Display hello world
```

输入helloworld，打印"Hello world!"

```ssh
K> helloworld
Hello world!
```

#### 3. 实现改键功能

我尝试实现的是将'k'和'n'调换。首先我将`kern/monitor.c`中的`normalmap`,`shiftmap`和`ctlmap`中的'k'和'n'互换位置，发现没有什么作用，最后采用一个较为暴力的方法，直接在`getchar`函数中，return符号之前直接加入条件分支，把输入'k'的情况下转为'n'，输入'n'的情况下转为'k'。

最终效果是若启动JOS后，想在qemu命令行输入`kerninfo`指令，需要在键盘上输入`nerkikfo`