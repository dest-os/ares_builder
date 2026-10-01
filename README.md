# Ares Builder - Otonom APK Derleyici

Tablet için yatay çalışan Flutter uygulaması.
Yaptığı iş: proje ZIP'ini GitHub'a yükler, GitHub Actions ile APK derletir,
derleme ilerlemesini canlı gösterir ve bitince APK'yı cihaza kaydettirir.

## 1) İlk kurulum (bir kere)

1. GitHub'da yeni bir depo aç. Adı: `Ares-Builder` (farklı olabilir, uygulamada aynısını yazarsın).
2. Bu ZIP'in içindeki **tüm dosya ve klasörleri** depoya yükle.
   - `.github` klasörü gizli klasördür, yüklendiğinden emin ol.
     Yüklenmediyse: GitHub'da **Add file > Create new file**, dosya adı kutusuna
     `.github/workflows/build_apk.yml` yaz ve aynı adlı dosyanın içeriğini yapıştır.
3. Yükleme bitince depoda **Actions** sekmesine gir. Derleme kendiliğinden başlar
   (yaklaşık 8-12 dakika). Bitince "AresBuilder-Release-APK" paketini indirip içinden
   `app-release.apk` dosyasını telefona/tablete kur.
4. Derleme kırmızı biterse, hata satırlarının ekran görüntüsünü bana gönder.

## 2) GitHub token (PAT) hazırlama

GitHub > Settings > Developer settings > Personal access tokens > **Fine-grained tokens**
1. Repository access: **Only select repositories** > sadece `Ares-Builder`
2. Permissions (Repository):
   - **Contents**: Read and write
   - **Actions**: Read and write
   - **Workflows**: Read and write
   - **Metadata**: Read-only (kendiliğinden gelir)
3. Token'ı kopyala. Sayfayı kapatınca bir daha görünmez.

Kolay yol: "Tokens (classic)" ile `repo` ve `workflow` kutularını işaretlemek de çalışır,
ama bu token tüm depolarına erişir. Fine-grained önerilir.

## 3) Uygulamayı kullanma

1. Sağ üstteki altıgen simgeye dokun > Ayarlar.
2. GitHub kullanıcı adını ve token'ı yaz. "Hedef Depo" kutusuna **depo adı/branch** yaz
   (örnek: `Ares-Builder/main`) > **Bilgileri Kaydet & Doğrula**.
   Sağ alttaki mesaj satırında yeşil "✓ Bağlantı başarılı" görmelisin.
3. (İsteğe bağlı) API anahtarlarını sağdaki listeye gir (sıra soldaki logolarla aynı).
   Zincirde en fazla 8 satır olur; satırın adına dokununca açılıp kapanır, model adına dokununca model seçilir.
   API anahtarlarını gir ve **Test** ile dene. Bu sürümde anahtarlar sadece
   saklanır ve test edilir; otomatik hata düzeltme bir sonraki aşamada bağlanacak.
4. Ana ekranda sol alttaki **Dosya / Kod Yükle / Düzenle** ile projenin ZIP'ini seç.
5. Sağ alttaki **APK Oluştur, Derle & Dağıt**'a dokun. Sol çubuk yükleme, sağ çubuk derleme
   ilerlemesini gösterir. Log paneli her adımı yazar.
6. Derleme bitince "APK'yı kaydet" penceresi açılır. Bir klasör seç, sonra Dosyalar'dan APK'ya dokunup kur.
7. Eski derlemeler için **Geçmiş APK'lar / İndir** butonunu kullan.

## Notlar

- Yüklediğin ZIP'te derleme dosyası yoksa uygulama `.github/workflows/build_apk.yml` dosyasını kendisi ekler.
- Projede `android` klasörü yoksa derleme sırasında otomatik oluşturulur.
- Kod alanındaki metni değiştirirsen, sadece o açık dosya (ör. `lib/main.dart`) güncellenir.
- Her derleme farklı bir debug anahtarıyla imzalanır. Yeni APK'yı eskisinin üstüne kuramazsan önce eskisini sil.
- Yedek JSON dosyasına GitHub token'ı hiçbir zaman yazılmaz. API anahtarları yalnızca sen onaylarsan yazılır.
