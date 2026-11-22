# 内部 Linux 机器执行：相邻立方数之间的素数

这是私有研究分支上的**运行脚本**，不是已经通过的证明报告。面对上游原证明，脚本从固定 Git 提交取源码并构建，不使用社区二进制缓存。
不使用 sudo、包管理器或云服务，不上传日志、证明或其他数据；日志和大型构建产物留在机器上。固定版本的 ProofWidgets 使用随 Git 提交提供的 JS，不访问 npm registry；只调整构建配置，不改动它的 Lean 文件。
上游源码仅从其公共验证仓库拉取，不复制进本仓库。

## 不联网自检

在仓库根目录运行：

```bash
bash research/cryptids/internal-runner/run.sh --probe
```

完整运行需要 Linux、Git、Python 3、C/C++ 构建工具和已安装的 **Lean 4.33.1**（提交
`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`），且机器必须获准 Git 读取各固定上游。
给脚本的是**真实工具链** `bin` 路径，不是 `elan` shim。脚本不会替你安装 Lean。
若受限网络只能访问机构 Git 镜像，由机器管理员按既有方式配置对应 Git URL；脚本没有代理或权限绕过逻辑。
首次完整运行要求约 64 GiB RAM、150 GB 空盘才尝试。这只是起跑线，不保证原证明构建成功，更不保证独立导出/复验够用。

## 安装固定版本的 Lean

如果机器允许访问官方发行文件，使用速度更快的方式。若已通过合规方式拿到归档，可用 `--archive /path/to/lean-4.33.1-linux.tar.zst` 取代 `--release`，完全离线解压。两种方式都按 Linux 架构（x86_64 / aarch64）检查官方 SHA-256，再核对 Lean 和 Lake 版本。

```bash
LEAN_BIN=$(bash research/cryptids/internal-runner/install-lean.sh --release)
```

**如果机器只允许 Git**，用锁定提交编译 Lean：

```bash
LEAN_BIN=$(bash research/cryptids/internal-runner/install-lean.sh --git)
```

源码模式要求已有 CMake ≥ 3.21、Make、C/C++ 编译工具、`pkg-config` 和 LibUV/OpenSSL 开发文件，以及可信的 `leantar 0.1.20`（可用 `LEANTAR_BIN=/路径/leantar` 指定）。如果没有 leantar，脚本可以从固定 Git 提交构建它，但要求已安装的真实 Rust/Cargo 和**已备齐**的离线依赖缓存；不会联网访问 Rust 包仓库。源码模式不会下载 Lean 发行包，也不会调用系统包管理器。构建可能较久，可用 `LEAN_BUILD_JOBS=4` 控制并发。不从系统旧版 GMP 编译内核；用 Lean 自带的大整数实现。

默认安装到当前目录的 `.lean-local`；可设置 `LEAN_INSTALL_DIR=/有空间的目录/lean`。不需要 sudo，不改系统 PATH。成功时标准输出只有实际的 `bin` 路径；已有工具链可用 `--check /路径/bin` 验证。仅在安装命令成功后，把 `LEAN_BIN` 传给下面的验证脚本。

## 拉取代码后运行

从私有仓库的 `research/cryptids-short-interval` 分支，在实际有空间的工作目录执行：

```bash
LEAN_BIN="$LEAN_BIN" RUN_DIR=/有空间的目录/cubes-run \
  bash research/cryptids/internal-runner/run.sh
```

同一机器、同一 `RUN_DIR` 和同一代码版本可直接重跑：Git 和 Lake 复用本地成果，有限区间透过有哈希的分组检查点续跑。不要并行对同一目录启动两次；可用 `CUBE_JOBS=3` 降低有限区间任务并发。
只需要有限区间和对黎曼猜想的条件证明时，追加 `--cube-only`，不会拉取 RH 仓库。

完成或中途退出，回传 `RUN_DIR/summary.txt`（终端也会显示），无需回传构建产物。
如果失败，可另贴对应 `logs/阶段名.log` 的首条有效错误；先删去公司的路径、地址和其他内部信息。

## 结果的范围

`cube_finite=PASS` 指 64 组严格区间的 Lean 检验及全范围条件定理通过。
`native_composition=PASS` 另表示该机确实导入了 Alpöge 的 `Main`，闭合了无条件的 Lean 目标，并审计了只使用标准公理的声明。原证明目标在固定镜像提交
`58afe6f4b8167e8945f7c82954b0fc477541f9d0`；Mathlib 提交 `0df444a360eaa60ab8c11dca51a86af692955474`。
这些状态都不替代将解答导出后用独立内核重放。
目录内的 `CubeChallenge.lean` / `comparator.json` 是后续独立重放的隔离题面和配置，不会被此脚本导入或当作证明；摘要明确记录 `independent_export_replay=NOT_RUN`。


`--probe` 还会只读报告 Linux 的单进程 VM 映射上限与
虚拟内存限制。大规模 `import Main` 对文件映射有额外需求，
换用较大内存并不能自动解除映射限制。`RESOURCE` 行记录
实际 Lean 子进程的映射数、文件/匿名内存及 RSS 峰值；采样值
不是极限或是否能运行的保证。脚本不改任何系统设置。
