# ParaphraseTool App - Guide (Roman Urdu)

## Is folder mein kya hai
- `lib/` = app ka poora code (Flutter)
- `assets/` = aapki website ka logo aur mode icons
- `.github/workflows/build-apk.yml` = GitHub par APK khud banane wali file

## Step 1: Server par chhota update (pehle ye karein)
`server_update.zip` kholein aur:
1. `app/Http/Controllers/ApiParaphraseController.php` ko apne server ke `app/Http/Controllers/` folder mein copy karein.
2. `routes/api.php` ko apne server ke `routes/api.php` se replace karein (ya sirf aakhri 2 `Route::` lines add kar dein).
3. Agar route cache use hota hai to `php artisan route:clear` chalayein (ya `bootstrap/cache/routes-v7.php` delete kar dein).
4. Test: browser mein ye link kholein: https://www.paraphrasingtool.uk/api/app-config
   Jawab aisa aana chahiye: `{"word_limit":1000,"locked_modes":[4,5]}`

Website ka baqi koi code change nahi hota.

## Modes ab kaise kaam karte hain (server par)
| Mode | Kitne words badalte hain | Synonym ka intikhab |
|---|---|---|
| Basic | ~30% | sabse qareeb wala |
| Elegant | ~60% | lamba, refined lafz |
| Productive | ~85% | random |
| Premium (locked) | 100% | random, repeat se bachata hai |
| Enterprise (locked) | 100% | Premium jaisa |
| Humanize | ~70% | chhota, aam lafz + contractions (don't, it's) - sirf English |

Premium aur Enterprise app mein locked hain (Upgrade button website kholta hai).
Humanize abhi free hai. Lock karna ho to `ApiParaphraseController.php` mein `LOCKED_MODES = [4, 5, 6]` kar dein. App dobara build karne ki zaroorat nahi.

## Step 2: APK banana (GitHub par)
1. github.com par free account banayein, naya repository banayein (Private bhi chalega).
2. Is folder ki **saari files** repository mein upload karein (`.github` folder samet).
   Agar `.github` folder upload na ho to: Add file > Create new file, naam likhein `.github/workflows/build-apk.yml` aur us file ka text paste kar dein.
3. Repository ke **Actions** tab mein jayen > **Build APK** > **Run workflow**.
4. 8-12 minute baad build complete hogi. Us run par neeche **Artifacts** mein `ParaphraseTool-APK` download karein (zip ke andar `app-release.apk` hai).

## Step 3: Phone mein install
APK phone mein bhejein, kholein, "Install unknown apps" allow karein, install kar lein.

## Zaroori baatein
- Ye code is chat mein compile/test nahi ho saka (yahan Flutter SDK download nahi hota). Is liye pehli build mein koi chhota error aa sakta hai. Aisa ho to Actions ka error log mujhe bhej dein, main fix kar dunga.
- Ye APK testing aur direct share ke liye theek hai. Play Store ke liye alag signing key chahiye hogi.
- Server par `.sdata` dictionaries aur engine wahi hain jo website use karti hai, is liye result ka quality website jaisa hoga.
