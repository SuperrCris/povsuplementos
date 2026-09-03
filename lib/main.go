package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

var ordenesSSE sync.Map // map[string]chan string — clave: referencia UUID de la orden

const mercadoPagoOrdenesURL = "https://api.mercadopago.com/v1/orders"
const clavepos1 = "REMOVED"
const clavepos2 = "REMOVED"
const clavepos3 = "REMOVED"

var claves = []string{
	clavepos1,
	clavepos2,
	clavepos3,
}

func claveMercadoPago() string {
	if v := os.Getenv("MP_ACCESS_TOKEN"); v != "" {
		return v
	}
	// clave test (fallback local)
	return "REMOVED"
}

type Pago struct {
	Monto string `json:"amount"`
}

type Transacciones struct {
	Pagos []Pago `json:"payments"`
}

type Configuraciones struct {
	Point      PointConfig `json:"point"`
	MetodoPago MetodoPago  `json:"payment_method"`
}

type PointConfig struct {
	IDdeTerminal string `json:"terminal_id"`
	Imprimir     string `json:"print_on_terminal"`
}

type MetodoPago struct {
	Tipo string `json:"default_type"`
}

type IntegradorID struct {
	ID string `json:"integrator_id"`
}

type Orden struct {
	Tipo              string          `json:"type"`
	ReferenciaExterna string          `json:"external_reference"`
	Expiracion        string          `json:"expiration_time"`
	Transacciones     Transacciones   `json:"transactions"`
	Configuraciones   Configuraciones `json:"config"`
	Descripcion       string          `json:"description"`
	InfoDeIntegracion IntegradorID    `json:"integration_data"`
}

type Argumentos struct {
	IDSucursal  string `json:"idsucursal"`
	IDTerminal  string `json:"idterminal"`
	Monto       string `json:"monto"`
	Descripcion string `json:"descripcion"`
}

type PagoInfo struct {
	ID                string `json:"id"`
	Estatus           string `json:"status"`
	ExternalReference string `json:"external_reference"`
}

func crearOrden(w http.ResponseWriter, r *http.Request) {

	clave := r.Header.Get("Authorization")
	claveValida := false
	for _, c := range claves {
		if clave == c {
			claveValida = true
			break
		}
	}
	if !claveValida {
		http.Error(w, "No autorizado", http.StatusUnauthorized)
		return
	}

	fmt.Printf("Ha entrado %s\n", clave)

	args := Argumentos{
		IDSucursal:  r.URL.Query().Get("idsucursal"),
		IDTerminal:  r.URL.Query().Get("idterminal"),
		Monto:       r.URL.Query().Get("monto"),
		Descripcion: r.URL.Query().Get("descripcion"),
	}

	if args.Monto == "" {
		http.Error(w, "No hay monto", http.StatusBadRequest)
		return
	}

	fmt.Printf("idsucursal: %s, idterminal: %s, monto: %s, descripcion: %s\n", args.IDSucursal, args.IDTerminal, args.Monto, args.Descripcion)

	montoFloat, err := strconv.ParseFloat(args.Monto, 64)
	if err != nil || montoFloat <= 0 {
		http.Error(w, "Monto inválido", http.StatusBadRequest)
		return
	}
	montoFormateado := fmt.Sprintf("%.2f", montoFloat)

	referencia := uuid.NewString()

	orden := Orden{
		Tipo:              "point",
		ReferenciaExterna: referencia,
		Expiracion:        "PT16M",
		Transacciones: Transacciones{
			Pagos: []Pago{
				{Monto: montoFormateado},
			},
		},
		Configuraciones: Configuraciones{
			Point: PointConfig{
				IDdeTerminal: "NEWLAND_N950__N950NCC503419358",
				Imprimir:     "seller_ticket",
			},
			MetodoPago: MetodoPago{
				Tipo: "credit_card",
			},
		},
		Descripcion: args.Descripcion,
		InfoDeIntegracion: IntegradorID{
			ID: "dev_784631003",
		},
	}

	jsonOrden, err := json.Marshal(orden)
	if err != nil {
		http.Error(w, "Error al codificar la orden a JSON", http.StatusInternalServerError)
		return
	}

	solicitud, err := http.NewRequest("POST", mercadoPagoOrdenesURL, bytes.NewBuffer(jsonOrden))
	if err != nil {
		http.Error(w, "Error al crear la solicitud HTTP", http.StatusInternalServerError)
		return
	}

	solicitud.Header.Set("Content-Type", "application/json")
	solicitud.Header.Set("Authorization", "Bearer "+claveMercadoPago())
	solicitud.Header.Set("X-Idempotency-Key", uuid.NewString())
	fmt.Printf("Solicitud creada con body: %s\n", string(jsonOrden))
	resp, err := http.DefaultClient.Do(solicitud)
	if err != nil {
		http.Error(w, "Error al enviar la solicitud a MercadoPago", http.StatusInternalServerError)
		return
	}

	defer resp.Body.Close()

	respCuerpo, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Error al leer la respuesta de MercadoPago", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)

	// Inyectar el campo "reference" (UUID local) en la respuesta para que Flutter lo use en el SSE
	if resp.StatusCode == http.StatusCreated {
		var respMap map[string]interface{}
		if err := json.Unmarshal(respCuerpo, &respMap); err == nil {
			respMap["reference"] = referencia
			if modificado, err := json.Marshal(respMap); err == nil {
				w.Write(modificado)
				return
			}
		}
	}
	w.Write(respCuerpo)
}

type OrdenInfo struct {
	ID                string `json:"id"`
	Estatus           string `json:"status"`
	ExternalReference string `json:"external_reference"`
}

type WebhookBody struct {
	Type string `json:"type"`
	Data struct {
		ID string `json:"id"`
	} `json:"data"`
}

func manejarWebhook(w http.ResponseWriter, r *http.Request) {

	if r.Method != http.MethodPost {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	// MercadoPago puede enviar los datos como query params O como JSON en el body
	tipo := r.URL.Query().Get("type")
	id := r.URL.Query().Get("data.id")
	externalReference := r.URL.Query().Get("data.external_reference")

	// Debug: imprimir el raw query para diagnosticar encoding de claves con puntos
	fmt.Printf("Webhook raw query: %s\n", r.URL.RawQuery)

	// Fallback: parsear el raw query manualmente por si los puntos están URL-encoded
	if id == "" || externalReference == "" {
		fmt.Printf("Intentando parsear manualmente el raw query por claves con puntos...\n")
		for _, part := range strings.Split(r.URL.RawQuery, "&") {
			kv := strings.SplitN(part, "=", 2)
			if len(kv) != 2 {
				continue
			}
			key := kv[0]
			val := kv[1]
			// Normalizar: data%2Eid → data.id
			key = strings.ReplaceAll(key, "%2E", ".")
			key = strings.ReplaceAll(key, "%2e", ".")
			switch key {
			case "data.id":
				if id == "" {
					id = val
				}
			case "data.external_reference":
				if externalReference == "" {
					externalReference = val
				}
			}
		}
	}

	cuerpo, err := io.ReadAll(r.Body)
	if err == nil && len(cuerpo) > 0 {
		fmt.Printf("Webhook body: %s\n", string(cuerpo))
		// Si los query params están vacíos, intentar leer del body JSON
		if tipo == "" || id == "" {
			fmt.Printf("Intentando parsear tipo e id desde el body JSON...\n")
			var wb WebhookBody
			if err := json.Unmarshal(cuerpo, &wb); err == nil {
				if tipo == "" {
					tipo = wb.Type
				}
				if id == "" {
					id = wb.Data.ID
				}
			}
		}
	}

	fmt.Printf("Webhook recibido: type=%s, id=%s, ref=%s\n", tipo, id, externalReference)

	switch tipo {
	case "payment":
		go obtenerInfoPago(id)
	case "order":
		go obtenerInfoOrden(id, externalReference)
	default:
		fmt.Printf("Webhook ignorado: tipo no manejado '%s'\n", tipo)
	}

	w.WriteHeader(http.StatusOK)
}

func obtenerInfoOrden(ordenId string, externalReference string) {
	var ordenInfo OrdenInfo

	if ordenId != "" {
		// Camino normal: consultar por ID de orden
		url := fmt.Sprintf("https://api.mercadopago.com/v1/orders/%s", ordenId)
		req, _ := http.NewRequest("GET", url, nil)
		req.Header.Add("Authorization", "Bearer "+claveMercadoPago())

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Error consultando orden %s: %v\n", ordenId, err)
			return
		}
		defer resp.Body.Close()

		respuesta, _ := io.ReadAll(resp.Body)
		fmt.Printf("Info de orden %s: %s\n", ordenId, string(respuesta))
		json.Unmarshal(respuesta, &ordenInfo)
	} else if externalReference != "" {
		// Fallback: buscar por external_reference
		fmt.Printf("id vacío, buscando por external_reference: %s\n", externalReference)
		url := fmt.Sprintf("https://api.mercadopago.com/v1/orders/search?external_reference=%s", externalReference)
		req, _ := http.NewRequest("GET", url, nil)
		req.Header.Add("Authorization", "Bearer "+claveMercadoPago())

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			fmt.Printf("Error buscando orden por ref %s: %v\n", externalReference, err)
			return
		}
		defer resp.Body.Close()

		respuesta, _ := io.ReadAll(resp.Body)
		fmt.Printf("Búsqueda por ref %s: %s\n", externalReference, string(respuesta))

		// La respuesta es un array: [{"id":...,"status":...,"external_reference":...}]
		var ordenes []OrdenInfo
		if err := json.Unmarshal(respuesta, &ordenes); err != nil || len(ordenes) == 0 {
			fmt.Printf("No se encontró orden para ref %s\n", externalReference)
			return
		}
		ordenInfo = ordenes[0]
	} else {
		fmt.Printf("Webhook sin id ni external_reference, ignorando\n")
		return
	}

	// Usar la external_reference del query param si MP no la devuelve en el body
	ref := ordenInfo.ExternalReference
	if ref == "" {
		ref = externalReference
	}

	estado := "failed"
	switch ordenInfo.Estatus {
	case "processed":
		estado = "processed"
	case "canceled":
		estado = "canceled"
	}

	payload := fmt.Sprintf(`{"status":"%s"}`, estado)
	fmt.Printf("Notificando SSE ref=%s estado=%s\n", ref, estado)

	if ch, ok := ordenesSSE.Load(ref); ok {
		ch.(chan string) <- payload
	} else {
		fmt.Printf("No se encontró canal SSE para la referencia: %s\n", ref)
	}
}

func obtenerInfoPago(pagoid string) {

	url := fmt.Sprintf("https://api.mercadopago.com/v1/payments/%s", pagoid)

	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Add("Authorization", "Bearer "+claveMercadoPago())

	client := &http.Client{}
	resp, err := client.Do(req)

	if err != nil {
		fmt.Printf("error creando solicitud")
		return
	}

	defer resp.Body.Close()

	respuesta, _ := io.ReadAll(resp.Body)
	fmt.Printf("respuesta del pago: %s", string(respuesta))

	var pagoInfo PagoInfo
	if err := json.Unmarshal(respuesta, &pagoInfo); err != nil {
		fmt.Printf("Error al decodificar el JSON del pago: %v", err)
		return
	}

	if pagoInfo.Estatus == "approved" {
		fmt.Printf("Pago aprobado: %s", pagoInfo.ID)
	}

	estado := "failed"
	if pagoInfo.Estatus == "approved" {
		estado = "processed"
	}
	payload := fmt.Sprintf(`{"status":"%s"}`, estado)

	if ch, ok := ordenesSSE.Load(pagoInfo.ExternalReference); ok {
		ch.(chan string) <- payload
	} else {
		fmt.Printf("No se encontró canal SSE para la referencia: %s\n", pagoInfo.ExternalReference)
	}
}

func manejarStream(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	referencia := strings.TrimPrefix(r.URL.Path, "/stream/")
	if referencia == "" {
		http.Error(w, "Falta el ID de referencia", http.StatusBadRequest)
		return
	}

	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming no soportado", http.StatusInternalServerError)
		return
	}

	ch := make(chan string, 1)
	ordenesSSE.Store(referencia, ch)
	defer ordenesSSE.Delete(referencia)

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	fmt.Printf("SSE: cliente conectado para referencia %s\n", referencia)

	// Nota: Cloud Run debe tener el timeout del servicio configurado en >= 600s
	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	timeout := time.After(10 * time.Minute)

	for {
		select {
		case evento := <-ch:
			fmt.Fprintf(w, "data: %s\n\n", evento)
			flusher.Flush()
			return
		case <-ticker.C:
			// Keepalive: evita que proxies y Cloud Run cierren la conexión por inactividad
			fmt.Fprintf(w, ": ping\n\n")
			flusher.Flush()
		case <-r.Context().Done():
			fmt.Printf("SSE: cliente desconectado para referencia %s\n", referencia)
			return
		case <-timeout:
			fmt.Fprintf(w, "data: {\"status\":\"timeout\"}\n\n")
			flusher.Flush()
			return
		}
	}
}

func cancelarOrden(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	ordenID := r.URL.Query().Get("id")
	if ordenID == "" {
		http.Error(w, "No se proporcionó el ID de la orden", http.StatusBadRequest)
		return
	}

	req, err := http.NewRequest("POST", fmt.Sprintf("https://api.mercadopago.com/v1/orders/%s/cancel", ordenID), nil)
	if err != nil {
		http.Error(w, "Error al crear la solicitud HTTP", http.StatusInternalServerError)
		return
	}

	req.Header.Set("Authorization", "Bearer "+claveMercadoPago())

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		http.Error(w, "Error al enviar la solicitud a MercadoPago", http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	respCuerpo, err := io.ReadAll(resp.Body)
	if err != nil {
		http.Error(w, "Error al leer la respuesta de MercadoPago", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(resp.StatusCode)
	w.Write(respCuerpo)

}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}
	fmt.Println("Servidor iniciado en :" + port)
	http.HandleFunc("/crearorden", crearOrden)
	http.HandleFunc("/webhook", manejarWebhook)
	http.HandleFunc("/cancelar", cancelarOrden)
	http.HandleFunc("/stream/", manejarStream)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatal(err)
	}
}
