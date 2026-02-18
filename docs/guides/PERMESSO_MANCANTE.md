# ⚠️ PERMESSO MANCANTE - pages_manage_posts

## 🔍 Stato Attuale

✅ **Token Valido**: Sì  
✅ **Utente**: Giuseppe Genna  
✅ **Pagina Trovata**: Cotton Mouth 999 Club  
❌ **Problema**: Manca il permesso `pages_manage_posts`

## 📋 Permessi Attuali

Il tuo token ha questi permessi:
- ✅ pages_show_list
- ✅ pages_read_engagement  
- ✅ ads_management
- ✅ ads_read
- ✅ business_management
- ✅ whatsapp_business_management
- ✅ whatsapp_business_messaging
- ✅ public_profile

**MANCA:**
- ❌ **pages_manage_posts** ← Necessario per pubblicare post

## 🔧 Come Aggiungere il Permesso

### Metodo 1: Graph API Explorer (Raccomandato)

1. **Vai qui:**
   https://developers.facebook.com/tools/explorer/

2. **In alto a destra:**
   - Assicurati che sia selezionata la tua app: `2102048307277114`

3. **Clicca su "Generate Access Token"**

4. **Nella finestra dei permessi, cerca e seleziona:**
   - ✅ pages_show_list (già ce l'hai)
   - ✅ pages_read_engagement (già ce l'hai)  
   - ✅ **pages_manage_posts** ← AGGIUNGI QUESTO!

5. **Clicca "Generate Access Token"**

6. **Copia il nuovo token** (sarà diverso da quello attuale)

7. **Usa il nuovo token** negli script di test

### Metodo 2: Verifica Manuale

Prima di generare il token, puoi verificare i permessi disponibili:

1. Vai su: https://developers.facebook.com/apps/2102048307277114/
2. Settings → Basic
3. Controlla che l'app sia in "Development Mode"
4. Se l'app è in development mode, solo admin/developer/tester possono usarla

### Metodo 3: URL Diretto OAuth (Avanzato)

Se vuoi controllare tutto manualmente, usa questo URL:

```
https://www.facebook.com/v18.0/dialog/oauth?\
client_id=2102048307277114&\
redirect_uri=https://localhost&\
scope=pages_show_list,pages_read_engagement,pages_manage_posts&\
response_type=token
```

Incolla questo URL nel browser (mentre sei loggato su Facebook) e autorizza l'app.

## 🧪 Test Dopo Aver Aggiunto il Permesso

Dopo aver ottenuto il nuovo token con `pages_manage_posts`:

```bash
cd /home/giuseppe-genna/brainiac_plus

# Metodo 1: Script interattivo
./test_facebook_interactive.sh
# Quando richiesto, incolla il NUOVO token

# Metodo 2: Test rapido
TOKEN="IL_NUOVO_TOKEN"
curl -s "https://graph.facebook.com/v18.0/me/permissions?access_token=$TOKEN" | \
  jq -r '.data[] | select(.status == "granted") | .permission' | \
  grep pages_manage_posts

# Se vedi "pages_manage_posts", sei a posto!
```

## 📝 Nota Importante: App in Development Mode

La tua app Facebook è probabilmente in **Development Mode**.

Questo significa:
- ✅ Solo tu (admin/developer) puoi usarla
- ✅ Perfetto per testing e sviluppo
- ⚠️ Altri utenti non possono autenticarsi
- ⚠️ Alcune funzionalità potrebbero essere limitate

**Non serve passare in Live Mode** per testare le automazioni personali!

## 🚀 Dopo Aver Ottenuto il Token Corretto

### 1. Aggiorna il file .env

```bash
cd /home/giuseppe-genna/brainiac_plus/go_backend
nano .env
```

Sostituisci `FACEBOOK_TOKEN` con il nuovo token.

### 2. Riavvia il Backend

```bash
# Trova il PID del backend
ps aux | grep "go run main.go" | grep -v grep | awk '{print $2}'

# Killalo (sostituisci PID con il numero trovato)
kill PID

# Riavvialo
cd /home/giuseppe-genna/brainiac_plus/go_backend
nohup go run main.go > /tmp/go_backend.log 2>&1 &
```

### 3. Testa la Pubblicazione

```bash
cd /home/giuseppe-genna/brainiac_plus
./test_facebook_interactive.sh
```

Lo script ti guiderà e pubblicherà un post di test sulla tua pagina!

## ✅ Risultato Atteso

Dopo aver fatto tutto, dovresti vedere:

```
📌 Test 3: Verifica Permessi
------------------------------------------
✅ Permessi attivi:
   ✓ pages_show_list
   ✓ pages_read_engagement
   ✓ pages_manage_posts  ← QUESTO DEVE APPARIRE
   ✓ public_profile

📌 Test 4: Pubblica Post di Test
------------------------------------------
✅ Post pubblicato con successo!
   🆔 Post ID: 113132123896705_123456789
   📄 Pagina: Cotton Mouth 999 Club
   💬 Messaggio: 🧠 Test automatico BrainiacPlus - 2026-02-16 11:15:00
```

## 🆘 Troubleshooting

### "Non riesco ad aggiungere il permesso"

Possibili cause:
1. L'app non ha richiesto il permesso in App Review
2. Sei in Development Mode (normale, va bene)
3. Non sei admin della pagina

**Soluzione**: Assicurati di essere in Development Mode e di essere admin della pagina.

### "Il token continua a non funzionare"

Verifica:
```bash
TOKEN="tuo_token"
curl "https://graph.facebook.com/v18.0/me/permissions?access_token=$TOKEN" | jq .
```

Cerca `pages_manage_posts` con `"status": "granted"`

### "Ho il permesso ma non posso pubblicare"

Controlla di usare il **Page Access Token**, non lo User Access Token:

```bash
# Recupera il Page Access Token
TOKEN="user_token"
PAGE_TOKEN=$(curl -s "https://graph.facebook.com/v18.0/me/accounts?access_token=$TOKEN" | \
  jq -r '.data[0].access_token')

# Usa PAGE_TOKEN per pubblicare
```

---

**Quick Link**: https://developers.facebook.com/tools/explorer/

Genera il nuovo token con tutti i permessi e torna qui per testare! 🚀
