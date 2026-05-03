# 🔧 Backend Agent

**Dominio**: `go_backend/`

---

## 🎯 Responsabilità

- REST API server (Gin framework)
- OAuth callbacks e token management
- Social media API proxy
- Ollama API relay
- Cross-platform sync endpoints

---

## 📁 Files Owned

```
go_backend/
├── main.go                           # Server entry point
├── go.mod                            # Go module definition
├── go.sum                            # Dependencies lock
├── .env                              # Environment variables (BLOCKED)
├── .env.example                      # Env template
├── models/
│   ├── facebook.go                   # Facebook data models
│   ├── instagram.go                  # Instagram data models
│   ├── task.go                       # Task models
│   └── sync.go                       # Sync models
├── routes/
│   ├── facebook.go                   # Facebook endpoints
│   ├── instagram.go                  # Instagram endpoints
│   ├── ollama.go                     # Ollama proxy
│   └── middleware.go                 # CORS, auth middleware
└── services/
    ├── facebook.go                   # Facebook Graph API client
    ├── instagram.go                  # Instagram Graph API client
    ├── jwt.go                        # JWT generation/validation
    └── ollama.go                     # Ollama HTTP client
```

---

## 🔧 Capabilities

- ✅ REST API development
- ✅ OAuth callback handling
- ✅ Token refresh automation
- ✅ Rate limiting
- ✅ Request logging
- ✅ Error handling middleware

---

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/facebook/auth` | Facebook OAuth |
| GET | `/api/facebook/pages` | Get user pages |
| POST | `/api/facebook/post` | Post to page |
| POST | `/api/instagram/auth` | Instagram OAuth |
| POST | `/api/instagram/post` | Post to Instagram |
| POST | `/api/ollama/chat` | Chat with Ollama |
| POST | `/api/ollama/generate` | Generate text |
| GET | `/api/tasks` | List tasks |
| POST | `/api/tasks` | Create task |
| DELETE | `/api/tasks/:id` | Delete task |
| POST | `/api/sync` | Sync data |

---

## 🔗 Dipendenze

- `settings.agent.md` → OAuth credentials
- `automation.agent.md` → Task execution
- `ai_assistant.agent.md` → Ollama relay

---

## 📖 Esempio Codice

```go
// Handler example
func HandlePostToFacebook(c *gin.Context) {
    var req PostRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }
    
    result, err := facebookService.Post(req.PageID, req.Message)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    
    c.JSON(http.StatusOK, result)
}
```

---

## 🛡️ Security Notes

- **CORS**: Configurato per localhost only
- **JWT**: Required per endpoints protetti
- **Secrets**: Mai loggati, solo da .env
- **Rate Limit**: 100 req/min per client

---

## 🚀 Comandi

```bash
# Run server
cd go_backend && go run main.go

# Build
cd go_backend && go build -o brainiac_backend

# Test
cd go_backend && go test ./...
```
