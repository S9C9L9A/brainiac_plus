package main

import (
	"log"
	"net/http"
	"os"
	"github.com/gin-gonic/gin"
	"brainiac_backend/routes"
)

// BrainiacPlus Go Backend
// REST API for Ollama integration and cross-platform sync

type HealthResponse struct {
	Status  string `json:"status"`
	Version string `json:"version"`
}

type OllamaRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
}

type OllamaResponse struct {
	Response string `json:"response"`
	Model    string `json:"model"`
}

func main() {
	r := gin.Default()

	// CORS middleware
	r.Use(func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	})

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, HealthResponse{
			Status:  "ok",
			Version: "2.0.0-alpha",
		})
	})

	// Ollama AI endpoints
	r.POST("/api/ollama/chat", handleOllamaChat)
	r.POST("/api/ollama/generate", handleOllamaGenerate)

	// Task automation endpoints
	r.GET("/api/tasks", getTasks)
	r.POST("/api/tasks", createTask)
	r.DELETE("/api/tasks/:id", deleteTask)

	// Sync endpoints
	r.POST("/api/sync", handleSync)

	// Facebook integration routes
	routes.SetupFacebookRoutes(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("🧠 BrainiacPlus Backend starting on :" + port)
	r.Run(":" + port)
}

// Ollama chat handler
func handleOllamaChat(c *gin.Context) {
	var req OllamaRequest
	
	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement actual Ollama API call
	// For now, mock response
	c.JSON(http.StatusOK, OllamaResponse{
		Response: "Mock AI response. Ollama integration coming soon.",
		Model:    req.Model,
	})
}

// Ollama generate handler
func handleOllamaGenerate(c *gin.Context) {
	var req OllamaRequest
	
	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// TODO: Implement actual Ollama API call
	c.JSON(http.StatusOK, OllamaResponse{
		Response: "Generated text from Ollama",
		Model:    req.Model,
	})
}

// Get all tasks
func getTasks(c *gin.Context) {
	// TODO: Implement database query
	c.JSON(http.StatusOK, gin.H{
		"tasks": []interface{}{},
	})
}

// Create new task
func createTask(c *gin.Context) {
	// TODO: Implement task creation
	c.JSON(http.StatusCreated, gin.H{
		"message": "Task created",
	})
}

// Delete task
func deleteTask(c *gin.Context) {
	taskID := c.Param("id")
	// TODO: Implement task deletion
	c.JSON(http.StatusOK, gin.H{
		"message": "Task deleted",
		"id":      taskID,
	})
}

// Sync handler
func handleSync(c *gin.Context) {
	// TODO: Implement Supabase sync logic
	c.JSON(http.StatusOK, gin.H{
		"status": "synced",
	})
}
