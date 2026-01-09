package main

import (
	"bufio"
	"crypto/rand"
	"crypto/rsa"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/json"
	"encoding/pem"
	"fmt"
	"io"
	"log"
	"math/big"
	"net"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"
)

// --- 数据结构 ---

type MockResponse struct {
	StatusCode int               `json:"statusCode"`
	Headers    map[string]string `json:"headers"`
	Body       string            `json:"body"`
	Delay      int               `json:"delay"` // New field for response delay in milliseconds
}

type MockRule struct {
	ID        string       `json:"id"`
	Enabled   bool         `json:"enabled"`
	Name      string       `json:"name"`
	URL       string       `json:"url"`
	MatchType string       `json:"matchType"` // exact, prefix, regex
	Response  MockResponse `json:"response"`
}

type TrafficLog struct {
	ID         string    `json:"id"`
	Time       time.Time `json:"time"`
	Method     string    `json:"method"`
	URL        string    `json:"url"`
	StatusCode int       `json:"statusCode"`
	Mocked     bool      `json:"mocked"`
	Duration   string    `json:"duration"`
}

type Config struct {
	Rules []MockRule `json:"rules"`
}

// --- 全局变量 ---

var (
	config      Config
	configMu    sync.RWMutex
	configFile  = "config.json"
	trafficLogs []TrafficLog
	logsMu      sync.Mutex
	maxLogs     = 500
	certManager *CertManager

	defaultTransport = &http.Transport{
		DisableCompression: true,
		MaxIdleConns:       100,
		IdleConnTimeout:    90 * time.Second,
		TLSClientConfig:    &tls.Config{InsecureSkipVerify: true},
	}
)

// --- 证书管理 (MITM) ---

type CertManager struct {
	caCert *x509.Certificate
	caKey  *rsa.PrivateKey
	mu     sync.RWMutex
	certs  map[string]*tls.Certificate
}

func NewCertManager() (*CertManager, error) {
	cm := &CertManager{certs: make(map[string]*tls.Certificate)}
	if err := cm.loadCA(); err != nil {
		log.Println("[CERT] 正在生成 CA 证书...")
		if err := cm.generateCA(); err != nil {
			return nil, err
		}
	}
	return cm, nil
}

func (cm *CertManager) loadCA() error {
	certPEM, err := os.ReadFile("ca.crt")
	if err != nil {
		return err
	}
	keyPEM, err := os.ReadFile("ca.key")
	if err != nil {
		return err
	}
	certBlock, _ := pem.Decode(certPEM)
	keyBlock, _ := pem.Decode(keyPEM)
	caCert, err := x509.ParseCertificate(certBlock.Bytes)
	if err != nil {
		return err
	}
	caKey, err := x509.ParsePKCS1PrivateKey(keyBlock.Bytes)
	if err != nil {
		return err
	}
	cm.caCert = caCert
	cm.caKey = caKey
	return nil
}

func (cm *CertManager) generateCA() error {
	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return err
	}
	serialNumber, _ := rand.Int(rand.Reader, new(big.Int).Lsh(big.NewInt(1), 128))
	template := x509.Certificate{
		SerialNumber: serialNumber,
		Subject: pkix.Name{
			Organization:       []string{"Proxy Mock CA"},
			OrganizationalUnit: []string{"MITM Development"},
			CommonName:         "Proxy Mock Root CA",
		},
		NotBefore:             time.Now().Add(-24 * time.Hour),
		NotAfter:              time.Now().AddDate(10, 0, 0),
		KeyUsage:              x509.KeyUsageCertSign | x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		BasicConstraintsValid: true,
		IsCA:                  true,
	}
	derBytes, err := x509.CreateCertificate(rand.Reader, &template, &template, &priv.PublicKey, priv)
	if err != nil {
		return err
	}
	os.WriteFile("ca.crt", pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: derBytes}), 0644)
	os.WriteFile("ca.key", pem.EncodeToMemory(&pem.Block{Type: "RSA PRIVATE KEY", Bytes: x509.MarshalPKCS1PrivateKey(priv)}), 0600)
	return cm.loadCA()
}

func (cm *CertManager) RegenerateCA() error {
	cm.mu.Lock()
	defer cm.mu.Unlock()
	cm.certs = make(map[string]*tls.Certificate) // Clear cache
	return cm.generateCA()
}

func (cm *CertManager) GetCertificate(host string) (*tls.Certificate, error) {
	if h, _, err := net.SplitHostPort(host); err == nil {
		host = h
	}
	cm.mu.RLock()
	if cert, ok := cm.certs[host]; ok {
		cm.mu.RUnlock()
		return cert, nil
	}
	cm.mu.RUnlock()

	cm.mu.Lock()
	defer cm.mu.Unlock()
	if cert, ok := cm.certs[host]; ok {
		return cert, nil
	}

	priv, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		return nil, err
	}
	serialNumber, _ := rand.Int(rand.Reader, new(big.Int).Lsh(big.NewInt(1), 128))
	template := x509.Certificate{
		SerialNumber:          serialNumber,
		Subject: pkix.Name{
			Organization:       []string{"Proxy Mock CA"},
			OrganizationalUnit: []string{"MITM Development"},
			CommonName:         host,
		},
		NotBefore:             time.Now().Add(-1 * time.Hour),
		NotAfter:              time.Now().AddDate(1, 0, 0),
		KeyUsage:              x509.KeyUsageDigitalSignature,
		ExtKeyUsage:           []x509.ExtKeyUsage{x509.ExtKeyUsageServerAuth},
		DNSNames:              []string{host},
		BasicConstraintsValid: true,
	}
	derBytes, err := x509.CreateCertificate(rand.Reader, &template, cm.caCert, &priv.PublicKey, cm.caKey)
	if err != nil {
		return nil, err
	}
	cert := &tls.Certificate{Certificate: [][]byte{derBytes}, PrivateKey: priv}
	cm.certs[host] = cert
	return cert, nil
}

// --- 逻辑函数 ---

func addTrafficLog(logEntry TrafficLog) {
	logsMu.Lock()
	defer logsMu.Unlock()
	trafficLogs = append([]TrafficLog{logEntry}, trafficLogs...)
	if len(trafficLogs) > maxLogs {
		trafficLogs = trafficLogs[:maxLogs]
	}
}

func loadConfig() {
	configMu.Lock()
	defer configMu.Unlock()
	data, err := os.ReadFile(configFile)
	if err == nil {
		_ = json.Unmarshal(data, &config)
	} else {
		config = Config{Rules: []MockRule{}}
	}
}

func saveConfig() {
	configMu.RLock()
	defer configMu.RUnlock()
	data, _ := json.MarshalIndent(config, "", "  ")
	os.WriteFile(configFile, data, 0644)
}

func findMatch(reqURL string) *MockRule {
	configMu.RLock()
	defer configMu.RUnlock()
	for _, rule := range config.Rules {
		if !rule.Enabled {
			continue
		}
		matched := false
		switch rule.MatchType {
		case "exact":
			matched = reqURL == rule.URL
		case "prefix":
			matched = strings.HasPrefix(reqURL, rule.URL)
		case "regex":
			re, err := regexp.Compile(rule.URL)
			if err == nil {
				matched = re.MatchString(reqURL)
			}
		}
		if matched {
			return &rule
		}
	}
	return nil
}

// --- HTTP 处理器 ---

func handleProxy(w http.ResponseWriter, r *http.Request) {
	// 管理后台判断
	host, _, _ := net.SplitHostPort(r.Host)
	if host == "" {
		host = r.Host
	}

	// 代理逻辑 - 只有当 Host 是 localhost:9292 且不是 CONNECT 时才认为是管理后台
	if r.Method != http.MethodConnect && (host == "localhost" || host == "127.0.0.1") && strings.HasSuffix(r.Host, ":9292") {
		handleManagementAPI(w, r)
		return
	}

	log.Printf("[PROXY] Recv Request: %s %s (Host: %s)", r.Method, r.URL.String(), r.Host)
	// 代理逻辑
	if r.Method == http.MethodConnect {
		handleHTTPSMITM(w, r)
	} else {
		fullURL := r.URL.String()
		if !r.URL.IsAbs() {
			fullURL = "http://" + r.Host + r.URL.RequestURI()
		}
		processRequest(w, r, fullURL)
	}
}

func handleManagementAPI(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	if r.Method == http.MethodOptions {
		return
	}

	// Serve static assets from "dist/assets"
	if strings.HasPrefix(r.URL.Path, "/assets/") {
		http.StripPrefix("/assets/", http.FileServer(http.Dir("dist/assets"))).ServeHTTP(w, r)
		return
	}

	switch r.URL.Path {
	case "/api/info":
		json.NewEncoder(w).Encode(map[string]string{
			"ip":   getLocalIP(),
			"port": "9292",
		})
	case "/":
		http.ServeFile(w, r, "dist/index.html")
	case "/ca.crt":
		w.Header().Set("Content-Type", "application/x-x509-ca-cert")
		http.ServeFile(w, r, "ca.crt")
	case "/api/traffic":
		logsMu.Lock()
		count := len(trafficLogs)
		json.NewEncoder(w).Encode(trafficLogs)
		logsMu.Unlock()
		if r.URL.Query().Get("silent") != "true" {
			log.Printf("[API] GET /api/traffic - Returned %d logs", count)
		}
	case "/api/config":
		if r.Method == http.MethodGet {
			configMu.RLock()
			json.NewEncoder(w).Encode(config)
			configMu.RUnlock()
		} else if r.Method == http.MethodPost {
			var newConfig Config
			if err := json.NewDecoder(r.Body).Decode(&newConfig); err == nil {
				configMu.Lock()
				config = newConfig
				configMu.Unlock()
				saveConfig()
			}
		}
	case "/api/ca/generate":
		if r.Method == http.MethodPost {
			if err := certManager.RegenerateCA(); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
			}
		}
	case "/api/traffic/clear":
		if r.Method == http.MethodPost {
			logsMu.Lock()
			trafficLogs = []TrafficLog{}
			logsMu.Unlock()
			w.WriteHeader(http.StatusOK)
			log.Println("[API] POST /api/traffic/clear - Traffic logs cleared")
		}
	default:
		http.NotFound(w, r)
	}
}

func processRequest(w http.ResponseWriter, r *http.Request, fullURL string) {
	start := time.Now()
	var statusCode int
	var mocked bool

	if rule := findMatch(fullURL); rule != nil {
		if rule.Response.Delay > 0 {
			log.Printf("[MOCK] Applying delay %dms for rule '%s'", rule.Response.Delay, rule.Name)
			time.Sleep(time.Duration(rule.Response.Delay) * time.Millisecond)
		}
		log.Printf("[MOCK] Matched rule '%s' for %s", rule.Name, fullURL)
		for k, v := range rule.Response.Headers {
			w.Header().Set(k, v)
		}
		w.WriteHeader(rule.Response.StatusCode)
		w.Write([]byte(rule.Response.Body))
		statusCode = rule.Response.StatusCode
		mocked = true
	} else {
		resp, err := forwardRequest(r)
		if err != nil {
			http.Error(w, err.Error(), http.StatusServiceUnavailable)
			return
		}
		defer resp.Body.Close()
		for k, vv := range resp.Header {
			for _, v := range vv {
				w.Header().Add(k, v)
			}
		}
		w.WriteHeader(resp.StatusCode)
		io.Copy(w, resp.Body)
		statusCode = resp.StatusCode
	}

	addTrafficLog(TrafficLog{
		ID:         fmt.Sprintf("%d", time.Now().UnixNano()),
		Time:       time.Now(),
		Method:     r.Method,
		URL:        fullURL,
		StatusCode: statusCode,
		Mocked:     mocked,
		Duration:   time.Since(start).String(),
	})
}

func handleHTTPSMITM(w http.ResponseWriter, r *http.Request) {
	destHost := r.Host
	hijacker, ok := w.(http.Hijacker)
	if !ok {
		return
	}
	clientConn, _, err := hijacker.Hijack()
	if err != nil {
		return
	}
	defer clientConn.Close()

	clientConn.Write([]byte("HTTP/1.1 200 Connection Established\r\n\r\n"))

	cert, err := certManager.GetCertificate(destHost)
	if err != nil {
		return
	}

	tlsConn := tls.Server(clientConn, &tls.Config{Certificates: []tls.Certificate{*cert}})
	if err := tlsConn.Handshake(); err != nil {
		return
	}
	defer tlsConn.Close()

	reader := bufio.NewReader(tlsConn)
	for {
		req, err := http.ReadRequest(reader)
		if err != nil {
			if err != io.EOF && !strings.Contains(err.Error(), "use of closed network connection") {
				log.Printf("[MITM] Error reading request from tunnel %s: %v", destHost, err)
			}
			break
		}

		// *** WebSocket 处理逻辑 ***
		if strings.ToLower(req.Header.Get("Upgrade")) == "websocket" {
			log.Printf("[MITM] WebSocket Upgrade detected for %s", destHost)
			
			// 1. 连接目标服务器 (使用 processRequest 里的逻辑类似的 Dial)
			// 注意：这里需要建立 TLS 连接
			targetConn, err := tls.Dial("tcp", destHost, &tls.Config{InsecureSkipVerify: true})
			if err != nil {
				log.Printf("[MITM] WS Dial failed: %v", err)
				http.Error(w, "WebSocket Dial Failed", http.StatusBadGateway)
				return
			}
			defer targetConn.Close()

			// 2. 将握手请求写入目标服务器
			// 注意：需要确保请求格式正确，RequestURI 需要是完整路径或相对路径
			req.URL.Scheme = "https"
			req.URL.Host = destHost
			
			// 修正 RequestURI 为路径形式，避免 Write 报错
			req.RequestURI = ""
			if err := req.Write(targetConn); err != nil {
				log.Printf("[MITM] WS Handshake Write failed: %v", err)
				return
			}

			// 3. 将目标服务器的响应写回客户端
			// 我们需要先读取响应，以确保握手成功，或者直接对接流
			// 这里直接对接流比较简单，但无法记录握手状态码
			// 更好的方式是劫持连接后直接进行双向拷贝

			// 启动双向转发
			errChan := make(chan error, 2)
			go func() {
				_, err := io.Copy(targetConn, tlsConn)
				errChan <- err
			}()
			go func() {
				_, err := io.Copy(tlsConn, targetConn)
				errChan <- err
			}()

			<-errChan // 等待一方断开
			log.Printf("[MITM] WebSocket session closed for %s", destHost)
			return // WebSocket 结束后退出循环，因为连接已被接管
		}

		// *** 普通 HTTPS 请求处理逻辑 (原有逻辑) ***
		log.Printf("[MITM] Recv Request: %s %s %s", req.Method, req.URL.String(), req.Host)

		// 计算纯净的 Host (不带端口)
		cleanHost := destHost
		if h, p, err := net.SplitHostPort(destHost); err == nil && p == "443" {
			cleanHost = h
		}

		req.URL.Scheme = "https"
		req.URL.Host = cleanHost
		req.Host = cleanHost // 关键：强制确保 Host 头不带端口，解决 OSS 等服务对 Host 头敏感的问题
		fullURL := req.URL.String()

		var resp *http.Response
		start := time.Now()
		mocked := false

		if rule := findMatch(fullURL); rule != nil {
			if rule.Response.Delay > 0 {
				log.Printf("[MITM MOCK] Applying delay %dms for rule '%s'", rule.Response.Delay, rule.Name)
				time.Sleep(time.Duration(rule.Response.Delay) * time.Millisecond)
			}
			mocked = true
			header := make(http.Header)
			for k, v := range rule.Response.Headers {
				header.Set(k, v)
			}
			resp = &http.Response{
				StatusCode:    rule.Response.StatusCode,
				Proto:         req.Proto,
				ProtoMajor:    req.ProtoMajor,
				ProtoMinor:    req.ProtoMinor,
				Header:        header,
				Body:          io.NopCloser(strings.NewReader(rule.Response.Body)),
				ContentLength: int64(len(rule.Response.Body)),
				Request:       req,
			}
		} else {
			resp, err = forwardRequest(req)
			if err != nil {
				resp = &http.Response{
					StatusCode: 502,
					Proto:      req.Proto,
					Header:     make(http.Header),
					Body:       io.NopCloser(strings.NewReader("Proxy Error")),
					Request:    req,
				}
			}
		}

		addTrafficLog(TrafficLog{
			ID:         fmt.Sprintf("%d", time.Now().UnixNano()),
			Time:       time.Now(),
			Method:     req.Method,
			URL:        fullURL,
			StatusCode: resp.StatusCode,
			Mocked:     mocked,
			Duration:   time.Since(start).String(),
		})

		resp.Write(tlsConn)
		if req.Header.Get("Connection") == "close" {
			break
		}
	}
}

func forwardRequest(r *http.Request) (*http.Response, error) {
	outReq := r.Clone(r.Context())
	outReq.RequestURI = ""
	if outReq.URL.Host == "" {
		outReq.URL.Host = r.Host
	}
	if outReq.URL.Scheme == "" {
		outReq.URL.Scheme = "http"
		if r.TLS != nil {
			outReq.URL.Scheme = "https"
		}
	}
	// 清理代理相关请求头
	for _, h := range []string{"Proxy-Connection", "Connection", "Keep-Alive", "Te", "Trailers"} {
		outReq.Header.Del(h)
	}
	return defaultTransport.RoundTrip(outReq)
}

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "127.0.0.1"
}

func main() {
	var err error
	certManager, err = NewCertManager()
	if err != nil {
		log.Fatal(err)
	}
	loadConfig()

	addr := ":9292"
	log.Printf("Proxy Mock Server 正在运行于 %s\n", addr)
	log.Fatal(http.ListenAndServe(addr, http.HandlerFunc(handleProxy)))
}