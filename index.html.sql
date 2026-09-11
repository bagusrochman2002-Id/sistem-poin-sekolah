-- ============================================================
-- SKEMA SUPABASE — Sistem Poin Kedisiplinan Siswa
-- SMK Muhammadiyah 2 Samarinda
-- ============================================================
-- Cara pakai:
-- 1. Buat project baru di https://supabase.com (gratis untuk mulai).
-- 2. Buka menu "SQL Editor" di dashboard project, tempel seluruh isi
--    file ini, lalu klik "Run".
-- 3. Buat akun login untuk Kesiswaan/BK/Kepsek di menu
--    Authentication -> Users -> Add user (isi email & password).
-- 4. Untuk tiap akun yang dibuat, salin User UID-nya, lalu jalankan
--    perintah INSERT di bagian paling bawah file ini (contoh sudah
--    disediakan) supaya nama & perannya dikenali aplikasi.
-- 5. Ambil Project URL & anon public key di Project Settings -> API,
--    lalu tempelkan ke SUPABASE_URL dan SUPABASE_ANON_KEY di file
--    sistem-poin-kesiswaan-online.html.
-- ============================================================

-- Ekstensi untuk id acak (biasanya sudah aktif secara default)
create extension if not exists "pgcrypto";

-- ------------------------------------------------------------
-- 1. Tabel profil pengguna (nama & peran setiap akun login)
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nama text not null,
  role text not null check (role in ('Kesiswaan','BK','Kepala Sekolah','Wali Kelas','Admin')),
  created_at timestamptz default now()
);

alter table public.profiles enable row level security;

create policy "profil bisa dibaca semua akun login"
  on public.profiles for select
  to authenticated
  using (true);

-- (insert/update profil sengaja tidak dibuka untuk role authenticated;
--  admin mengatur lewat SQL Editor / dashboard, lihat contoh di bawah)

-- ------------------------------------------------------------
-- 2. Tabel data siswa
-- ------------------------------------------------------------
create table if not exists public.siswa (
  id uuid primary key default gen_random_uuid(),
  nama text not null,
  nisn text,
  kelas text not null,
  poin int not null default 100,
  created_at timestamptz default now()
);

alter table public.siswa enable row level security;

create policy "siswa: semua akun login bisa lihat"
  on public.siswa for select to authenticated using (true);

create policy "siswa: hanya role tertentu bisa ubah"
  on public.siswa for all to authenticated
  using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) )
  with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) );

-- ------------------------------------------------------------
-- 3. Tabel riwayat pelanggaran
-- ------------------------------------------------------------
create table if not exists public.pelanggaran_log (
  id uuid primary key default gen_random_uuid(),
  siswa_id uuid references public.siswa(id) on delete cascade,
  nama_siswa text not null,
  kelas text,
  tanggal date not null,
  kode int,
  jenis text,
  kategori text,
  poin int not null,
  catatan text,
  pencatat text,
  role text,
  semester text,
  created_at timestamptz default now()
);

alter table public.pelanggaran_log enable row level security;

create policy "log: semua akun login bisa lihat"
  on public.pelanggaran_log for select to authenticated using (true);

create policy "log: hanya role tertentu bisa ubah"
  on public.pelanggaran_log for all to authenticated
  using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) )
  with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) );

-- ------------------------------------------------------------
-- 4. Tabel pengaturan sekolah (satu baris saja, id selalu = 1)
-- ------------------------------------------------------------
create table if not exists public.sekolah_settings (
  id int primary key default 1,
  nama text,
  alamat text,
  kepsek text,
  semester text
);

insert into public.sekolah_settings (id, nama, alamat, kepsek, semester)
values (1, 'SMK Muhammadiyah 2 Samarinda', 'Samarinda, Kalimantan Timur', 'La Aida, S.E.', 'Ganjil 2026/2027')
on conflict (id) do nothing;

alter table public.sekolah_settings enable row level security;

create policy "settings: semua akun login bisa lihat"
  on public.sekolah_settings for select to authenticated using (true);

create policy "settings: hanya role tertentu bisa ubah"
  on public.sekolah_settings for all to authenticated
  using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) )
  with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('Kesiswaan','Wali Kelas','Admin')) );

-- ============================================================
-- CONTOH: mendaftarkan profil (nama & peran) untuk akun yang sudah
-- dibuat di Authentication -> Users. Ganti UID & datanya sesuai akun
-- masing-masing, lalu jalankan satu per satu di SQL Editor.
-- ============================================================
-- insert into public.profiles (id, nama, role) values
--   ('tempel-uid-akun-kesiswaan-di-sini', 'Bagus Fathur Rochman, S.Kom', 'Kesiswaan');
-- insert into public.profiles (id, nama, role) values
--   ('tempel-uid-akun-bk-di-sini', 'Nama Guru BK', 'BK');
-- insert into public.profiles (id, nama, role) values
--   ('tempel-uid-akun-kepsek-di-sini', 'La Aida, S.E.', 'Kepala Sekolah');
