# Security Review Checklist

> **Lazy reference**: 只在 Security 角色做 PR review 时引用走清单, 不进 SKILL.md 主体, 节省主流程 context。
>
> 用法: Security review 一个 PR 前, 先读本清单 12 类一遍, 按 PR 改动范围挑相关项查; 全过 → LGTM, 任一红 → NOT-LGTM 退 author 修。

---

## 1. 鉴权 / 授权

- **鉴权检查 (用户态/admin/anonymous 路径)** — 为什么: 接口是不是漏了登录态判断, anonymous 能不能直调 / 验: `grep -nE "func.*Handler|router\.(Get|Post)" + 看每个 handler 是否经过 auth middleware`
- **capability gate (用户能不能做这操作)** — 为什么: 登录 ≠ 有权限做此事, 缺细粒度 capability 检查 / 验: 看 handler 内是否有 `RequireCapability("...")` / `permission.Check(...)` 类语句
- **cross-org / tenant 数据隔离** — 为什么: 用户拿别人 org 的 ID 进 query, 服务端没按 `org_id = current_user.org_id` 过滤就泄露 / 验: `grep -nE "WHERE.*id|FindByID" + 看是否有 org_id / tenant_id 过滤`
- **impersonate 路径 (admin god-mode 红线)** — 为什么: admin 能借身份操作普通用户数据, 没 audit 就是黑盒 / 验: 凡是 admin 写动作必走 audit log + impersonate 必有"代谁操作"字段
- **cookie 域 / SameSite / HttpOnly / Secure flag** — 为什么: cookie 域错配导致跨子域泄露; 缺 HttpOnly 让 XSS 偷 session; 缺 Secure 让 HTTP 路径泄露 / 验: `grep -rnE "SetCookie|Set-Cookie" + 检查 Domain/SameSite/HttpOnly/Secure 四个 flag 全齐`

## 2. 输入验证

- **SQL injection (ORM 用法 / raw query)** — 为什么: 字符串拼 SQL 是最经典注入 / 验: `grep -rnE "fmt\.Sprintf.*SELECT|\"SELECT.*\" \+|raw\(|\.Exec\(.*\+"` 应 0 hit (除白名单)
- **XSS (innerHTML / dangerouslySetInnerHTML / unescaped output)** — 为什么: 用户输入直渲染成 HTML 就是 XSS / 验: `grep -rnE "innerHTML|dangerouslySetInnerHTML|v-html" + 看是否经过 sanitize`
- **Command injection (shell exec / spawn 用户输入)** — 为什么: shell exec 拼接用户输入 = RCE / 验: `grep -rnE "exec\.Command|child_process\.(exec|spawn)" + 看参数是否数组形式 (非字符串拼接)`
- **Path traversal (文件路径用户控制)** — 为什么: `../../../etc/passwd` 经典攻击 / 验: 用户控制路径前必走 `filepath.Clean` + 白名单根目录前缀检查
- **SSRF (server 拿用户 URL 出网请求)** — 为什么: 用户给 URL 让 server 拉, 能拿到 169.254.169.254 metadata / 内网服务 / 验: 出网请求前必 resolve + 黑名单内网/loopback 网段
- **CSRF (state-changing GET / 缺 token)** — 为什么: state-changing 操作走 GET 或不带 CSRF token = 跨站可伪造 / 验: 看写动作走 POST + 带 token / SameSite=Strict cookie
- **反序列化 (JSON.parse / unmarshal 用户控制结构)** — 为什么: 用户控制结构能触发 prototype pollution / 类型混淆 / 验: 反序列化目标必为定义清楚的 struct, 不接受 `interface{}` / `any` 类用户输入

## 3. 敏感数据

- **密码 / token / API key 不入日志, 不入 client** — 为什么: log 是审计常看路径, secret 入日志 = 半泄露; 入 client 直接全泄露 / 验: `grep -rnE "log.*password|log.*token|log.*secret|log.*api_?key"` 应 0 hit
- **错误信息不泄露内部结构 (stack trace / SQL error)** — 为什么: prod 把 stack trace / SQL error 返给用户暴露内部架构 / 验: prod error response 必走 generic message, 内部细节只入服务端 log
- **PII (邮箱/手机/身份证/IP) 处理符合最小化原则** — 为什么: 收集越多泄露面越大 / 验: 看接口返 PII 是否真业务必须, log 中 PII 是否脱敏 (邮箱中段星号 / IP 后两段截掉)
- **加密存储 (at-rest, e.g. password bcrypt 而非明文/MD5)** — 为什么: DB 泄露后明文/MD5 等于直接送; bcrypt/argon2 是底线 / 验: `grep -rnE "md5|sha1.*password|password.*md5"` 应 0 hit; password 必走 bcrypt/argon2
- **TLS in-transit (HTTP → HTTPS, ws → wss)** — 为什么: HTTP 中间人嗅探 / 验: 配置文件 + 文档 grep `http://[^l]` 看有没有非 localhost 的 HTTP

## 4. 会话 / 凭证

- **session 失效路径 (logout / 密码改 / 异常登录)** — 为什么: logout 不真失效 / 改密码不踢旧 session / 异常登录不通知 / 验: 看 logout handler 是否真删 session record + 改密码是否 invalidate all sessions
- **token 有效期 / refresh 机制** — 为什么: 长期 token 一旦泄露窗口大 / 没 refresh 用户体验差 / 验: access token ≤1h + refresh token 有 rotation 机制
- **多设备登录策略** — 为什么: 攻击者偷 token 后跟用户并发用, 没策略检测不到 / 验: 看是否记录 device fingerprint + 异常并发提醒
- **暴力破解防护 (rate limit / lockout)** — 为什么: 登录接口无 rate limit = 撞库天堂 / 验: 登录接口有 rate limit (per IP + per account) + N 次失败 lockout

## 5. Rate limit / DoS

- **高频接口限流** — 为什么: 单用户高频打爆服务 / 验: 看 middleware 是否有 rate limit + 关键接口配额合理
- **资源消耗大接口 (上传 / 搜索 / 导出) 限制** — 为什么: 上传无大小限制 = 磁盘炸; 全表搜索 = DB 卡; 大导出 = 内存 OOM / 验: 上传 size limit + 搜索分页 + 导出限行数 / 异步队列
- **递归/循环上限 (反 ZIP bomb / 深度嵌套 JSON)** — 为什么: ZIP bomb 解压炸内存 / 深嵌套 JSON 解析栈溢 / 验: ZIP 解压有解压上限 + JSON parser 深度限制

## 6. 第三方依赖

- **新引入依赖审计 (npm audit / govulncheck)** — 为什么: 依赖里带 CVE 等于自带漏洞 / 验: CI 跑 `npm audit` / `govulncheck` / `pip-audit`, 高危必修
- **锁文件提交 (package-lock / go.sum)** — 为什么: 锁文件不提 = 不同机器装到不同版本 = 不可复现的安全风险 / 验: `git ls-files | grep -E "package-lock\.json|go\.sum|Pipfile\.lock"` 应有
- **升级路径有 CVE patch** — 为什么: 长期不升级 = 暴露已公开漏洞 / 验: 周期性 dep bump (e.g. dependabot / renovate) 流程在跑

## 7. 配置 / 部署

- **secret 不进 git (.env / .env.local 入 gitignore)** — 为什么: secret 进 git 历史 = 永久泄露 (rebase 也清不掉) / 验: `git ls-files | grep -E "\.env$|\.env\.local"` 应 0 hit; `.gitignore` 有 `.env*` 排除
- **默认值 panic-fast 反 silent prod (CORS_ORIGIN / ADMIN_PASSWORD 模式)** — 为什么: 缺 env 时 fallback 到默认 = 默认值进 prod = 弱口令/全 origin / 验: 关键 env 缺 → 启动 panic, 不接受 fallback
- **域名 / endpoint 不写死 (env 注入)** — 为什么: 写死后无法切环境, 测试环境改动可能漏改 prod / 验: `grep -rnE "https?://[a-z]" 业务代码` 应只命中文档/测试/env 注入位
- **Docker base image 安全 (官方 / 最新 / 非 root user)** — 为什么: 用 root 跑容器, 漏洞放大成宿主机 root / 验: Dockerfile 有 `USER non-root` + base image 来自官方且近期 (≤6 月)

## 8. 业务逻辑安全

- **IDOR (Insecure Direct Object Reference)** — 为什么: 用户拿别人的 resource_id 调接口能直接拿到别人数据 / 验: 每个 resource get/update/delete 接口必检查 resource.owner_id == current_user.id (或 org 隔离)
- **权限提升路径 (普通用户 → admin 漏洞)** — 为什么: 客户端可改字段直接发, 服务端没 strip / 验: 用户更新 profile 接口必 strip role/admin/permission 字段, 不接受客户端传
- **race condition (并发 update / counter)** — 为什么: 两个并发请求同时读-改-写, 后者覆盖前者; counter 漏数 / 验: 关键 counter / 余额走 DB 原子操作 (`UPDATE ... SET x = x + 1`) 或事务 + 行锁
- **资金/积分类操作的事务完整性 (反 double-spend)** — 为什么: 扣款成功但发货失败 / 同一笔扣两次 / 验: 资金操作必走 DB transaction + idempotency key + 状态机 (pending/confirmed/failed)

---

## 用法 (Security review 流程)

1. PR open + 通知 Security review
2. `gh pr view <N> --json files` 看改动文件
3. 按改动文件类型对应到本清单 12 类 (e.g. 改 handler → §1 §2 §3; 改前端 → §2 §3; 改 Dockerfile → §7)
4. 一条条查 + 写 LGTM 评论 (或 NOT-LGTM 退 author 修)
5. LGTM 评论必带具体清单条目引用 (e.g. "§1 鉴权 ✅, §2 SQL injection ✅, §8 IDOR 见 line 42 已防")

## 反模式

- ❌ 不读清单只凭直觉 review (12 类有意义, 漏一类 = 漏一类风险面)
- ❌ LGTM 不引清单条目 (后续不可追溯, drift 抓不到)
- ❌ 把清单拷进 SKILL.md 主体 (lazy reference 模式失效, context 污染)
- ❌ 清单条目只列 "什么" 不列 "为什么 + 怎么验" (反 "清单不告诉为什么")
