# PhishSim — Rails 8 sürümü

Bu dizin, `bitirme-projesi-main` klasöründeki React/Vite + Flask prototipinin
**Rails 8 üzerine baştan inşa edilmiş** karşılığıdır. Aynı mantığı tek bir
Rails uygulamasında birleştirir:

- **Admin paneli** (`/admin`) — React'teki Dashboard, Campaigns, Analytics
  sayfalarının Tailwind + ERB karşılığı.
- **Sahte Microsoft login sayfası** (`/auth`) — eski `auth.html` + `main.py`
  `/login` endpoint'inin karşılığı. Girilen kimlik bilgisini `Credential`
  kaydı olarak DB'ye yazar ve kullanıcıyı gerçek `login.microsoftonline.com`
  adresine yönlendirir.
- **PhishingMailer** — `send_email()` fonksiyonunun karşılığı. Dev
  ortamında `letter_opener` sayesinde mail gerçekten gönderilmez;
  tarayıcıda önizleme açılır.

## Stack

| Katman    | Seçim |
|-----------|-------|
| Runtime   | Ruby 3.3.5, Rails 8.0 |
| DB        | SQLite (storage/development.sqlite3) |
| View      | ERB + Tailwind CSS (tailwindcss-rails gem) |
| JS        | Hotwire Turbo + Stimulus (importmap) |
| Mail      | ActionMailer + letter_opener (dev) |

## Kurulum

```bash
cd rails-app

# 1) Bağımlılıklar
bundle install

# 2) Tailwind CSS build için (ilk kurulumda gerekir)
bin/rails tailwindcss:install

# 3) Veritabanı
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# 4) Sunucu + Tailwind watcher
bin/dev
# (foreman yoksa bin/dev bir kez foreman'ı kurar)
```

Alternatif olarak ayrı terminallerde:

```bash
bin/rails server                 # http://localhost:3000
bin/rails tailwindcss:watch      # stylesheet recompile
```

## URL'ler

| URL | Karşılık | Açıklama |
|-----|----------|----------|
| `http://localhost:3000/` | — | `/admin`'e yönlendirir |
| `http://localhost:3000/admin` | `Index.tsx` | KPI'lar + kampanya tablosu |
| `http://localhost:3000/admin/campaigns` | `Campaigns.tsx` | Kampanya listesi |
| `http://localhost:3000/admin/campaigns/new` | `Campaigns.tsx` | Campaign Builder formu |
| `http://localhost:3000/admin/analytics` | `Analytics.tsx` | Funnel grafiği |
| `http://localhost:3000/admin/credentials` | *yeni* | Yakalanan credentials listesi |
| `http://localhost:3000/auth` | `auth.html` | Sahte MS login sayfası |
| `http://localhost:3000/auth/:token` | — | Kampanya linki; kime tıkladığını izler |

## Veri modeli

```
Campaign  1──*  EmailEvent  *──1  Target
Campaign  1──*  Credential        Credential *──1 Target
```

- **Campaign** — kampanya ayarları + agregat KPI (emails_sent, links_clicked, creds_captured).
- **Target** — phishing hedefi (öğrenci/personel). Her hedefin tekil `token`'u var.
- **EmailEvent** — `sent / opened / clicked / submitted` (funnel için).
- **Credential** — `/auth/login` POST'una düşen kimlik bilgisi.

## Mantık / akış

1. Admin `/admin/campaigns/new` üzerinden kampanyayı tasarlar.
2. `Send Campaign` butonu → `Admin::CampaignsController#send_now`:
   - Hedef gruba göre `Target`'ları çeker.
   - Her biri için `PhishingMailer.campaign_email` çağrılır.
   - letter_opener sayesinde dev'de mail tarayıcıda açılır.
   - Her gönderim için `EmailEvent(event_type: "sent")` kaydı atılır.
3. Hedef mail içindeki linke tıkladığında `/auth/:token` açılır:
   - `AuthController#show` → `clicked` event'i, `links_clicked += 1`.
   - Sahte Microsoft login formu render edilir.
4. Kullanıcı formu doldurup submit ederse `AuthController#login`:
   - `Credential` kaydı oluşturulur.
   - `submitted` event'i, `creds_captured += 1`.
   - Gerçek `login.microsoftonline.com`'a meta-refresh + JS redirect.
5. Admin panelindeki KPI'lar (CTR, Data Breach Rate, Credential Submission
   Rate) bu agregatlardan canlı hesaplanır.

## Seed verisi

`db/seeds.rb` 60 sahte hedef + 4 kampanya + rastgele event/credential
üretir. Böylece dashboard'u boş değil, React prototipindeki gibi dolu
görürsün. `bin/rails db:seed` her çalıştığında verileri sıfırlar.

## Güvenlik notu

> Bu proje, **Kadir Has Üniversitesi** bitirme projesi kapsamında
> farkındalık eğitimi için hazırlanmıştır. Başkalarının kimlik bilgilerini
> rızasız toplamak için **kesinlikle** kullanılmamalıdır. `letter_opener`
> sayesinde dev modda dışarı mail çıkmaz. Prod mail ayarları bilinçli
> olarak kapalı bırakılmıştır.

## Eski proje ile eşleşme

| React / Flask (eski) | Rails (yeni) |
|----------------------|--------------|
| `src/pages/Index.tsx` | `app/views/admin/dashboard/index.html.erb` |
| `src/pages/Campaigns.tsx` | `app/views/admin/campaigns/_form.html.erb` |
| `src/pages/Analytics.tsx` | `app/views/admin/analytics/index.html.erb` |
| `src/components/DashboardSidebar.tsx` | `app/views/layouts/admin.html.erb` |
| `auth.html` | `app/views/auth/show.html.erb` |
| `main.py /login` | `AuthController#login` |
| `main.py send_email()` | `PhishingMailer#campaign_email` |
| `creds.txt` | `credentials` tablosu |
