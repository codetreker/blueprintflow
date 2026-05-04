# Security Review Checklist

> **Lazy reference**: 只在 Security 角色做 PR review 时引用走清单, 不进 SKILL.md 主体, 节省主流程 context。
>
> 用法: Security review 一个 PR 前, 先读本清单 12 类一遍, 按 PR 改动范围挑相关项查; 全过 → LGTM, 任一红 → NOT-LGTM 退 author 修。
>
> **粒度立场**: 本清单只列**维度 + 一句话查什么 + 反约束**, **不绑具体语言/框架/工具/路径**。每个项目按自己技术栈细化具体 grep 命令 / lint 规则 / 工具调用; 项目可在自己仓库的 `references/security-checklist-<stack>.md` 落具体执行细节, 本通用清单只锚维度。

---

## 1. 鉴权 / 授权

- **鉴权检查 (用户态/admin/anonymous 路径)**
  - 维度: 接口是否漏了登录态判断, anonymous 能否直调
  - 反约束: 凡是涉用户数据的接口都必须经过 auth 中间件
- **capability gate (用户能不能做这操作)**
  - 维度: 登录 ≠ 有权限, 是否有细粒度 capability 检查
  - 反约束: 写动作必查权限不只是查登录态
- **cross-org / tenant 数据隔离**
  - 维度: 用户拿别人 org 的 ID 进 query, 服务端是否按租户过滤
  - 反约束: 任何按 ID 查的接口必带租户/owner 范围限定
- **impersonate 路径 (admin god-mode)**
  - 维度: admin 能借身份操作普通用户数据是否有审计
  - 反约束: 凡是 admin 写动作必走 audit log + 必有 "代谁操作" 字段
- **cookie 域 / SameSite / HttpOnly / Secure flag**
  - 维度: cookie 是否限定子域 / 跨站防 / JS 读取防 / HTTP 路径防
  - 反约束: 所有 session/auth cookie 4 个 flag 全齐, 不允许默认值

## 2. 输入验证

- **SQL injection**
  - 维度: 用户输入是否能直接拼进 SQL 查询
  - 反约束: 任何拼字符串构造的 SQL 都要审, 必走参数化
- **XSS (跨站脚本)**
  - 维度: 用户输入直接渲染成 HTML 是否未转义
  - 反约束: 用户内容渲染必经过 sanitize 或转义
- **Command injection**
  - 维度: 用户输入是否被拼进 shell / exec 命令
  - 反约束: shell 调用参数必走数组形式不接受字符串拼接
- **Path traversal**
  - 维度: 用户控制的文件路径是否能逃出预期目录
  - 反约束: 用户路径必经过 normalize + 白名单根目录前缀检查
- **SSRF (server 端请求伪造)**
  - 维度: server 拿用户给的 URL 出网, 是否能访问内网/metadata
  - 反约束: 出网请求前必 resolve + 黑名单内网/loopback/metadata 网段
- **CSRF (跨站请求伪造)**
  - 维度: state-changing 操作是否走 GET / 是否缺 token / 是否依赖 SameSite
  - 反约束: 写动作必走非 GET method + 带 CSRF token 或严格 SameSite
- **反序列化**
  - 维度: 用户控制的结构是否能触发类型混淆 / prototype pollution
  - 反约束: 反序列化目标必为定义清楚的类型, 不接受任意结构

## 3. 敏感数据

- **密码 / token / API key 不入日志, 不入 client**
  - 维度: secret 是否被打日志 / 返给 client / 写进错误响应
  - 反约束: secret 字段在序列化/日志层有过滤
- **错误信息不泄露内部结构**
  - 维度: prod 是否把 stack trace / 数据库错误 / 内部路径返给用户
  - 反约束: prod error response 走 generic message, 内部细节只入服务端日志
- **PII 处理符合最小化原则**
  - 维度: 是否收集了不必要的 PII, 日志中 PII 是否脱敏
  - 反约束: 接口返 PII 必须业务必须 + 日志中 PII 必须脱敏
- **加密存储 (at-rest)**
  - 维度: 密码是否走单向慢哈希, 敏感数据是否加密存储
  - 反约束: 密码不允许明文/快速哈希, 必走业内通用慢哈希算法
- **TLS in-transit**
  - 维度: 数据传输是否走加密通道
  - 反约束: 生产环境配置不允许出现非加密 endpoint

## 4. 会话 / 凭证

- **session 失效路径**
  - 维度: logout / 改密码 / 异常登录是否真失效旧 session
  - 反约束: logout 必真删 session record + 改密码 invalidate all sessions
- **token 有效期 / refresh 机制**
  - 维度: access token 是否过长 / refresh 是否有 rotation
  - 反约束: access token 短期 + refresh token 有 rotation 机制
- **多设备登录策略**
  - 维度: 是否检测异常并发使用 / 是否有 device fingerprint
  - 反约束: 异常并发登录有提醒或拦截路径
- **暴力破解防护**
  - 维度: 登录接口是否有 rate limit + 失败 lockout
  - 反约束: 登录接口必有 per-IP + per-account rate limit

## 5. Rate limit / DoS

- **高频接口限流**
  - 维度: 单用户高频是否能打爆服务
  - 反约束: 所有公开接口必有限流, 关键接口配额可显式裁剪
- **资源消耗大接口限制**
  - 维度: 上传/搜索/导出是否有大小/行数/时长上限
  - 反约束: 大请求必走分页 + 异步队列或显式上限
- **递归/循环上限**
  - 维度: 解压/解析是否有深度/大小上限 (反 ZIP bomb / 深嵌套)
  - 反约束: 解析器必配深度上限 + 解压必配输出大小上限

## 6. 第三方依赖

- **新引入依赖审计**
  - 维度: 新依赖是否带已知 CVE
  - 反约束: CI 必跑依赖漏洞扫描, 高危必修
- **锁文件提交**
  - 维度: 依赖版本是否锁定, 不同环境是否复现
  - 反约束: 锁文件必入 git
- **升级路径有 CVE patch**
  - 维度: 长期不升级是否暴露已公开漏洞
  - 反约束: 必有周期性依赖升级流程

## 7. 配置 / 部署

- **secret 不进 git**
  - 维度: 是否有 .env / credentials / key 文件被 commit 进历史
  - 反约束: 所有 secret 文件必入 ignore, secret 走 env 注入
- **默认值 panic-fast 反 silent prod**
  - 维度: 缺关键 env 时是否 fallback 到默认值进 prod
  - 反约束: 关键安全 env 缺则启动 panic, 不允许 silent fallback
- **域名 / endpoint 不写死**
  - 维度: prod / test / staging endpoint 是否写死在代码里
  - 反约束: 环境相关 endpoint 必走 env 注入
- **运行时不以特权用户运行**
  - 维度: 容器/进程是否以 root 跑, 漏洞是否会放大成宿主权限
  - 反约束: 容器/进程必以非特权用户运行

## 8. 业务逻辑安全

- **IDOR (Insecure Direct Object Reference)**
  - 维度: 用户拿别人的 resource_id 调接口能否直接拿到别人数据
  - 反约束: 所有按 resource_id 的 get/update/delete 必查 owner / 租户范围
- **权限提升路径 (普通用户 → admin 漏洞)**
  - 维度: 用户更新 profile 类接口是否能改 role/admin/permission 字段
  - 反约束: 用户可改字段必走显式白名单, 不接受客户端传任意字段
- **race condition (并发 update / counter)**
  - 维度: 并发读-改-写是否有原子性保证
  - 反约束: 关键 counter / 余额走原子操作或事务 + 行锁
- **资金/积分类操作的事务完整性**
  - 维度: 多步操作中段失败是否能回滚 / 是否能 double-spend
  - 反约束: 资金类操作必走事务 + idempotency key + 状态机

---

## 用法 (Security review 流程)

1. PR open + 通知 Security review
2. 看 PR 改动范围 (改 handler / 前端 / 部署配置 / 依赖等)
3. 按改动范围对应到本清单 12 类挑相关项查
4. 一条条查 + 写 LGTM 评论 (或 NOT-LGTM 退 author 修)
5. LGTM 评论必带具体清单条目引用 (e.g. "§1 鉴权 ✅, §2 SQL injection ✅, §8 IDOR 已防")

## 项目特定细化

本清单只锚**维度**。具体项目按自己技术栈在仓库内补一份 `<repo>/references/security-checklist-<stack>.md` 落:

- 具体 grep 命令
- 具体框架 / 工具调用 (依赖审计 / lint 规则 / 静态扫描)
- 项目特定路径 / 模块边界

通用清单 (本文件) 不绑栈, 项目细化清单按需扩展。

## 反模式

- ❌ 不读清单只凭直觉 review (12 类有意义, 漏一类 = 漏一类风险面)
- ❌ LGTM 不引清单条目 (后续不可追溯, drift 抓不到)
- ❌ 把清单拷进 SKILL.md 主体 (lazy reference 模式失效, context 污染)
- ❌ 通用清单里写死具体语言/框架/工具/路径 (项目栈差异极大, 不通用)
- ❌ 清单条目只列 "什么" 不列 "为什么 / 反约束" (反 "清单不告诉为什么")
