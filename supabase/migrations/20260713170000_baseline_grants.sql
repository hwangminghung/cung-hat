-- FIX BUG PROD THAT (CI job db phat hien tu merge audit-hardening):
-- DB dung TUOI tu migrations khong co table grant cho `authenticated` va
-- `service_role` (default privileges cua image/CLI moi khong ap cho role chay
-- migration). Hau qua KHONG chi la 5 file pgTAP do:
--   * App doc bang truc tiep se "permission denied" tren moi deploy tuoi:
--     messages (lich su chat), music_genres/music_artists/songs (onboarding),
--     plans (man Ke hoach), consents (Cai dat).
--   * service_role BYPASS RLS nhung van can GRANT — edge functions
--     (validate-iap ghi purchases/entitlements, ingest-places-venues ghi
--     venues...) cung sap tren DB tuoi.
-- DB local lau nay co grants (state cu) nen moi thu "chay duoc" — CI moi la
-- chuan. Cap grant TOI THIEU (khong TRUNCATE/TRIGGER/REFERENCES nhu local
-- drift); RLS van la lop kiem soat that: bang khong co policy (vd
-- user_locations — toa do private) grant xong van 0 row voi authenticated.
-- `anon` CHU DICH khong duoc grant: truoc login khong co duong doc bang truc
-- tiep nao (RPC cho anon deu SECURITY DEFINER, vd resolve_share_plan).

grant select, insert, update, delete on all tables in schema public
  to authenticated, service_role;
grant usage, select on all sequences in schema public
  to authenticated, service_role;

-- Bang tao MOI trong cac migration tuong lai (chay boi cung role voi file nay)
-- tu dong co grant — khoi lap lai o tung dot.
alter default privileges in schema public
  grant select, insert, update, delete on tables to authenticated, service_role;
alter default privileges in schema public
  grant usage, select on sequences to authenticated, service_role;
