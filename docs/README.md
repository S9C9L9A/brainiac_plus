# 📚 BrainiacPlus - Documentazione

Benvenuto nella documentazione di **BrainiacPlus**, l'app multi-platform (Linux/Android) per l'automazione dei social media.

---

## 🚀 Inizia Qui

### Per Utenti Finali

1. **[Quick Start](setup/QUICK_START.md)** - Installazione e primo avvio (5 minuti)
2. **[Configurazione Social Media](#-configurazione-social-media)** - Collega i tuoi account

### Per Sviluppatori

1. **[System Architecture](architecture/SYSTEM_ARCHITECTURE.md)** - Architettura del sistema
2. **[Go Backend Guide](architecture/GO_BACKEND_GUIDE.md)** - Backend API documentation
3. **[Maintenance Guide](guides/MAINTENANCE_GUIDE.md)** - Sviluppo e debug

---

## 📱 Configurazione Social Media

### Facebook
- **[Facebook Quick Start](setup/QUICK_START_FACEBOOK.md)** ⭐ Inizia qui (2 minuti)
- **[Facebook Token Guide](setup/FACEBOOK_TOKEN_GUIDE.md)** - Generazione e rinnovo token
- **[Test Results](guides/TEST_RESULTS.md)** - Funzionalità disponibili

### Instagram
- **[Instagram Quick Start](setup/INSTAGRAM_QUICK_START.md)** ⭐ Setup veloce (2 minuti)
- **[Instagram Setup Guide](setup/INSTAGRAM_SETUP_GUIDE.md)** - Guida completa

### Altri Servizi
- **[Service Config Guide](setup/SERVICE_CONFIG_GUIDE.md)** - YouTube, Twitter, ecc.

---

## 🏗️ Architettura

```
┌──────────────────────────────────────┐
│      BrainiacPlus (Utente PC)        │
├──────────────────────────────────────┤
│                                      │
│  Flutter App ←→ Go Backend           │
│  (UI/UX)        (localhost:8080)     │
│                                      │
│  ↓ API Calls                         │
│                                      │
│  Facebook Graph API                  │
│  Instagram Graph API                 │
│  YouTube Data API                    │
│  Twitter API                         │
└──────────────────────────────────────┘
```

**Caratteristiche chiave**:
- ✅ Backend locale (nessun server remoto)
- ✅ Privacy totale (dati sul tuo PC)
- ✅ Multi-account supportato
- ✅ Cross-platform (Linux, Android)

📖 [Architettura Completa](architecture/SYSTEM_ARCHITECTURE.md)

---

## 📖 Guide Dettagliate

### Setup e Installazione
- [Installation Guide](setup/INSTALLATION_GUIDE.md) - Installazione completa
- [Quick Start](setup/QUICK_START.md) - Avvio rapido
- [Service Config](setup/SERVICE_CONFIG_GUIDE.md) - Configurazione servizi

### Funzionalità
- [Facebook Automation](architecture/FACEBOOK_AUTOMATION_README.md) - Sistema automazioni Facebook
- [Social Media Cards](architecture/SOCIAL_MEDIA_CARDS_README.md) - Dashboard social cards
- [Test Results](guides/TEST_RESULTS.md) - Funzionalità testate

### Manutenzione
- [Maintenance Guide](guides/MAINTENANCE_GUIDE.md) - Debug e troubleshooting
- [Missing Permissions](guides/PERMESSO_MANCANTE.md) - Limitazioni API Facebook

---

## 🛠️ Comandi Utili

```bash
# Avvia l'app
flutter run -d linux

# Avvia backend (automatico all'avvio app)
cd go_backend && go run main.go

# Test Facebook
./test_facebook_automation.sh

# Test Instagram
./test_instagram_integration.sh

# Test completo sistema
./test_automazioni_complete.sh
```

---

## ❓ FAQ

**Q: Devo avere un server per usare BrainiacPlus?**  
A: No! Tutto gira sul tuo PC. Il backend è localhost:8080.

**Q: I miei dati sono al sicuro?**  
A: Sì, tutto è locale. Nessun dato viene inviato a server esterni (eccetto API social).

**Q: Posso usare più account social?**  
A: Sì, puoi collegare multipli account Facebook, Instagram, ecc.

**Q: Funziona su Android?**  
A: Sì, è multi-platform (Linux + Android).

**Q: Serve la Facebook App Review per usarlo?**  
A: No per le funzionalità di lettura (metriche, insights). Sì per pubblicare post automaticamente.

---

## 📞 Supporto

### Script di Test
- `test_facebook_automation.sh` - Test automazioni Facebook
- `test_instagram_integration.sh` - Test integrazione Instagram
- `test_automazioni_complete.sh` - Test completo sistema
- `demo_automation_scheduler.sh` - Demo animata automazioni

### Log e Debug
```bash
# Log backend
tail -f go_backend/logs/backend.log

# Log Flutter
flutter run -d linux --verbose

# Test API manuale
curl http://localhost:8080/api/v1/health
```

---

## 📂 Struttura Documentazione

```
docs/
├── README.md                  ← Sei qui
├── setup/                     ← Guide di installazione
│   ├── QUICK_START.md
│   ├── INSTALLATION_GUIDE.md
│   ├── QUICK_START_FACEBOOK.md
│   ├── FACEBOOK_TOKEN_GUIDE.md
│   ├── INSTAGRAM_QUICK_START.md
│   ├── INSTAGRAM_SETUP_GUIDE.md
│   └── SERVICE_CONFIG_GUIDE.md
├── architecture/              ← Architettura tecnica
│   ├── SYSTEM_ARCHITECTURE.md
│   ├── GO_BACKEND_GUIDE.md
│   ├── FACEBOOK_AUTOMATION_README.md
│   └── SOCIAL_MEDIA_CARDS_README.md
├── guides/                    ← Guide d'uso
│   ├── MAINTENANCE_GUIDE.md
│   ├── TEST_RESULTS.md
│   └── PERMESSO_MANCANTE.md
└── archive/                   ← Vecchie documentazioni
```

---

## 🎯 Prossimi Passi

1. **[Quick Start](setup/QUICK_START.md)** - Installa l'app
2. **[Facebook Setup](setup/QUICK_START_FACEBOOK.md)** - Collega Facebook (2 min)
3. **[Instagram Setup](setup/INSTAGRAM_QUICK_START.md)** - Collega Instagram (2 min)
4. **Usa l'app!** 🚀

---

**Versione**: 1.0.0  
**Ultima modifica**: 2026-02-16  
**Piattaforme**: Linux, Android  
**License**: MIT
