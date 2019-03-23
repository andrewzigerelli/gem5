# Compilation
See gem5 wiki for downloading and compiling gem5 with scons. 

Note: you must also set an m5 folder somewhere on your system for the disk and
kernel.

For speed, checkpoint with **TimingSimpleCPU**.

# Install stuff
For Ciro's setup, you need to muck around with buildroot.

Since we need to get SPEC to run, boot the image in qemu and install using the
guest compiler. Here's a script which can help you boot:
https://gist.github.com/andrewzigerelli/5c0c82d5bc304ed28ac972c9254edb54

# System setup
1. Use qemu to create a disk image, see Jason's blog:
http://www.lowepower.com/jason/setting-up-gem5-full-system.html

**BE SURE** to note what disk root is on! (e.g. /dev/sda1)

Compile the kernel. Look up how to use an oldconfig; here is one that I got to
work: https://gist.github.com/andrewzigerelli/6e0084af628a38e658320a1ff2d9ebd9. 
Note: vmlinux will work with gem5. You also need to `make bzImage` to use
with qemu later.

Make sure to also install the gem5 tools, covered in Jason's post.

Further, if these are installed: 

Lxcfs is a fuse filesystem mainly designed for use by lxc
containers. We don't need it, and it always fails to startup with:
[FAILED] Failed to start FUSE filesystem for LXC.
Remove it

```shell
sudo apt remove lxcfs -y --purge
```

Also remove snappy, which also fails during startup:

```shell
sudo apt purge snapd ubuntu-core-launcher squashfs-tools
```


2. Alternatively, use Ciro Santilli's excellent setup:
https://github.com/cirosantilli/linux-kernel-module-cheat Even if you don't use
this, at least check it out because he has excellent notes.

# Modify run_gem.sh in my_script accordingly.
As of now, the automatic checkpoint doesn't work. Take it manually (boot and run
m5 checkpoint from the simulated system).

For the initial setup, should only have to be concerned with changing the m5 and
gem5 locations, as well as the disk you want to boot, plus the **root**
variable.

Also, you need to edit cache, mem_size, etc parameters per experiment.

# Boot problems

## No internet
Boot in the gui where host networking should be set up for you. e.g. look at
`run_qemu_gui.sh` and modify appropriately (image name). This may be used in the
case where you need to apt-get to fix things.

In qemu, during boot, if you get
```
[FAILED] Failed to start Load Kernel Modules.
```

Hopefully, it still boots and you can debug. Login as root and:
```shell
systemctl status systemd-modules-load.service
```

Example output:
```
  Loaded: loaded (/lib/systemd/system/systemd-modules-load.service; static; ven
  Active: failed (Result: exit-code) since Wed 2019-01-23 16:41:59 EST; 12min a
  Docs: man:systemd-modules-load.service(8)
        man:modules-load.d(5)
  Process: 57 ExecStart=/lib/systemd/systemd-modules-load (code=exited, status=1
  Main PID: 57 (code=exited, status=1/FAILURE)
```

Get the PID (in this case, 57) and run (replace 57 with your PID)
```shell
journalctl _PID=57 | less
```
This will give you failure messages than you can google.
In my case, I got, among other messages :
```
could not open moddep file '/lib/modules/4.19.0/modules.dep.bin'
```
For ubuntu, doing
```shell
apt-get install linux-image-4.19.0
```
will fix it, but this probably won't work. Either compile it yourself:
https://stackoverflow.com/questions/22783793/how-to-install-kernel-modules-from-source-code-error-while-make-process
Look at Ciro's answer (he is everywhere!)

Or you need to install libssl1.1 here:
https://packages.ubuntu.com/bionic/amd64/libssl1.1/download

Or direct link here:
http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4.3_amd64.deb

and install it very dpkg -i package_name


Also install

http://ubuntuhandbook.org/index.php/2018/10/linux-kernel-4-19-released-install-ubuntu/

and make a softlink like so:
```shell
cd /lib/modules
ln -s 4.19.0-041900-generic 4.19.0
```

You may still have the service fail to load. Check the journal
again following the above steps.

In may case, the following failed to load:
iscsi_tcp
ib_iser

In this case, the fix:
```shell
cd /lib/modules-load.d
vim open-isci.conf
```
and comment out the files that were complained about by appending #.

Next time, the service started on boot!
>>>>>>> bb513da20643fad707cc42ec040388629a9ae6ee
