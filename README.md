# Kubxr — Local Kubernetes Node on Android

**Run a full k3s/k0s Kubernetes cluster on a non-rooted Android device — no Termux, no root, one APK.**

Kubxr provides the **Node/Control Plane** for the AI2TH Kubernetes ecosystem. It uses the established QEMU-on-Android architecture to host a lightweight Alpine Linux VM running Kubernetes.

---

## How it works

```
Android App (Kotlin)
  └── VmManager  ──launches──▶  QEMU (libqemu.so)
                                  └── Alpine Linux VM
                                        └── k0s (Kubernetes)
                                              └── API Server :6443
  └── VmService  ────────────────▶  Foreground Service (Persistence)
```

- **No root required** — Uses QEMU user-mode networking (SLIRP).
- **Lightweight** — Optimized for mobile to minimize RAM (~512MB-800MB).
- **Persistent** — `user.qcow2` overlay preserves cluster state and container images.

---

## Features

- **One-Tap Cluster**: Start a certified Kubernetes distribution in seconds.
- **Resource Optimized**: Tailored Alpine guest with `cgroups` and `libc6-compat` for stability.
- **API Access**: Forwards port `6443` to the Android host for local or remote management.
- **Ecosystem Integration**: Designed to be managed by [Vizxr](../K8s-console/README.md).

---

## About AI2TH

**Applied Intelligence To Tackle Hardships**

AI2TH builds developer tools that bring powerful computing environments to constrained devices.

🌐 [ai2th.github.io](https://ai2th.github.io)
