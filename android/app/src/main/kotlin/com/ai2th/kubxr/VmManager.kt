package com.ai2th.kubxr

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream

class VmManager(private val context: Context) {
    private val TAG = "VmManager"
    @Volatile private var vmProcess: Process? = null
    @Volatile private var isRunning = false

    private val filesDir: File get() = context.filesDir
    private val vmDir: File get() = File(filesDir, "vm")

    private val nativeLibDir: File
        get() = File(context.applicationInfo.nativeLibraryDir)

    @Synchronized
    fun startVm() {
        Log.d(TAG, "Starting Kubxr Node VM...")

        if (isRunning || vmProcess != null) {
            stopVm()
        }

        if (!assetsReady()) {
            extractAssets()
        }

        val qemuBin = resolveQemuBinary()
        val baseImage = File(vmDir, "base.qcow2")
        val userImage = File(vmDir, "user.qcow2")

        if (!userImage.exists()) {
            createUserImage(userImage.absolutePath, baseImage.absolutePath)
        }

        val cmd = buildQemuCommand(
            qemuBin = qemuBin.absolutePath,
            userImage = userImage.absolutePath
        )

        Log.d(TAG, "QEMU command: ${cmd.joinToString(" ")}")

        vmProcess = ProcessBuilder(cmd).apply {
            environment()["LD_LIBRARY_PATH"] = nativeLibDir.absolutePath
            redirectErrorStream(true)
        }.start()

        isRunning = true

        Thread {
            try {
                vmProcess?.inputStream?.bufferedReader()?.forEachLine { line ->
                    Log.d("QEMU", line)
                }
            } catch (e: Exception) {
                Log.w(TAG, "QEMU output reader closed")
            }
        }.apply { isDaemon = true; start() }
    }

    @Synchronized
    fun stopVm() {
        Log.d(TAG, "Stopping Kubxr Node VM...")
        vmProcess?.destroy()
        vmProcess = null
        isRunning = false
    }

    fun checkHealth(): Boolean {
        if (!isRunning) return false
        vmProcess?.let {
            try {
                it.exitValue()
                isRunning = false
                return false
            } catch (_: IllegalThreadStateException) { }
        }
        return true
    }

    fun getStatus(): String {
        return if (isRunning) "running" else "stopped"
    }

    fun getKubeconfig(): String {
        return "MOCK_KUBECONFIG_DATA"
    }

    private fun assetsReady(): Boolean {
        return File(vmDir, "base.qcow2").exists() &&
               File(vmDir, "vmlinuz-virt").exists() &&
               File(vmDir, "initramfs-virt").exists()
    }

    private fun extractAssets() {
        vmDir.mkdirs()
        listOf("base.qcow2", "vmlinuz-virt", "initramfs-virt").forEach { name ->
            val dest = File(vmDir, name)
            context.assets.open("vm/$name").use { input ->
                FileOutputStream(dest).use { input.copyTo(it) }
            }
        }
    }

    private fun createUserImage(userImagePath: String, baseImagePath: String) {
        val qemuImg = File(nativeLibDir, "libqemu_img.so")
        ProcessBuilder(
            qemuImg.absolutePath, "create", "-f", "qcow2",
            "-b", baseImagePath, "-F", "qcow2", userImagePath, "10G"
        ).apply {
            environment()["LD_LIBRARY_PATH"] = nativeLibDir.absolutePath
        }.start().waitFor()
    }

    private fun buildQemuCommand(qemuBin: String, userImage: String): List<String> {
        val cmd = mutableListOf<String>()
        cmd += qemuBin
        cmd += listOf("-machine", "virt", "-cpu", "cortex-a53", "-accel", "tcg,thread=multi")
        cmd += listOf("-smp", "2", "-m", "1024")
        cmd += listOf("-drive", "if=none,file=$userImage,id=user,format=qcow2")
        cmd += listOf("-device", "virtio-blk-pci,drive=user")
        cmd += listOf("-netdev", "user,id=net0,hostfwd=tcp::6443-:6443")
        cmd += listOf("-device", "virtio-net-pci,netdev=net0")
        cmd += listOf("-display", "none", "-serial", "stdio", "-no-reboot")

        val kernel = File(vmDir, "vmlinuz-virt")
        val initrd = File(vmDir, "initramfs-virt")
        cmd += listOf("-kernel", kernel.absolutePath)
        cmd += listOf("-initrd", initrd.absolutePath)
        cmd += listOf("-append", "console=ttyAMA0 root=/dev/vda rootfstype=ext4 rootflags=rw modules=virtio_blk,ext4 cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory quiet")

        return cmd
    }

    private fun resolveQemuBinary(): File = File(nativeLibDir, "libqemu.so")
}
