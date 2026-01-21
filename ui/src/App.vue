<template>
  <IntroAnimation />

  <header>
    <h1><span>⚡</span> Proxy Mock</h1>
    <div class="header-info">
      <div v-if="serverInfo.ip" class="info-pill">
        代理地址：<strong>{{ serverInfo.ip }}:{{ serverInfo.port }}</strong>
      </div>
    </div>
    <div class="header-actions">
      <el-button @click="showHelp = true">💡 使用说明</el-button>
      <el-button @click="regenerateCA">🔄 重生成 CA</el-button>
      <a :href="caUrl" style="text-decoration: none; margin: 0 12px">
        <el-button>📥 下载 CA 证书</el-button>
      </a>
      <el-button @click="exportConfig">导出配置</el-button>
      <el-button type="primary" @click="saveAll">全部保存</el-button>
    </div>
  </header>

  <div class="main-container">
    <!-- Sidebar -->
    <div class="sidebar" :style="{ width: sidebarWidth + 'px' }">
      <div class="resizer" @mousedown="startResizing"></div>
      <div class="tab-header">
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'rules' }"
          @click="activeTab = 'rules'"
        >
          规则配置
        </button>
        <button
          class="tab-btn"
          :class="{ active: activeTab === 'traffic' }"
          @click="activeTab = 'traffic'"
        >
          流量监控
        </button>
      </div>

      <RuleList
        v-if="activeTab === 'rules'"
        :rules="config.rules"
        :currentId="currentRule?.id"
        @add="addRule"
        @select="selectRule"
        @update="saveAll"
        @toggleAll="toggleAllRules"
      />

      <TrafficMonitor
        v-if="activeTab === 'traffic'"
        :traffic="traffic"
        :isPaused="isTrafficPaused"
        @refresh="getTraffic(true)"
        @clear="clearTraffic"
        @togglePause="isTrafficPaused = !isTrafficPaused"
        @select="selectTraffic"
      />
    </div>

    <!-- Editor Area -->
    <div class="editor-container">
      <RuleEditor
        v-if="editorMode === 'rule' && currentRule"
        :rule="currentRule"
        @delete="deleteRule"
        @save="saveAll"
      />

      <TrafficDetail
        v-else-if="editorMode === 'traffic' && selectedLog"
        :log="selectedLog"
        @createRule="createRuleFromTraffic"
      />

      <div v-else class="empty-view">
        <div class="empty-icon">
          <svg
            width="60"
            height="60"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="1"
              d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
            ></path>
          </svg>
        </div>
        <p>选择左侧项目或查看流量实时动态</p>
      </div>
    </div>
  </div>

  <!-- Help Dialog -->
  <el-dialog v-model="showHelp" title="⚡ Proxy Mock 使用说明" width="600px">
    <div class="help-body">
      <h3>1. 设置代理</h3>
      <p>
        将您的设备（手机/浏览器）代理设置为当前机器 IP，端口为
        <code class="code-bg">9292</code>。
      </p>
      <h3>2. HTTPS 证书信任 (关键)</h3>
      <p>若要解密 HTTPS 流量，请下载并信任证书：</p>
      <ul>
        <li>
          <span class="step-badge">iOS</span>
          下载后，在“关于本机”->“证书信任设置”中勾选。
        </li>
        <li>
          <span class="step-badge">Android</span> 在“加密和凭据”中从存储盘安装。
        </li>
        <li>
          <span class="step-badge">PC</span> 导入至“受信任的根证书颁发机构”。
        </li>
      </ul>
      <h3>3. 匹配模式</h3>
      <ul>
        <li><strong>正则匹配</strong>: 建议用于复杂 API 过滤。</li>
        <li><strong>精确匹配</strong>: URL 必须完全一致。</li>
        <li><strong>前缀匹配</strong>: 匹配以特定路径开头的请求。</li>
      </ul>
    </div>
  </el-dialog>
</template>

<script setup>
import { ref, onMounted, onUnmounted, watch, computed } from "vue";
import api, { baseURL } from "./api.js";
import { ElMessage, ElMessageBox } from "element-plus";
import IntroAnimation from "./components/IntroAnimation.vue";
import RuleList from "./components/RuleList.vue";
import TrafficMonitor from "./components/TrafficMonitor.vue";
import RuleEditor from "./components/RuleEditor.vue";
import TrafficDetail from "./components/TrafficDetail.vue";

// State
const config = ref({ rules: [] });
const traffic = ref([]);
const activeTab = ref("rules");
const isTrafficPaused = ref(false);
const wsConnected = ref(true); // Default to true as we're polling anyway
const currentRule = ref(null);
const selectedLog = ref(null);
const editorMode = ref("none");
const showHelp = ref(false);
const serverInfo = ref({ ip: "", port: "" });

// CA 证书下载链接
const caUrl = computed(() => baseURL + "/ca.crt");

// Resizer Logic
const sidebarWidth = ref(380);
const isResizing = ref(false);
const startResizing = () => {
  isResizing.value = true;
  document.addEventListener("mousemove", doResize);
  document.addEventListener("mouseup", stopResizing);
  document.body.classList.add("resizing");
};
const doResize = (e) =>
  (sidebarWidth.value = Math.max(250, Math.min(600, e.clientX)));
const stopResizing = () => {
  isResizing.value = false;
  document.removeEventListener("mousemove", doResize);
  document.removeEventListener("mouseup", stopResizing);
  document.body.classList.remove("resizing");
};

// Helpers
const showToast = (msg, type = "success") => {
  ElMessage({
    message: msg,
    type: type,
    duration: 2000,
  });
};

// API
const getConfig = async () => {
  try {
    const res = await api.get("/api/config");
    config.value = res.data;
    const infoRes = await api.get("/api/info");
    serverInfo.value = infoRes.data;

    const savedRuleId = localStorage.getItem("selectedRuleId");
    if (savedRuleId) {
      const rule = config.value.rules.find((r) => r.id === savedRuleId);
      if (rule) selectRule(rule);
    }
  } catch (e) {
    showToast("加载配置失败", "error");
  }
};

const getTraffic = async (showMessage = false, silent = false) => {
  try {
    const res = await api.get("/api/traffic", { params: { silent } });
    traffic.value = res.data || [];
    if (showMessage && traffic.value.length > 0)
      showToast(`已加载 ${traffic.value.length} 条流量记录`);
  } catch (e) {
    if (showMessage) showToast("获取流量数据失败", "error");
  }
};

const saveAll = async () => {
  try {
    await api.post("/api/config", config.value);
    showToast("配置已生效");
  } catch (e) {
    showToast("保存失败", "error");
  }
};

const clearTraffic = async () => {
  try {
    await api.post("/api/traffic/clear");
    traffic.value = [];
    showToast("流量记录已清空");
  } catch (e) {
    showToast("清空失败", "error");
  }
};

const regenerateCA = async () => {
  try {
    await ElMessageBox.confirm("确定重新生成 CA 证书吗？", "提示", {
      confirmButtonText: "确定",
      cancelButtonText: "取消",
      type: "warning",
    });
    try {
      await api.post("/api/ca/generate");
      showToast("CA 证书已重生成");
    } catch (e) {
      showToast("重生成失败", "error");
    }
  } catch (e) {
    // Cancelled
  }
};

// Actions
const addRule = () => {
  const newRule = {
    id: "rule-" + Date.now(),
    enabled: true,
    name: "API Mock 示例",
    method: "ALL",
    url: "http://example.com/api",
    matchType: "regex",
    response: {
      statusCode: 200,
      headers: { "Content-Type": "application/json" },
      body: '{"status": "ok"}',
      delay: 0,
    },
  };
  config.value.rules.unshift(newRule);
  selectRule(newRule);
};

const selectRule = (rule) => {
  currentRule.value = rule;
  editorMode.value = "rule";
  localStorage.setItem("selectedRuleId", rule.id);
  activeTab.value = "rules"; // Ensure tab switch if selecting from elsewhere
};

const selectTraffic = (log) => {
  selectedLog.value = log;
  editorMode.value = "traffic";
};

const deleteRule = async (id) => {
  try {
    await ElMessageBox.confirm("确定删除此规则？", "提示", {
      confirmButtonText: "确定",
      cancelButtonText: "取消",
      type: "warning",
    });
    config.value.rules = config.value.rules.filter((r) => r.id !== id);
    currentRule.value = null;
    editorMode.value = "none";
    await saveAll();
    showToast("已删除");
  } catch (e) {
    // Cancelled
  }
};

const createRuleFromTraffic = (log) => {
  addRule();
  currentRule.value.url = log.url;
  currentRule.value.method = log.method || "ALL";
  currentRule.value.name = "Mock: " + (log.url.split("/").pop() || "Untitled");

  // Auto-fill response body if available
  if (log.responseBody) {
    currentRule.value.response.body = log.responseBody;
  }

  // Auto-fill Content-Type if available
  if (log.responseHeaders && log.responseHeaders["Content-Type"]) {
    currentRule.value.response.headers["Content-Type"] =
      log.responseHeaders["Content-Type"];
  }
};

const toggleAllRules = (targetState) => {
  config.value.rules.forEach((rule) => (rule.enabled = targetState));
  saveAll();
};

const exportConfig = () => {
  const data = JSON.stringify(config.value, null, 2);
  const blob = new Blob([data], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = "config.json";
  a.click();
};

// Lifecycle
let timer;
onMounted(() => {
  const savedWidth = localStorage.getItem("sidebarWidth");
  if (savedWidth) sidebarWidth.value = parseInt(savedWidth);

  const savedTab = localStorage.getItem("activeTab");
  if (savedTab) activeTab.value = savedTab;

  getConfig();
  timer = setInterval(() => {
    if (!isTrafficPaused.value) getTraffic(false, true);
  }, 2000);
});

onUnmounted(() => clearInterval(timer));

watch(sidebarWidth, (v) => localStorage.setItem("sidebarWidth", v));
watch(activeTab, (v) => localStorage.setItem("activeTab", v));
</script>

<style scoped>
header {
  background-color: #ffffff;
  padding: 0.75rem 2rem;
  border-bottom: 1px solid var(--border-color);
  display: flex;
  justify-content: space-between;
  align-items: center;
  z-index: 100;
}

header h1 {
  font-size: 1.1rem;
  color: var(--blue-dark);
  font-weight: 700;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.header-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-left: 2rem;
  flex: 1;
}

.info-pill {
  background: #f1f5f9;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  color: var(--text-secondary);
  border: 1px solid var(--border-color);
  white-space: nowrap;
}

.header-actions {
  display: flex;
  gap: 0.8rem;
}

.main-container {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.sidebar {
  min-width: 250px;
  max-width: 600px;
  flex-shrink: 0;
  background-color: var(--sidebar-bg);
  border-right: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  position: relative;
}

.resizer {
  width: 8px;
  cursor: col-resize;
  background-color: transparent;
  transition: background-color 0.2s;
  position: absolute;
  right: -4px;
  top: 0;
  bottom: 0;
  z-index: 10;
}

.resizer:hover,
.resizer.active {
  background-color: var(--blue-main);
}

.tab-header {
  display: flex;
  border-bottom: 1px solid var(--border-color);
}

.tab-btn {
  flex: 1;
  padding: 1rem;
  border: none;
  background: none;
  cursor: pointer;
  font-size: 0.85rem;
  font-weight: 600;
  color: var(--text-secondary);
  transition: all 0.2s;
  position: relative;
}

.tab-btn.active {
  color: var(--blue-main);
}

.tab-btn.active::after {
  content: "";
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background-color: var(--blue-main);
}

.sidebar-list {
  padding: 1rem 0;
  border-bottom: 1px solid var(--border-color);
}

.sidebar-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1.25rem;
  cursor: pointer;
  transition: all 0.2s;
}

.sidebar-item:hover {
  background-color: #f1f5f9;
}

.sidebar-item.active {
  background-color: var(--blue-light);
  border-right: 3px solid var(--blue-main);
}

.item-icon {
  font-size: 1.25rem;
}

.item-title {
  font-size: 0.85rem;
  font-weight: 700;
  color: var(--text-main);
}

.item-subtitle {
  font-size: 0.7rem;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 0.4rem;
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.status-dot.online {
  background-color: #10b981;
  box-shadow: 0 0 8px #10b981;
}
.status-dot.offline {
  background-color: #94a3b8;
}

.editor-container {
  flex: 1;
  background: white;
  overflow-y: auto;
  padding: 2rem;
  display: flex;
  flex-direction: column;
}

.empty-view {
  height: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: var(--text-secondary);
  gap: 1rem;
  opacity: 0.6;
}

.empty-icon {
  opacity: 0.3;
}

.help-body h3 {
  margin: 1.5rem 0 0.5rem 0;
  color: var(--blue-dark);
  font-size: 1rem;
}

.help-body p,
.help-body li {
  font-size: 0.9rem;
  line-height: 1.6;
  color: var(--text-main);
  margin-bottom: 0.5rem;
}

.help-body ul {
  padding-left: 1.25rem;
}

.step-badge {
  background: var(--blue-light);
  color: var(--blue-dark);
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: bold;
  margin-right: 6px;
}

.code-bg {
  background: #f1f5f9;
  padding: 2px 4px;
  border-radius: 3px;
  font-weight: bold;
}
</style>
