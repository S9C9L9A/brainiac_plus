# 🤖 BrainiacPlus AI Vision - Self-Modifying System

**Data**: 2026-02-13
**Vision**: Sistema auto-adattivo guidato da AI conversazionale

---

## ✅ PROMPT CONTRACT (SEMPRE ATTIVO)

Per ogni prompt in questa chat:
1. Conferma che la richiesta e' allineata a questa AI_VISION.
2. Seleziona l'agente di dominio corretto e dichiara i path consentiti.
3. Se la richiesta tocca piu' domini, dividi il lavoro o chiedi approvazione.
4. Non modificare file bloccati (`pubspec.yaml`, `lib/main.dart`) senza richiesta esplicita.

---

## 🎯 OBIETTIVO FINALE

Trasformare BrainiacPlus in un **AGI-like assistant** che può:
1. Modificare se stesso basandosi su richieste in linguaggio naturale
2. Generare codice Flutter on-the-fly
3. Automatizzare task complessi
4. Adattarsi alle esigenze dell'utente

---

## 🔍 CHIARIMENTO: Packages Section

**Attuale**: La sezione "Packages" gestisce i pacchetti di SISTEMA (apt/snap)
- Es: installare/rimuovere Firefox, VSCode, etc.
- NON sono le dipendenze Flutter dell'app

**Dipendenze BrainiacPlus**: Sono in `pubspec.yaml`
- flutter_riverpod, lucide_icons, etc.
- Gestite da Flutter pub

---

## 🏗️ ARCHITETTURA PROPOSTA

### Dashboard Riprogettata (come Moltbot/Google AGI)

```
┌──────────────────────────────────────┐
│  BrainiacPlus AI Assistant      [⚙️] │
├──────────────────────────────────────┤
│                                      │
│  💬 Chat Interface                   │
│  ┌────────────────────────────────┐ │
│  │ User: "Aggiungi monitoraggio   │ │
│  │       temperatura CPU"          │ │
│  │                                 │ │
│  │ AI: "Sto implementando la       │ │
│  │     feature... ✅ Fatto!"       │ │
│  └────────────────────────────────┘ │
│                                      │
│  🎯 Quick Actions                    │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐           │
│  │CPU│ │RAM│ │Disk│ │Net│           │
│  └───┘ └───┘ └───┘ └───┘           │
│                                      │
│  📊 System Metrics (compact)         │
│  ━━━━━━━━━━ CPU 45%                 │
│  ━━━━━━━━━━ RAM 60%                 │
│  ━━━━━━━━━━ Disk 75%                │
│                                      │
│  🤖 AI Suggestions                   │
│  • "Libera 10GB di spazio disco"    │
│  • "Ottimizza avvio sistema"        │
│  • "Analizza processi lenti"        │
└──────────────────────────────────────┘
```

---

## 🧠 COMPONENTI AI SYSTEM

### 1. Ollama Integration
```dart
lib/features/ai_assistant/
├── ollama_service.dart     // API client
├── ai_chat_screen.dart     // Chat UI
├── code_generator.dart     // Code generation
└── task_executor.dart      // Execute generated code
```

### 2. Self-Modifying Capability
```dart
// AI genera codice → Compila → Hot reload
AI: "Voglio monitorare temperatura"
→ Genera: temperature_monitor.dart
→ Compila: flutter pub run build_runner
→ Hot reload: Inject in app
```

### 3. Natural Language → Actions
```
User: "Mostrami i processi che usano più RAM"
AI: Capisce intent → Esegue comando → Mostra risultato

User: "Crea automazione per backup ogni giorno"
AI: Genera task automation → Salva in DB → Attiva scheduler
```

---

## 🔧 IMPLEMENTAZIONE FASI

### FASE 1: Ollama Setup ✅ (Prossimo)
- [ ] Installare Ollama su sistema
- [ ] Creare ollama_service.dart
- [ ] Test comunicazione con API
- [ ] Modello: llama2, codellama, mistral

### FASE 2: Chat Interface ⏳
- [ ] Riprogettare dashboard con chat
- [ ] Quick actions integrate
- [ ] System metrics compatte
- [ ] AI suggestions

### FASE 3: Code Generation 🔮
- [ ] AI genera widget Flutter
- [ ] Template system per common tasks
- [ ] Validation & safety checks
- [ ] Hot reload integration

### FASE 4: Self-Modification 🚀
- [ ] AI modifica propri file
- [ ] Version control (git commits)
- [ ] Rollback mechanism
- [ ] User approval workflow

---

## ⚠️ SAFETY & CONSTRAINTS

### Cosa AI PUÒ fare:
✅ Generare nuovi widget
✅ Creare automation tasks
✅ Modificare UI esistente
✅ Aggiungere features in sandbox

### Cosa AI NON PUÒ fare:
❌ Modificare core system files senza approval
❌ Eseguire comandi pericolosi
❌ Accedere a dati sensibili
❌ Modificare security settings

### Approval Workflow:
```
AI genera codice
  ↓
User preview (diff)
  ↓
User approva/rifiuta
  ↓
Se approvato → Applica + Git commit
```

---

## 🎨 UI REDESIGN CONCEPTS

### Concept 1: Chat-First
- Chat al centro
- Metrics sidebar
- Quick actions floating

### Concept 2: Hybrid (Raccomandato)
- Chat bar in alto (collapsible)
- System metrics cards (attuale)
- Quick actions integrate
- AI suggestions bottom

### Concept 3: Command Palette
- Cmd+K → AI command bar
- Metrics in background
- Overlay chat quando richiesto

---

## 🚀 ROADMAP

**Week 1** (Ora):
- Setup Ollama
- Chat interface base
- Dashboard redesign

**Week 2**:
- Code generation templates
- Task automation AI
- Safety checks

**Week 3**:
- Self-modification (sandbox)
- Hot reload integration
- User approval system

**Week 4**:
- Production ready
- Testing
- Documentation

---

**Status**: 🔵 PLANNING  
**Complexity**: ⭐⭐⭐⭐⭐ (Very High)  
**Feasibility**: ✅ Possible with constraints