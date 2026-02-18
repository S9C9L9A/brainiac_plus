# 📱 Instagram Setup - ONE PAGE REFERENCE

## ⚡ Procedura Veloce (5 minuti)

### Passo 1: Converti Account Instagram
```
Instagram app → Profilo → Impostazioni → 
"Account professionale" → "Business" → Completa
```
⏱️ 1 minuto

### Passo 2: Collega a Facebook
```
Instagram app → Impostazioni → Account → 
"Account collegati" → Facebook → Autorizza
```
⏱️ 1 minuto

### Passo 3: Genera Token
1. Vai a: https://developers.facebook.com/tools/explorer/
2. Seleziona la tua app (top-left menu)
3. Clicca sul token (right side)
4. Assicurati siano ✅:
   - instagram_basic
   - pages_show_list
5. Clicca "Genera token"
6. Copia il token (inizia con EAAZ...)

⏱️ 2 minuti

### Passo 4: Inserisci in BrainiacPlus
```
BrainiacPlus → Setup Wizard → Instagram → 
Incolla token → Clicca "Verifica Token" → 
Vedi ✅ "Instagram collegato!" → Avanti!
```
⏱️ 1 minuto

---

## ❌ Errori Comuni & Soluzioni

| Errore | Causa | Soluzione |
|--------|-------|----------|
| "Invalid OAuth access token" | Token scaduto | Genera nuovo token |
| "No Instagram Business Account" | Account non collegato a FB | Ricollega su Instagram → Account collegati |
| "Account is not business" | Account personale | Converti a Business (Passo 1) |
| "Insufficient permissions" | Permessi mancanti | Aggiungi `instagram_basic` al token |
| Token funziona nel browser ma non in app | Copia incompleta/scaduto | Ricopia intero, senza spazi |

---

## 🧪 Test Token nel Browser

Apri browser e incolla questo URL (sostituisci TOKEN):
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

✅ Se vedi i dati → Token valido!  
❌ Se vedi error → Token non valido

---

## 📚 Documenti Completi

| Quando Leggere | Documento |
|----------------|-----------|
| **Ho 5 minuti** | `docs/setup/INSTAGRAM_QUICK_START.md` |
| **Ho 20 minuti** | `docs/setup/INSTAGRAM_SETUP_GUIDE.md` |
| **Voglio riassunto** | `docs/setup/INSTAGRAM_SETUP_SUMMARY.md` |
| **Non so da dove iniziare** | `docs/setup/README_INSTAGRAM.md` |
| **Voglio sapere gli aggiornamenti** | `docs/setup/INSTAGRAM_IMPROVEMENTS_COMPLETED.md` |

---

## ✅ Checklist

- [ ] Account Instagram convertito a Business
- [ ] Account Instagram collegato a Pagina Facebook
- [ ] Token generato da Graph API Explorer
- [ ] Token testato nel browser (vedi sopra)
- [ ] Token incollato in BrainiacPlus
- [ ] Visto messaggio ✅ "Instagram collegato!"
- [ ] Continuato Setup Wizard fino alla fine

---

## 💡 Pro Tips

1. **Copia token completo** → no spazi extra
2. **Token scade dopo ~2 ore** → Rigenera se aspetti troppo
3. **Se non riconosce il token** → Chiudi/riapri BrainiacPlus
4. **Test nel browser** → Se valido lì, valido ovunque
5. **Non condividere il token** → È come una password!

---

## 🚀 Prossimi Passi

Una volta configurato:

1. Vai al Dashboard → Vedrai card Instagram
2. Clicca sulla card → Vedi dettagli e metriche
3. Crea automazioni → Automation → New Instagram Task
4. Monitora risultati → Analytics

---

**Status:** ✅ PRONTO PER IL SETUP  
**Tempo:** 5 minuti | **Difficoltà:** Facile | **Supporto:** ✓ Completo

Vai al passo 1 e inizia! 🚀
