# V2 复验报告

状态：**RUNNING**（2026-11-28 22:04 北京时间核实）。上次运行在 RH 依赖拉取时失败，尚无最终验收结论。

## A 原生合成

| 阶段 | 状态 | 退出码 |
| --- | --- | --- |
| 资源检查与固定提交检出 | PASS | 0 |
| 初始探针 | PASS | 0（仅表示探针正常退出） |
| Lean 安装及版本校验 | PASS | 0（首次安装因 tar 选项不兼容退出 64，兼容后重试成功） |
| Cryptids 固定提交拉取 | PASS | 0（此前失败 128，重试成功） |
| cube_git | PASS | 0（首次运行失败 128） |
| cube_setup | PASS | 0 |
| cube_data | PASS | 0（上次运行失败 1） |
| 兼容 Python 环境准备 | PASS | 0（Python 3.12.16、SymPy 1.14.0、mpmath 1.3.0；语法及依赖版本检查通过） |
| cube_dependencies | PASS | 0（续跑） |
| cube_analytic | PASS | 0（续跑） |
| cube_finite | PASS | 0（续跑），有限验证 **64/64** 组 |
| rh_git | PASS | 0（续跑） |
| rh_build | RUNNING（`Statements` 模块已构建） | 当时尚无退出码；上次运行 FAIL，退出码 1，Git 子进程 128 |
| native_composition | NOT_RUN | 尚无 |
| SSH 认证与推送预演 | PASS | 认证命令退出 1（GitHub 不提供 shell，认证成功）；仓库推送预演退出 0 |

有效资源：24 个可用逻辑 CPU；当前 CPU cgroup 的 CFS 配额为无限制。内存 cgroup 上限 120 GiB，启动前已用约 12.0 GiB，按上限减用量估算余量约 108.0 GiB；11 月 28 日 11:43 检查已用约 **6.65 GiB**、余量约 **113.35 GiB**，内存限制失败计数为 **0**。启动前系统报告可用约 112 GiB。运行工作盘的共享文件系统显示可用约 790 TiB，个人配额查询无可用结果；系统盘总量 512 GiB、可用约 504 GiB。RH 根目录及依赖包的编译 JSON 持续采样，11 月 28 日 11:44 记录为 **6,446** 个文件、**4,095,808,607** 字节，共享盘剩余 **868,743,248,871,424** 字节。共享盘余量保护已启用；个人配额不在其检测范围内。用户确认已为任务分配足量 512 GB 磁盘；运行目录实际位于网络工作区，系统盘是另一文件系统。`vm.max_map_count=2560000`；进程虚拟内存上限为 unlimited。

版本：Lean 4.33.1（`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`）；Mathlib 固定提交 `0df444a360eaa60ab8c11dca51a86af692955474`；RH 固定提交 `58afe6f4b8167e8945f7c82954b0fc477541f9d0`。后两者为运行脚本记录的目标版本，尚未完成构建验证。

当前 `summary.txt` 脱敏内容（运行中）：

```text
CUBE_INTERNAL_RUN_V1
mode=--run
host_max_vm_mappings=2560000
host_vmem_limit_kib_or_unlimited=unlimited
lean=4.33.1:819816b2e0a3bf405af45ae5c7af2491d8f5bee6
mathlib=0df444a360eaa60ab8c11dca51a86af692955474
rh_source=58afe6f4b8167e8945f7c82954b0fc477541f9d0
cryptids=3647718b5df22e1a61462dec0376bd204526285a
cube_git=PASS
cube_setup=PASS
cube_data=PASS
cube_dependencies=PASS
cube_analytic=PASS
cube_finite=PASS
finite_groups=64/64
candidate_sha256=fc3053b39f17074f257eda1798041a8b33c7eaa2cb72c611c7764bef9a599b1d
rh_git=PASS
```

上次运行的首个可操作错误：RH 构建准备阶段拉取 LeanSearchClient 时，Git 收到服务器空响应，Git 子进程退出 128。已在内网机按清单固定提交准备缺失依赖，并使用原目录续跑；下一步监测 RH 构建和磁盘空间，完成后核对原生验收条件。

## A 最终独立复验

状态：**NOT_RUN**；尚无退出码。指定提交中的脚本可读取，运行目录未发现同一次成功构建的最终导出，独立题面和检查器未确认就绪。

## B 旧接口比较及同版对照

状态：旧接口比较 **FAIL**（检查器退出码 **1**）；同版对照 **PASS**，检查器退出码 **0**；重试旧接口比较再次未获接受，检查器退出码 **1**，脚本总体退出码 **3**。隔离检出脚本提交 `84fb0e3330bae1f1c7f6d90233d96bf573a59ba0`，检查器提交 `5dc36dc15b7bee891a02406b78a8ac816a47baad`，Lean 4.36.0，检查器构建退出码 **0**，检查线程数 **2**。MIT 压缩包与解压输入哈希核对通过。原脚本的旧题面长度常量与哈希匹配文件相差 **659** 字节，首次准备退出 **64**。经用户授权，仅将长度从 **350,862,970** 改为 **350,862,311**，保留单行补丁后重跑；输入长度与固定哈希检查均通过，旧版五定理比较未获接受，检查器在 `riemannHypothesis` 报告其类型所依赖的 `CauSeq.Completion.Cauchy` 声明不一致；同版对照题面下载达到 3600 秒超时（curl 退出码 28，下载 45,397,876 / 46,679,352 字节），准备阶段退出码 1；续传已完成，压缩包与 MIT 清单、解压文件与脚本固定哈希均核对通过；脚本在独立目录重跑后完成同版对照，五个目标均获接受，耗时 **314 秒**。最近一次检查容器用量约 **13.5 GiB / 120 GiB**，限制失败计数 **0**；资源保护监测 A 线负载及容器内存。
B 线 `summary.txt` 脱敏要点：

```text
compact_commit=72fead102f663d5c7a407964a13dc0cf9d977207
checker_commit=5dc36dc15b7bee891a02406b78a8ac816a47baad
jobs=2
compact.ndjson_sha256=ab7b4223b9bd748a1aa68bdb63afb6d6264121fc834aadba7ba3d3796c32115b
old.ndjson_sha256=bd484ac9886a96f26b1d9a7a59ebd45b7a70d102c015d4f31f9302bbdd6ab2b9
old_challenge=MIT_original_five_roots
old_checker_exit=1
cross_version_comparison=NOT_ACCEPTED
previous_stage_new_control_exit=1
control_download_retry=PASS
control_retry_script_exit=3
new_control_checker_exit=0
new_control_justified_count=5
same_version_control=PASS
```

## B 精确旧 cube bridge

**NOT_RUN**：该 bridge 未单独比较，现有回执不能推断通过或失败。B 线按要求归档，不再重跑。

## C 原生合成

**NOT_RUN**：独立准备进行中，原生编译尚未启动，暂无退出码。固定 C 线提交 `642830bf082e5e6862e79a1b82ee1cd9e8d256e7` 已检出；MIT 配方包 SHA-256 `0c1fcdea71d15fa40abfadda964e654eddb1961596f095335314a14cb1d62ee6` 核对通过。目标版本：Lean 4.35.0 `eb6cafb7290e8bd5f2937522d8d804f58f02bafc`、Mathlib `56a005855ea17e0b0958f73ec801ae140b0a1679`、紧凑 RH `72fead102f663d5c7a407964a13dc0cf9d977207`、Schoenfeld `0e52d7b1a83fb548f6395546828a923a2e3d9627`。工具链下载及校验 PASS，下载和解压退出码均为 0；实际 Lean 版本及提交已核对。两项源码固定提交与洁净状态核对通过。独立 Mathlib 依赖和缓存准备 RUNNING，完成后复测资源，再决定启动原生编译。

## C 独立复验

**NOT_RUN**：尚无同次成功原生构建及最终导出，暂无退出码。检查器目标版本 `5dc36dc15b7bee891a02406b78a8ac816a47baad`；题面预期 SHA-256 `75a70364fb0d9026f3220cf0ebae361cefb2df217f82a0cbd3279407d6728968`。目标为 `CubePrime.primeBetweenCubes` 和 `CubePrime.primeStrictlyBetweenConsecutiveCubes`。

## 最新资源采样

2026-11-28 22:04（北京时间）：可用 CPU 24，系统可用内存约 114 GiB，cgroup 上限 120 GiB、用量约 6.47 GiB、失败计数 0；工作盘共享文件系统余量约 790 TiB，任务独立配额未能实测；`vm.max_map_count=2560000`，A 进程虚拟内存上限 unlimited。RH 构建 JSON 最近采样 7,255 个、4,566,243,686 字节。A 仍运行，原生及独立验收尚无退出码。
