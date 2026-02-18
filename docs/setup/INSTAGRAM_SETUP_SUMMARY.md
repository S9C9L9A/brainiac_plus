# 📱 Instagram Setup - Istruzioni Complete Migliorate

## 📝 Sommario dei Miglioramenti Effettuati

Ho migliorato significativamente il processo di configurazione Instagram in BrainiacPlus:

### 1. **Guida Completa Aggiornata**
   - **File:** `docs/setup/INSTAGRAM_SETUP_GUIDE.md`
   - **Lunghezza:** 300+ linee con istruzioni dettagliate
   - **Sezioni:**
     - ✅ Panoramica della procedura con diagramma
     - ✅ Prerequisiti checklist
     - ✅ 4 Fasi principali con step-by-step
     - ✅ Sezione troubleshooting completa (10+ errori comuni)
     - ✅ Test di connessione manuale
     - ✅ Diagnostica avanzata

### 2. **Widget UI Migliorato**
   - **File:** `lib/features/onboarding/widgets/instagram_setup_step.dart`
   - **Miglioramenti:**
     - ✅ 3 step card con istruzioni chiare
     - ✅ Pulsanti di collegamento diretto ai siti ufficiali
     - ✅ Campo di input per token con toggle visibilità
     - ✅ Validazione del token
     - ✅ Messaggi di errore più chiari
     - ✅ Sezione di aiuto integrata

### 3. **Quick Start per Setup Rapido**
   - **File:** `docs/setup/INSTAGRAM_QUICK_START.md`
   - **Tempo:** 5 minuti
   - **Contiene:**
     - ✅ Procedura rapida in 5 passi
     - ✅ Tabella troubleshooting rapido
     - ✅ Test di validazione token

---

## 🎯 Procedura Corretta da Seguire

### Prerequisiti (Una volta sola)

1. **Account Instagram convertito a Business**
   - Instagram app → Profilo → Impostazioni → "Account professionale" → "Business"
   - Oppure visitare: https://business.instagram.com

2. **Account Instagram collegato a Pagina Facebook**
   - Instagram app → Impostazioni → Account → "Account collegati" → Facebook
   - Selezionare una Pagina Facebook
   - Autorizzare

### Setup in BrainiacPlus

1. **Apri il Setup Wizard**
   - BrainiacPlus → Setup Wizard → Step "Collega Instagram"

2. **Segui i 3 step mostrati:**
   - **Step 1:** Converti account Instagram (se necessario)
   - **Step 2:** Collega a Facebook
   - **Step 3:** Ottieni token da Graph API Explorer

3. **Incolla il token**
   - Copia il token da: https://developers.facebook.com/tools/explorer/
   - Incolla nel campo di BrainiacPlus
   - Clicca "Verifica Token"

4. **Se vedi ✅ "Instagram collegato!"**
   - Clicca "Avanti" per continuare il Setup Wizard

---

## 🔑 Dove Ottenere il Token (Procedura Passo-Passo)

### Passo A: Accedi a Graph API Explorer

1. **Visita:** https://developers.facebook.com/tools/explorer/
2. **Accedi** con il tuo account Facebook (se richiesto)

### Passo B: Seleziona la tua App

1. **Nel menu in alto a sinistra, seleziona la tua app**
   - Cerca: `2102048307277114` o il nome della tua app
   - Clicca per selezionarla

### Passo C: Genera il Token

1. **Nel riquadro token (parte destra dello schermo), clicca su di esso**
2. **Si aprirà una finestra, seleziona i permessi:**
   ```
   ✅ instagram_basic
   ✅ pages_show_list
   ```
   Se vuoi postare contenuti, aggiungi:
   ```
   ✅ instagram_content_publish
   ```

3. **Clicca "Genera token"**
4. **Autorizza se richiesto**
5. **Copia il token** (dovrebbe iniziare con `EAAZ...`)

---

## ✅ Checklist Rapida

- [ ] Account Instagram è Business (non personale)
- [ ] Account Instagram è collegato a Pagina Facebook
- [ ] Ho accesso a Facebook Developers
- [ ] Ho generato un token con permessi Instagram
- [ ] Ho incollato il token in BrainiacPlus
- [ ] Vedo il messaggio ✅ "Instagram collegato!"
- [ ] Ho completato il Setup Wizard

---

## ❓ Errori Comuni & Soluzioni

### Errore: "Invalid OAuth access token"
**Significa:** Token non valido o scaduto
**Soluzione:** Genera un nuovo token da Graph API Explorer

### Errore: "No Instagram Business Account found"
**Significa:** Account Instagram non collegato a Facebook
**Soluzione:** Ricollega da Instagram → Impostazioni → Account → Account collegati

### Errore: "Account is not a business account"
**Significa:** L'account Instagram è personale
**Soluzione:** Converti a Business: Instagram → Impostazioni → "Account professionale"

### Errore: "Insufficient permissions"
**Significa:** Token non ha i permessi necessari
**Soluzione:** Genera un nuovo token assicurandoti che `instagram_basic` sia ✅ selezionato

### Il token funziona nel browser ma non in BrainiacPlus
**Soluzioni possibili:**
1. Verifica di aver copiato il token **completo** (nessuno spazio)
2. Chiudi e riapri BrainiacPlus
3. Il token potrebbe essere scaduto (genera uno nuovo)

---

## 🧪 Come Testare il Token

### Test nel Browser (Rapido)

Apri il browser e incolla questo URL (sostituisci `TOKEN` con il tuo):

```
https://graph.facebook.com/v18.0/me/accounts?fields=instagram_business_account&access_token=TOKEN
```

**Dovresti vedere:**
```json
{
  "data": [{
    "instagram_business_account": {
      "id": "17841405309211844",
      "username": "il_tuo_username"
    }
  }]
}
```

✅ Se vedi i dati → Token è valido!

---

## 📚 Documentazione

| Documento | Scopo | Tempo |
|-----------|-------|-------|
| `docs/setup/INSTAGRAM_QUICK_START.md` | Setup rapido | 5 min |
| `docs/setup/INSTAGRAM_SETUP_GUIDE.md` | Guida completa | 20 min |
| Widget in-app | Istruzioni interattive | Durante setup |

---

## 🚀 Prossimi Passi Dopo Setup

Una volta configurato Instagram:

1. **Vai a Dashboard** → Vedrai la card Instagram
2. **Clicca sulla card** → Vedi dettagli e metriche
3. **Crea automazioni** → Automation → New Instagram Task
4. **Monitora risultati** → Dashboard → Analytics

---

## 🆘 Se Hai Ancora Problemi

1. **Leggi la guida completa:** `docs/setup/INSTAGRAM_SETUP_GUIDE.md`
   - Sezione "TROUBLESHOOTING" ha 10+ soluzioni comuni

2. **Esegui test token:**
   - Usa il test nel browser (vedi sopra)
   - Se token è valido nel browser, il problema è nell'app

3. **Controlla i log:**
   ```bash
   flutter logs
   ```
   - Copia l'errore e cercalo nella guida

---

## 📧 Supporto

Se hai domande specifiche:
1. Leggi la guida completa prima
2. Esegui il test del token
3. Raccogli log e screenshot
4. Contatta supporto con le informazioni

---

**Versione:** 2.0 | **Aggiornato:** Febbraio 2026
