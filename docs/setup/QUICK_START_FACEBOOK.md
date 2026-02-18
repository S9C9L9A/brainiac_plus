# 🎯 COME TESTARE LE AUTOMAZIONI FACEBOOK - Guida Rapida

## ⚡ Quick Start (3 passi)

### 1️⃣ Genera un Token Facebook Valido

Il token che hai fornito è **scaduto**. Devi generarne uno nuovo:

**➡️ Vai qui:** https://developers.facebook.com/tools/explorer/

**Fai così:**
1. In alto a destra, seleziona "Meta App" → `2102048307277114`
2. Clicca "Generate Access Token"
3. Quando richiede i permessi, seleziona:
   - ✅ `pages_show_list`
   - ✅ `pages_manage_posts`
   - ✅ `pages_read_engagement`
4. Copia il token che appare (sarà lungo tipo "EAAd3zUKn7To...")

**⚠️ IMPORTANTE:** Questo token dura solo 1-2 ore! Se vuoi un token che dura 60 giorni, dopo averlo ottenuto esegui:

```bash
# Sostituisci IL_TUO_TOKEN con il token appena ottenuto
curl -X GET "https://graph.facebook.com/v18.0/oauth/access_token?\
grant_type=fb_exchange_token&\
client_id=2102048307277114&\
client_secret=5cc547de365531456ec19ddc1a335cb7&\
fb_exchange_token=IL_TUO_TOKEN"
```

---

### 2️⃣ Verifica che il Backend sia Attivo

Il backend Go **è già in esecuzione** su porta 8080.

Verifica con:
```bash
curl http://localhost:8080/health
```

Dovresti vedere:
```json
{
  "status": "ok",
  "version": "2.0.0-alpha"
}
```

✅ Se vedi questo, il backend funziona!

❌ Se non funziona, avvialo con:
```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
go run main.go &
```

---

### 3️⃣ Esegui il Test

Hai **3 modi** per testare le automazioni Facebook:

---

## 🔧 Metodo A: Script Interattivo (CONSIGLIATO)

Il più semplice, ti guida passo-passo:

```bash
cd /home/giuseppe-genna/brainiac_plus
./test_facebook_interactive.sh
```

Lo script ti chiederà:
1. Incolla il token (quello ottenuto al passo 1)
2. Ti mostrerà le tue info utente
3. Ti mostrerà le tue pagine Facebook
4. Ti chiederà se vuoi pubblicare un post di test
5. Opzionalmente salva il token nel file .env

**✨ Questo è il metodo più facile!**

---

## 📱 Metodo B: App Flutter con UI

Più visuale, con interfaccia grafica:

```bash
cd /home/giuseppe-genna/brainiac_plus
flutter run -d linux
```

Quando l'app si apre:
1. Vai su "Automations" (icona ⚡)
2. Clicca sull'icona Facebook (📘 in alto a destra)
3. Incolla il token nel campo "Access Token"
4. Clicca "Valida Token"
5. Clicca "Carica Pagine"
6. Seleziona una pagina
7. Scrivi un messaggio
8. Clicca "Pubblica Post"

---

## 💻 Metodo C: Test Manuale con cURL

Per gli smanettoni:

```bash
# Sostituisci YOUR_TOKEN con il tuo token valido
TOKEN="YOUR_TOKEN"

# Test 1: Verifica token
curl "https://graph.facebook.com/v18.0/me?fields=id,name,email&access_token=$TOKEN"

# Test 2: Autenticazione backend
curl -X POST http://localhost:8080/api/facebook/auth \
  -H "Content-Type: application/json" \
  -d "{\"access_token\": \"$TOKEN\"}"

# Test 3: Recupera pagine
curl -X GET http://localhost:8080/api/facebook/pages \
  -H "X-Facebook-Token: $TOKEN"

# Test 4: Pubblica post (sostituisci PAGE_ID e PAGE_TOKEN)
curl -X POST http://localhost:8080/api/facebook/post \
  -H "Content-Type: application/json" \
  -d '{
    "page_id": "PAGE_ID",
    "page_token": "PAGE_TOKEN",
    "message": "🧠 Test automatico da BrainiacPlus!"
  }'
```

---

## 🎬 Esempio Completo di Test Riuscito

Ecco cosa vedrai se tutto funziona:

```bash
$ ./test_facebook_interactive.sh

==================================================
🧠 BrainiacPlus - Test Automazioni Facebook
   Interactive Token Setup
==================================================

🔍 Controllo backend...
✅ Backend attivo su porta 8080

📝 Per ottenere un token valido:
   1. Vai su: https://developers.facebook.com/tools/explorer/
   ...

🔑 Incolla il tuo Facebook Access Token: [TUO_TOKEN]

==================================================
🧪 Iniziando i test...
==================================================

📌 Test 1: Verifica Token con Facebook API
--------------------------------------------------
✅ Token valido!
   👤 Nome: Mario Rossi
   🆔 ID: 123456789
   📧 Email: mario@example.com

📌 Test 2: Autenticazione Backend
--------------------------------------------------
✅ Autenticazione backend riuscita!

📌 Test 3: Verifica Permessi
--------------------------------------------------
✅ Permessi attivi:
   ✓ pages_show_list
   ✓ pages_manage_posts
   ✓ public_profile

📌 Test 4: Recupero Pagine Facebook
--------------------------------------------------
✅ Trovate 2 pagina/e:

   1. 📄 La Mia Pagina Test
      ID: 109876543210
   2. 📄 Altra Pagina
      ID: 109876543211

🎯 Vuoi testare la pubblicazione di un post? (s/n): s
   Scegli il numero della pagina (1-2): 1

📝 Pagina selezionata: La Mia Pagina Test
   Scrivi il messaggio del post (ENTER per usare messaggio di test): 

📤 Pubblicando post...
✅ Post pubblicato con successo!
   🆔 Post ID: 109876543210_987654321
   📄 Pagina: La Mia Pagina Test
   💬 Messaggio: 🧠 Test automatico da BrainiacPlus! Timestamp: 2026-02-16 10:50:00

==================================================
✅ Test completati!
==================================================
```

---

## ❓ FAQ - Domande Frequenti

### Q: "Il token non funziona, dice 'invalid'"
**A:** Il token è scaduto. I token Facebook hanno durata limitata:
- Token short-lived: 1-2 ore
- Token long-lived: 60 giorni
Genera un nuovo token seguendo il passo 1.

### Q: "Non vedo nessuna pagina"
**A:** Possibili cause:
1. Non sei admin/editor di nessuna pagina Facebook → Crea una pagina o chiedi i permessi
2. Il token non ha il permesso `pages_show_list` → Rigenera il token con i permessi corretti
3. La pagina è in modalità restricted → Verifica le impostazioni della pagina

### Q: "Il backend non si connette"
**A:** 
```bash
# Controlla se è in esecuzione
ps aux | grep "go run main.go"

# Se non c'è, avvialo
cd /home/giuseppe-genna/brainiac_plus/go_backend
go run main.go &

# Aspetta 5 secondi poi testa
sleep 5
curl http://localhost:8080/health
```

### Q: "Posso usare questo in produzione?"
**A:** Non ancora. Per la produzione dovrai:
1. Passare l'app Facebook in "Live Mode"
2. Completare l'App Review di Facebook per i permessi
3. Implementare OAuth flow completo (non usare token hardcoded)
4. Implementare refresh automatico dei token
5. Aggiungere error handling robusto

Per ora, va bene per test e sviluppo personale.

### Q: "Il token dura solo 1 ora, è normale?"
**A:** Sì, i token generati da Graph API Explorer sono short-lived. Per estenderli a 60 giorni, usa il comando curl al passo 1.

---

## 📁 File Creati per Te

Durante questo setup sono stati creati i seguenti file:

```
brainiac_plus/
├── test_facebook_automation.sh           # Script di test automatico
├── test_facebook_interactive.sh          # Script interattivo (CONSIGLIATO)
├── FACEBOOK_TOKEN_GUIDE.md               # Guida dettagliata sui token
├── FACEBOOK_AUTOMATION_README.md         # Documentazione completa
├── QUICK_START_FACEBOOK.md               # Questo file
└── lib/features/automation/screens/
    └── facebook_automation_test_screen.dart  # UI di test Flutter
```

---

## 🚀 Dopo il Test, Cosa Fare?

Una volta che i test funzionano:

### 1. Salva il Token nel .env
```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
nano .env

# Sostituisci la riga FACEBOOK_TOKEN con il tuo token valido
FACEBOOK_TOKEN=IL_TUO_TOKEN_VALIDO
```

### 2. Riavvia il Backend
```bash
# Uccidi il processo corrente
pkill -f "go run main.go"

# Riavvia con il nuovo token
cd /home/giuseppe-genna/brainiac_plus/go_backend
go run main.go &
```

### 3. Crea la Tua Prima Automazione
Vai nell'app Flutter → Automations → Create e configura un post automatico!

---

## 📞 Hai Problemi?

**Leggi la documentazione completa:**
```bash
cd /home/giuseppe-genna/brainiac_plus
cat FACEBOOK_TOKEN_GUIDE.md
cat FACEBOOK_AUTOMATION_README.md
```

**Debug logs:**
```bash
# Logs del backend
tail -f /tmp/copilot-detached-go_backend-*.log

# Test manuale
./test_facebook_interactive.sh
```

**Risorse online:**
- Facebook Graph API Explorer: https://developers.facebook.com/tools/explorer/
- Facebook API Documentation: https://developers.facebook.com/docs/graph-api/
- App Dashboard: https://developers.facebook.com/apps/2102048307277114/

---

## ✅ Checklist Finale

Prima di iniziare, assicurati di avere:

- [ ] Token Facebook valido (generato al passo 1)
- [ ] Backend Go in esecuzione su porta 8080
- [ ] Accesso admin/editor ad almeno una pagina Facebook
- [ ] Script di test eseguibile (`chmod +x test_facebook_interactive.sh`)

Se hai tutto, esegui:
```bash
cd /home/giuseppe-genna/brainiac_plus
./test_facebook_interactive.sh
```

**Buon test! 🚀**
