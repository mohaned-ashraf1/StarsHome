-- ============================================================
-- STARS HOMES ERP — Migration 13: Activity Logs & Backup Records Schema
-- توفير جداول سجل العمليات والتدقيق وإدارة سجلات النسخ الاحتياطي مع سياسات الأمان
-- ============================================================

-- ── 1. جدول سجل العمليات والتدقيق (ACTIVITY / AUDIT LOGS) ────────
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_name TEXT NOT NULL,
    user_role TEXT DEFAULT 'manager',
    device_id TEXT,
    action TEXT NOT NULL,
    module TEXT NOT NULL,
    entity_table TEXT,
    entity_id TEXT,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- إضافة الأعمدة إن كانت موجودة مسبقاً بنسخة أقدم
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS user_role TEXT DEFAULT 'manager';
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS device_id TEXT;
ALTER TABLE public.audit_logs ADD COLUMN IF NOT EXISTS module TEXT DEFAULT 'general';

-- فهارس للبحث السريع في السجلات
CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at ON public.audit_logs (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_module ON public.audit_logs (module);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_name ON public.audit_logs (user_name);

-- ── 2. جدول سجلات النسخ الاحتياطي (BACKUP RECORDS) ──────────────
CREATE TABLE IF NOT EXISTS public.backup_records (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    filename TEXT NOT NULL,
    backup_type TEXT NOT NULL CHECK (backup_type IN ('manual', 'automatic', 'before_restore', 'before_update')),
    storage_destination TEXT NOT NULL DEFAULT 'local',
    file_size BIGINT DEFAULT 0,
    sha256_hash TEXT,
    device_id TEXT,
    created_by TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'failed', 'restored')),
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_backup_records_created_at ON public.backup_records (created_at DESC);

-- ── 3. سياسات الأمان ومنع التلاعب (SECURITY & IMMUTABILITY) ──────
-- تمكين RLS
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.backup_records ENABLE ROW LEVEL SECURITY;

-- السماح بالقراءة والإضافة لكافة مستخدمي المصنع المفوضين
DROP POLICY IF EXISTS "Allow select audit_logs" ON public.audit_logs;
CREATE POLICY "Allow select audit_logs" ON public.audit_logs FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert audit_logs" ON public.audit_logs FOR INSERT WITH CHECK (true);
-- لا يُسمح بأي سياسة UPDATE أو DELETE على audit_logs لضمان النزاهة التامة ومنع التلاعب بالسجلات!

DROP POLICY IF EXISTS "Allow select backup_records" ON public.backup_records;
CREATE POLICY "Allow select backup_records" ON public.backup_records FOR SELECT USING (true);

DROP POLICY IF EXISTS "Allow insert backup_records" ON public.backup_records FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Allow update backup_records" ON public.backup_records FOR UPDATE USING (true);

-- ── 4. التعليقات والتوثيق بالعربية في الداشبورد ─────────────────
COMMENT ON TABLE public.audit_logs IS 'سجل تدقيق ورقابة العمليات المنفذة في المصنع — يسجل من قام بالعملية، نوعها، وقتها، والجهاز';
COMMENT ON COLUMN public.audit_logs.user_name IS 'اسم المستخدم أو الدور الذي نفذ العملية';
COMMENT ON COLUMN public.audit_logs.action IS 'نوع الإجراء (تسجيل دخول، إنشاء طلب، حذف، استرجاع، إلخ)';
COMMENT ON COLUMN public.audit_logs.module IS 'القسم التابع له الإجراء (العملاء، العمال، الحسابات، النسخ الاحتياطي)';

COMMENT ON TABLE public.backup_records IS 'سجل عمليات النسخ الاحتياطي السحابية والمحلية وبيانات التحقق الرقمي SHA-256';
