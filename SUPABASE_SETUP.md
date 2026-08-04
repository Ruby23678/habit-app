# Supabase 配置说明（Habit Witness 网页版）

本应用已内置 Supabase 云端能力（认证 + PostgreSQL + 行级安全 RLS），
未配置时自动进入「本地试用模式」，原功能全部可用；配置后即可注册/登录并多设备同步数据。

---

## 一、创建 Supabase 项目（免费）

1. 打开 https://supabase.com 注册并登录（免费额度足够个人使用）。
2. 点击 **New project**，填写项目名称与数据库密码，选择离你近的区域（如 Singapore/Tokyo）。
3. 等待项目创建完成（约 1~2 分钟）。

## 二、执行建表 SQL（重要）

进入项目 Dashboard → 左侧 **SQL Editor** → 新建查询，粘贴下面全部 SQL 并运行：

```sql
-- 习惯表
create table public.habits (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  icon text default '🏃',
  target_days int not null default 30,
  start_date text,
  is_active boolean default true,
  frequency_type text default 'daily',
  weekly_days jsonb,
  created_at text
);
alter table public.habits enable row level security;
create policy "habits own" on public.habits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 打卡记录表
create table public.habit_records (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  habit_id uuid not null,
  date text not null,
  is_completed boolean default true,
  is_makeup boolean default false
);
alter table public.habit_records enable row level security;
create policy "records own" on public.habit_records
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 每日任务表
create table public.daily_tasks (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  date text not null,
  is_completed boolean default false
);
alter table public.daily_tasks enable row level security;
create policy "tasks own" on public.daily_tasks
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 日志表（含 tags 列，用于月度报告的习惯标签）
create table public.daily_logs (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date text not null,
  excitement text,
  low_moment text,
  resistance text,
  opposite_expectation text,
  emotion text,
  tomorrow_action text,
  filled_count int default 0,
  tags text
);
alter table public.daily_logs enable row level security;
create policy "logs own" on public.daily_logs
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
```

> 说明：所有表都带 `user_id` 并启用 RLS，用户只能读写自己的数据；
> 前端只使用 anon key，不会接触 service_role key。

## 三、获取配置并填入应用

1. 项目 Dashboard → 左侧 **Settings → API**（或 Project Settings → API）。
2. 复制两样东西：
   - **Project URL**（形如 `https://xxxx.supabase.co`）
   - **anon public key**（一长串 `eyJ...`）
3. 打开 `index.html`，搜索 `SUPABASE_URL` 和 `SUPABASE_ANON_KEY`，填入即可：

```js
var SUPABASE_URL='https://xxxx.supabase.co';       // 你的 Project URL
var SUPABASE_ANON_KEY='eyJhbGciOi...';             // 你的 anon public key
```

或者不修改文件：在打开页面之前注入 `window.__HW_CONFIG`：

```html
<script>
  window.__HW_CONFIG={supabaseUrl:'https://xxxx.supabase.co',supabaseKey:'eyJ...'};
</script>
```

## 四、部署到 Netlify / Vercel（保持原有部署方式）

- 本应用是**纯静态单文件**，无需构建、无需环境变量注入。
- Netlify：把 `index.html` 拖进 https://app.netlify.com/drop 即可。
- Vercel：新建项目 → 选择静态文件目录，或直接拖拽上传。
- 唯一要做的：把上面的 `SUPABASE_URL / SUPABASE_ANON_KEY` 填进 `index.html`
  （anon key 是公开的，写在前端是 Supabase 官方推荐做法，安全由 RLS 保证）。
- 部署后浏览器访问时若提示防火墙/网络正常，即可注册登录、数据同步。

## 五、功能与数据说明

- 注册：邮箱 + 至少 6 位密码；默认开启邮件确认时，需先点邮件里的链接再登录。
- 登录状态：Supabase Session 自动存入浏览器，关闭再打开会自动登录（Token 有效期内）。
- 首次登录：若检测到本机旧数据（localStorage），会弹出「导入到云端」；可确认导入或跳过，
  之后也能用页面右上角「⬆️ 导入本地数据」按钮再次导入。
- 同步方式：每次操作后自动全量同步到云端（含删除），支持多设备（同一账号）。
- 补签额度（每月 3 次）保存在本机，不跨设备共享；如需云端共享可后续加表。
- 未配置 Supabase 时：所有数据仍保存在本机浏览器 localStorage，与原版行为一致。