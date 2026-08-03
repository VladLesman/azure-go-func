package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

// helloHandler — функция-обработчик HTTP-запроса.
// w (http.ResponseWriter) — отвечает за то, ЧТО мы отправляем клиенту (тело, заголовки, статус-код).
// r (*http.Request) — содержит всё, ЧТО пришло от клиента (URL, заголовки, параметры, тело).
func helloHandler(w http.ResponseWriter, r *http.Request) {
	// 1. Устанавливаем заголовок Content-Type в JSON
	w.Header().Set("Content-Type", "application/json")
	
	// 2. Устанавливаем HTTP-статус 200 OK
	w.WriteHeader(http.StatusOK)

	// 3. Читаем переменную окружения (пробросим её позже через Ansible!)
	envName := os.Getenv("ENVIRONMENT")
	if envName == "" {
		envName = "local"
	}

	// 4. Формируем JSON-ответ
	jsonResponse := fmt.Sprintf(`{"status":"success", "message":"Hello from Azure Functions on Go!", "environment":"%s"}`, envName)

	// 5. Отправляем ответ клиенту
	w.Write([]byte(jsonResponse))
}

func main() {
	// Azure Functions передаёт порт через FUNCTIONS_CUSTOMHANDLER_PORT
	customHandlerPort, exists := os.LookupEnv("FUNCTIONS_CUSTOMHANDLER_PORT")
	if !exists {
		customHandlerPort = "8080" // Дефолтный порт для локальной отладки
	}

	// Регистрируем маршрут: при запросе на /api/hello вызывать helloHandler
	http.HandleFunc("/api/hello", helloHandler)

	// Логируем запуск
	log.Printf("Go Custom Handler server starting on port %s...", customHandlerPort)

	// Запускаем HTTP-сервер. ListenAndServe блокирует выполнение и слушаeт входящие соединения.
	log.Fatal(http.ListenAndServe(":"+customHandlerPort, nil))
}