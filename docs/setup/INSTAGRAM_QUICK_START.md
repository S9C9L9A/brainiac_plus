# 📸 INSTAGRAM - Quick Start

## 🎯 Risultato Test

Ho eseguito il test di integrazione Instagram. Ecco cosa è emerso:

### ✅ Funzionante
- Token Facebook valido
- Pagina Facebook trovata: **Cotton Mouth 999 Club**

### ⚠️ Da Configurare
- **Nessun account Instagram** è collegato alla pagina Facebook

---

## 🚀 Cosa Devi Fare (2 Minuti)

### Opzione 1: Se Hai Già un Account Instagram

1. **Apri Facebook** sul browser
2. Vai alla **Pagina**: Cotton Mouth 999 Club
3. **Impostazioni** → **Instagram**
4. Clicca **"Collega account Instagram"**
5. Accedi con Instagram e autorizza

### Opzione 2: Se Non Hai Instagram o È Personale

1. **Apri Instagram app** sul telefono
2. Vai sul **Profilo** (icona in basso a destra)
3. **Menu (☰)** → **Impostazioni**
4. **Account** → **Passa a un account professionale**
5. Scegli **"Business"**
6. Completa il setup
7. Torna a Facebook e collega (Opzione 1)

---

## 🧪 Dopo Aver Collegato

Esegui di nuovo il test:

```bash
cd /home/giuseppe-genna/brainiac_plus
./test_instagram_integration.sh
```

Vedrai:
```
✅ Instagram Business Account trovato!
✅ Username: @tuo_username
✅ Followers: 123
✅ Posts: 45
✅ Engagement Rate: 5.2%
```

Lo script ti darà anche il **codice già pronto** da copiare nel controller!

---

## 📱 Come Apparirà in BrainiacPlus

Dopo la configurazione, nella dashboard vedrai:

### Card Instagram
```
┌──────────────────────────────────┐
│ 📸  @tuo_username          [Active]
│     Instagram
│
│  👥 123     📄 45       ❤️ 5.2%
│  Followers  Posts    Engagement
│
│ 🕐 Updated 2m ago            →
└──────────────────────────────────┘
```

### Click sulla Card → Dettagli
- Grafici follower growth
- Post più popolari
- Engagement breakdown
- Stories analytics
- Quick actions

---

## ❓ FAQ

**Q: Devo creare un nuovo account Instagram?**  
A: No! Puoi usare il tuo account esistente, basta convertirlo in Business.

**Q: Costa qualcosa?**  
A: No, l'account Instagram Business è gratuito.

**Q: Perderò i miei follower?**  
A: No, passa solo da "Personale" a "Business", mantieni tutto.

**Q: Serve una pagina Facebook?**  
A: Sì, Instagram Business API funziona SOLO se collegato a una pagina Facebook.

**Q: Ho già collegato ma non funziona?**  
A: Prova a scollegare e ricollegare, poi rigenera il token con permessi Instagram.

---

## 🔧 Comandi Utili

```bash
# Test integrazione Instagram
./test_instagram_integration.sh

# Test con token diverso
./test_instagram_integration.sh 'nuovo_token'

# Vedere config generata
cat /tmp/instagram_config.json

# Guida completa
cat INSTAGRAM_SETUP_GUIDE.md
```

---

## 📚 Documenti Creati

1. **INSTAGRAM_SETUP_GUIDE.md** - Guida completa passo-passo
2. **test_instagram_integration.sh** - Script di test automatico
3. **INSTAGRAM_QUICK_START.md** - Questa guida rapida

---

## ✅ Checklist

- [ ] Ho un account Instagram (personale o business)
- [ ] Ho convertito in Instagram Business (se era personale)
- [ ] Ho collegato Instagram alla pagina Facebook
- [ ] Ho eseguito `./test_instagram_integration.sh`
- [ ] Test passato ✅
- [ ] Copiato configurazione nel controller
- [ ] Riavviato app Flutter
- [ ] Card Instagram visibile in dashboard

---

**Dopo il setup, Instagram funzionerà esattamente come Facebook!** 🎉

Stesse funzionalità:
- ✅ Metriche real-time
- ✅ Sync automatico
- ✅ Schermata dettaglio
- ✅ Analytics e insights
- ✅ Quick actions

---

**Durata setup**: ~2 minuti  
**Difficoltà**: Facile ⭐⭐☆☆☆
