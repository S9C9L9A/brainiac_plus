# 📱 Guida Completa di Configurazione Instagram per BrainiacPlus

> **Aggiornato:** Febbraio 2026 | **Versione:** 2.0
> 
> Questa guida ti aiuta a configurare Instagram in BrainiacPlus **passo-passo** con tutte le istruzioni necessarie.

---

## 🎯 Panoramica della Procedura

La configurazione di Instagram in BrainiacPlus richiede **4 fasi principali**:

```
┌─────────────────────────────────────────────────────────┐
│  FASE 1: Preparare Account Instagram                    │
│  ↓                                                       │
│  Convertire a Business + Collegare a Facebook           │
├─────────────────────────────────────────────────────────┤
│  FASE 2: Ottenere Token di Accesso                      │
│  ↓                                                       │
│  Usa Facebook Developers Graph API Explorer             │
├─────────────────────────────────────────────────────────┤
│  FASE 3: Configurare BrainiacPlus                       │
│  ↓                                                       │
│  Inserisci token + Verifica connessione                 │
├─────────────────────────────────────────────────────────┤
│  FASE 4: Test & Troubleshooting                         │
│  ↓                                                       │
│  Testa la connessione e risolvi errori                  │
└─────────────────────────────────────────────────────────┘
```

⏱️ **Tempo richiesto:** ~15 minuti (la prima volta)

---

## 📋 Prerequisiti Checklist

Prima di iniziare, assicurati di avere:

- [ ] Account Facebook personale
- [ ] Account Instagram (personale o business)
- [ ] Accesso email per verifiche
- [ ] Browser aggiornato (Chrome, Firefox, Safari)
- [ ] La seguente app Facebook già creata: `2102048307277114`

**Se NON hai questi elementi, leggi i sottosezioni di preparazione.**

---

## ✅ FASE 1: Preparare Account Instagram

### Step 1.1: Convertire Account Instagram a Business

**Perché?** Le API di Instagram funzionano SOLO su account Business o Creator, non su account personali.

#### Su Smartphone (Più Facile)

1. **Apri Instagram** sul tuo telefono
2. Tocca il tuo **Profilo** (icona in basso a destra)
3. Tocca il **Menu (☰)** in alto a destra
4. Scorri e seleziona **Impostazioni e Privacy**
5. Vai su **Impostazioni** (se non entrato automaticamente)
6. Scorri fino a **Come usi Instagram**
7. Seleziona **Account professionale**
8. Scegli il tipo:
   - **Business** = Azienda/E-commerce
   - **Creator** = Content creator/Influencer
9. Segui i passaggi per completare la configurazione

#### Su Browser Web

1. Vai a: https://instagram.com
2. Accedi
3. Vai su **Profilo** → **Impostazioni**
4. Seleziona **Account**
5. Scorri fino a "Passa a un account professionale"
6. Clicca e segui i passaggi

**✅ Completo:** Il tuo profilo dovrebbe ora mostrare una badge "Business" o "Creator"

---

### Step 1.2: Collegare Instagram a una Pagina Facebook

**Perché?** Instagram Business API richiede un collegamento con una Pagina Facebook. Senza questo, non puoi usare l'API.

#### Opzione A: Collega da Instagram (Raccomandato)

**Per chi ha accesso da smartphone:**

1. **Instagram app** → **Profilo**
2. Tocca **Menu (☰)** → **Impostazioni e Privacy**
3. Vai su **Impostazioni** → **Account**
4. Scorri a **Account collegati**
5. Seleziona **Facebook**
6. Tocca **Collega**
7. Accedi con il tuo account Facebook
8. Seleziona la Pagina Facebook da collegare (o creane una nuova)
9. Autorizza

#### Opzione B: Collega da Facebook

**Se preferisci via web:**

1. Vai a: https://facebook.com
2. Accedi
3. Apri la tua **Pagina** (in alto a sinistra, seleziona la pagina)
4. Clicca su **Impostazioni** (in basso a sinistra)
5. Nel menu di sinistra, seleziona **Instagram**
6. Clicca **Collega account**
7. Accedi se necessario
8. Seleziona il tuo account Instagram Business
9. Autorizza

#### Opzione C: Se Ancora Non Collegato da Nessuno

**Se non hai una Pagina Facebook:**

1. Vai a: https://facebook.com/pages/create
2. Scegli una categoria (es: "Azienda")
3. Compila i dettagli di base
4. Clicca "Crea Pagina"
5. Subito dopo, vedrai un'opzione per collegare Instagram
6. Segui i passaggi di collegamento

**✅ Completo:** Dovresti vedere il tuo account Instagram nel menu "Instagram" della Pagina Facebook

---

### Step 1.3: Verifica il Collegamento

Verifica che tutto sia collegato correttamente:

1. **Visita:** https://business.facebook.com/latest/settings/pages
   - (Oppure: Facebook → Impostazioni → Pagine)

2. **Seleziona la tua Pagina** dall'elenco

3. **Nel menu sinistro, cerca "Instagram"**

4. **Dovresti vedere:**
   ```
   Instagram Business Account: [@il_tuo_username]
   Status: Connected ✅
   ```

Se vedi ✅, sei pronto per il prossimo step!

Se vedi un errore, torna ai step 1.1-1.2 e ripeti.

---

## 🔑 FASE 2: Ottenere il Token di Accesso

### Step 2.1: Accedere a Facebook Graph API Explorer

**Cos'è?** Graph API Explorer è uno strumento che Facebook mette a disposizione per testare e generare token.

1. **Vai a:** https://developers.facebook.com/tools/explorer/

2. **Se non sei loggato, accedi** con il tuo account Facebook

3. **Nel menu in alto a sinistra, seleziona la tua app:**
   - Cerca e seleziona: `2102048307277114`
   - (Se non la vedi, chiedi all'amministratore dell'app)

**Lo schermo dovrebbe assomigliare a questo:**
```
┌─────────────────────────────────────┐
│  App: 2102048307277114  ▼          │ ← App selector
├─────────────────────────────────────┤
│  GET  │  /me  ▼                     │ ← Query editor
│  [Invia Query]                      │ ← Button
├─────────────────────────────────────┤
│  Results:                           │
│  {                                  │
│    "data": [...]                    │
│  }                                  │ ← Response
└─────────────────────────────────────┘
```

### Step 2.2: Ottenere l'Access Token

**Con i giusti permessi:**

1. **Nel riquadro superiore destro, cerca "Token di accesso"**
   - Dovrebbe dire "Accesso" o "User Token"
   
2. **Clicca su di esso**
   - Si aprirà una finestra di dialogo
   
3. **Nella sezione "Seleziona permessi", assicurati questi siano ✅ selezionati:**
   ```
   ✅ instagram_basic
   ✅ instagram_manage_insights
   ✅ pages_show_list
   ✅ pages_read_engagement
   ```
   
   Se vuoi anche **postare automaticamente**, aggiungi:
   ```
   ✅ instagram_content_publish
   ```

4. **Clicca "Genera token"**

5. **Una finestra pop-up ti chiederà di autorizzare**
   - Clicca "Continua" e autorizza

6. **Vedrai il token nel formato:**
   ```
   EAAZ...xyzabc...
   ```

7. **Clicca per copiarlo** (icona "copia" accanto)

**🔐 Importante:** 
- ⚠️ Non condividere questo token con nessuno!
- ⚠️ Trattalo come una password
- ⚠️ Se lo perdi, puoi rigenerarne uno nuovo qui

---

### Step 2.3: Verifica che il Token Funzioni

Prima di inserirlo in BrainiacPlus, verificalo:

1. **Nel Graph API Explorer, cambia la query a:**
   ```
   /me/accounts?fields=instagram_business_account
   ```

2. **Clicca "Invia Query"**

3. **Dovresti vedere una risposta simile a:**
   ```json
   {
     "data": [
       {
         "instagram_business_account": {
           "id": "17841405309211844",
           "username": "il_tuo_username"
         },
         "name": "Nome Pagina Facebook",
         "id": "123456789"
       }
     ]
   }
   ```

**Se la risposta contiene "error":**
- ❌ Token non valido
- ❌ Permessi insufficienti
- ❌ Account Instagram non collegato a Pagina Facebook
- → Ritorna ai step precedenti

**Se la risposta è corretta:**
- ✅ Token è valido!
- ✅ Pronto per il prossimo step

---

## 🎯 FASE 3: Configurare BrainiacPlus

### Step 3.1: Aprire Setup Wizard Instagram

1. **Apri BrainiacPlus**

2. **Vai a: Setup Wizard → Passaggio "Collega Instagram"**

3. **Se sei già stato nel Setup, vai a:**
   - **Impostazioni → Instagram → Configura**

### Step 3.2: Inserire il Token

1. **Nel campo "Access Token", incolla il token che hai copiato da Graph API Explorer**
   - Dovrebbe iniziare con `EAAZ` o `EAA`
   - Dovrebbe essere una stringa lunga

2. **Nel campo "Account ID" (se richiesto), incolla l'ID da Step 2.3:**
   - La parte dopo `"id":` nella risposta
   - Dovrebbe assomigliare a: `17841405309211844`

3. **Clicca il pulsante "Verifica Connessione"**

### Step 3.3: Attendere la Verifica

La app contatterà Facebook per verificare il token:

```
⏳ Verifica in corso...
  ↓
✅ Instagram collegato!  (SUCCESSO)
  oppure
❌ Errore di connessione (vedi troubleshooting)
```

**Se vedi ✅ "Instagram collegato!":**
- Perfetto! Vai al Step 3.4

**Se vedi ❌ Errore:**
- Vai alla sezione "TROUBLESHOOTING" qui sotto

### Step 3.4: Salva e Completa

1. **Se il messaggio è ✅, clicca "Avanti"**

2. **Continua il Setup Wizard**

3. **Alla fine, clicca "Completa Setup"**

✅ **Fatto!** Instagram è configurato in BrainiacPlus

---

## 🧪 FASE 4: Test & Troubleshooting

### Test 1: Verifica Connessione

### Test 1: Verifica Connessione Manuale

Apri il browser e vai a questo URL (sostituisci i valori):

```
https://graph.facebook.com/v18.0/me/accounts?fields=instagram_business_account&access_token=IL_TUO_TOKEN
```

**Cosa dovresti vedere:**
```json
{
  "data": [
    {
      "instagram_business_account": {
        "id": "17841405309211844",
        "username": "il_tuo_username"
      }
    }
  ]
}
```

**Se vedi un errore:**
- ❌ `"error": {"message": "Invalid OAuth access token"}` → Token scaduto o non valido
- ❌ `"error": {"message": "Insufficient permissions"}` → Permessi mancanti
- ❌ `"error": {"message": "No Instagram Business Account found"}` → Account non collegato

---

### Test 2: Recupera Info Profilo Instagram

Una volta verificata la connessione, recupera le info:

```
https://graph.facebook.com/v18.0/17841405309211844?fields=id,username,followers_count,follows_count,media_count,profile_picture_url&access_token=IL_TUO_TOKEN
```

**Cosa dovresti vedere:**
```json
{
  "id": "17841405309211844",
  "username": "il_tuo_username",
  "followers_count": 1234,
  "follows_count": 567,
  "media_count": 89,
  "profile_picture_url": "https://..."
}
```

Se vedi i dati, il collegamento è perfetto! ✅

---

## ❌ TROUBLESHOOTING: Errori Comuni e Soluzioni

### ❌ Errore 1: "Invalid OAuth access token"

**Cosa significa:** Il token non è valido o è scaduto.

**Soluzioni:**
1. **Genera un nuovo token:**
   - Vai a: https://developers.facebook.com/tools/explorer/
   - Seleziona la tua app
   - Clicca sul token attuale (a destra)
   - Clicca "Genera token"
   - Copia il nuovo token
   - Inserisci in BrainiacPlus

2. **Se il problema persiste:**
   - Controlla di aver copiato il token **completo** (deve iniziare con `EAA`)
   - Non copiare spazi bianchi prima/dopo
   - Riprova a generare un token nuovo

---

### ❌ Errore 2: "No Instagram Business Account found"

**Cosa significa:** Il tuo account Instagram non è collegato a nessuna Pagina Facebook.

**Soluzioni:**
1. **Collega Instagram a Facebook:**
   - Su Instagram app: Profilo → Menu → Impostazioni → Account → Account collegati → Facebook
   - Seleziona una Pagina Facebook
   - Autorizza

2. **Oppure collega da Facebook:**
   - Vai a: https://facebook.com/pages
   - Seleziona la tua Pagina
   - Impostazioni → Instagram → Collega account
   - Seleziona il tuo account Instagram
   - Autorizza

3. **Se ancora non funziona:**
   - Verifica che l'account Instagram sia di tipo **Business** (non personale)
   - Se no, convertilo seguendo Step 1.1 sopra
   - Ricollega dopo la conversione

---

### ❌ Errore 3: "Account is not a business account"

**Cosa significa:** L'account Instagram è personale, ma l'API richiede un account Business.

**Soluzione:**
1. **Converti l'account a Business:**
   - Instagram app: Profilo → Menu → Impostazioni e Privacy
   - Scorri a "Come usi Instagram"
   - Seleziona "Account professionale"
   - Scegli "Business" o "Creator"
   - Completa i dati

2. **Ricollega a Facebook:**
   - Dopo la conversione, ricollega il tuo account a una Pagina Facebook
   - Segui le istruzioni in Errore 2

---

### ❌ Errore 4: "Insufficient permissions"

**Cosa significa:** Il token non ha i permessi necessari per accedere a Instagram.

**Soluzione:**
1. **Genera un nuovo token con permessi Instagram:**
   - Vai a: https://developers.facebook.com/tools/explorer/
   - Seleziona la tua app
   - Nel riquadro token (destra), clicca su di esso
   - Nella sezione "Seleziona permessi", assicurati siano ✅:
     ```
     ✅ instagram_basic
     ✅ pages_show_list
     ```
   - Se vuoi postare, aggiungi:
     ```
     ✅ instagram_content_publish
     ```

2. **Genera il token**

3. **Copia il nuovo token**

4. **Inserisci in BrainiacPlus**

---

### ❌ Errore 5: "Limit Exceeded" o "Rate Limited"

**Cosa significa:** Hai fatto troppe richieste all'API di Instagram in poco tempo.

**Soluzione:**
1. **Aspetta 5-10 minuti**
2. **Riprova dopo**

Se il problema persiste:
- Iscriviti a un piano API più alto su Facebook Developers
- Oppure contatta supporto Facebook

---

### ❌ Errore 6: "Invalid Field"

**Cosa significa:** Stai richiedendo un field che non esiste o non hai accesso.

**Soluzione:**
1. **Controlla la query:**
   - Se il URL contiene: `fields=...` e vedi errore
   - Rimuovi i field che non conosci
   - Usa i field base: `id,username,followers_count`

2. **Esempio corretto:**
   ```
   https://graph.facebook.com/v18.0/ME/accounts?fields=instagram_business_account&access_token=TOKEN
   ```

---

### ❓ Il Token Funziona nel Browser, ma non in BrainiacPlus

**Possibili cause:**

1. **Copia-incolla errata:**
   - Incolla il token di nuovo, assicurandoti che sia completo
   - No spazi, no caratteri extra

2. **App non aggiornata:**
   - Chiudi completamente BrainiacPlus
   - Riaprila
   - Riprova

3. **Cache problematica:**
   - Vai a Impostazioni → Cancella cache
   - Riavvia l'app

4. **Token scaduto durante la configurazione:**
   - I token token scadono dopo ~2 ore
   - Se hai aspettato troppo tra la generazione e l'inserimento, genera uno nuovo
   - Questo è raro, ma può accadere

---

## 🔍 Diagnostica Avanzata

### Come Raccogliere Log

1. **Apri il terminale:**
   ```bash
   cd /home/giuseppe-genna/brainiac_plus
   flutter logs
   ```

2. **Apri BrainiacPlus e prova a configurare Instagram**

3. **Nel terminale vedrai i log:**
   ```
   I/FlutterLog(12345): [InstagramSetup] Verifying token...
   E/FlutterLog(12345): [InstagramSetup] Error: Invalid token
   ```

4. **Copia gli errori e condividili per supporto**

### Come Testare il Token Direttamente

**Da terminale (Linux/Mac):**

```bash
# Salva il token in una variabile
TOKEN="EAA..."

# Test 1: Verifica account Instagram
curl -s "https://graph.facebook.com/v18.0/me/accounts?fields=instagram_business_account&access_token=$TOKEN" | python3 -m json.tool

# Test 2: Recupera profilo Instagram
curl -s "https://graph.facebook.com/v18.0/17841405309211844?fields=username,followers_count&access_token=$TOKEN" | python3 -m json.tool
```

Se vedi i dati in formato JSON corretto, il token è valido! ✅

---

## 📚 Documentazione Correlata
