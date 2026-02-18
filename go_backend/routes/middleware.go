package routes

import (
	"net/http"
	"strings"
	"brainiac_backend/services"
	"github.com/gin-gonic/gin"
)

// JWTMiddleware verifica il token JWT nelle richieste autenticate
func JWTMiddleware(jwtSvc *services.JWTService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Authorization header mancante",
			})
			c.Abort()
			return
		}

		// Estrai il token dal header "Bearer TOKEN"
		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "Formato Authorization non valido",
			})
			c.Abort()
			return
		}

		token := parts[1]
		claims, err := jwtSvc.ValidateToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": err.Error(),
			})
			c.Abort()
			return
		}

		// Salva i dati nel context per usarli nei handler
		c.Set("user_id", claims.UserID)
		c.Set("email", claims.Email)
		c.Set("name", claims.Name)

		c.Next()
	}
}
