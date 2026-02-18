package routes

import (
	"net/http"
	"brainiac_backend/models"
	"brainiac_backend/services"
	"github.com/gin-gonic/gin"
)

// SetupFacebookRoutes configura tutti i route per Facebook
func SetupFacebookRoutes(r *gin.Engine) {
	facebookSvc := services.NewFacebookService()

	// Grupo di route per Facebook
	fb := r.Group("/api/facebook")
	{
		// Autenticazione
		fb.POST("/auth", func(c *gin.Context) {
			handleFacebookAuth(c, facebookSvc)
		})

		// Recupera le pagine dell'utente
		fb.GET("/pages", func(c *gin.Context) {
			handleGetPages(c, facebookSvc)
		})

		// Pubblica un post
		fb.POST("/post", func(c *gin.Context) {
			handlePostToPage(c, facebookSvc)
		})
	}
}

// handleFacebookAuth gestisce l'autenticazione con Facebook
func handleFacebookAuth(c *gin.Context, svc *services.FacebookService) {
	var req models.FacebookAuthRequest

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Dati non validi",
		})
		return
	}

	// Valida il token ricevuto dal frontend
	user, err := svc.ValidateUserToken(req.AccessToken)
	if err != nil {
		c.JSON(http.StatusUnauthorized, models.FacebookAuthResponse{
			Valid:   false,
			Message: err.Error(),
		})
		return
	}

	// TODO: Genera JWT per sessione interna
	// jwtToken := generateJWT(user.ID)

	c.JSON(http.StatusOK, models.FacebookAuthResponse{
		Valid:   true,
		User:    *user,
		Message: "Autenticazione riuscita",
		// Token: jwtToken,
	})
}

// handleGetPages recupera le pagine dell'utente
func handleGetPages(c *gin.Context, svc *services.FacebookService) {
	// TODO: Estrai il token dal header Authorization
	userToken := c.GetHeader("X-Facebook-Token")
	
	if userToken == "" {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "Token non fornito",
		})
		return
	}

	pages, err := svc.GetUserPages(userToken)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"pages": pages,
	})
}

// handlePostToPage pubblica un post su Facebook
func handlePostToPage(c *gin.Context, svc *services.FacebookService) {
	var req map[string]string

	if err := c.BindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Dati non validi",
		})
		return
	}

	pageID := req["page_id"]
	pageToken := req["page_token"]
	message := req["message"]

	if pageID == "" || pageToken == "" || message == "" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Mancano campi obbligatori: page_id, page_token, message",
		})
		return
	}

	postID, err := svc.PostToPage(pageID, pageToken, message)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"post_id": postID,
		"message": "Post pubblicato con successo",
	})
}
