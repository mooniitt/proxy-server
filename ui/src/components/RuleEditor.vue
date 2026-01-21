<template>
  <div v-if="rule" class="editor-content">
    <el-scrollbar
      class="editor-scroll-area"
      view-style="padding-right: 12px; display: flex; flex-direction: column; gap: 1.5rem;"
    >
      <section>
        <div class="section-title">基础配置</div>
        <div class="grid-2">
          <div class="form-group">
            <label>规则名称</label>
            <el-input v-model="rule.name" placeholder="请输入规则名称" />
          </div>
          <div class="form-group">
            <label>激活状态</label>
            <div
              style="
                display: flex;
                align-items: center;
                gap: 0.5rem;
                height: 100%;
              "
            >
              <el-switch v-model="rule.enabled" />
              <span class="status-text">{{
                rule.enabled ? "已启用" : "已禁用"
              }}</span>
            </div>
          </div>
        </div>
      </section>

      <section>
        <div class="section-title">匹配逻辑</div>
        <div class="method-url-container">
          <div class="form-group method-group">
            <label>请求方法</label>
            <el-select
              v-model="rule.method"
              placeholder="方法"
              clearable
              default-first-option
            >
              <el-option label="ALL" value="ALL" />
              <el-option label="GET" value="GET" />
              <el-option label="POST" value="POST" />
              <el-option label="PUT" value="PUT" />
              <el-option label="DELETE" value="DELETE" />
              <el-option label="OPTIONS" value="OPTIONS" />
              <el-option label="PATCH" value="PATCH" />
              <el-option label="HEAD" value="HEAD" />
            </el-select>
          </div>
          <div class="form-group match-type-group">
            <label>匹配方式</label>
            <el-select v-model="rule.matchType" placeholder="选择匹配方式">
              <el-option label="正则匹配 (Regex)" value="regex" />
              <el-option label="精确匹配 (Exact)" value="exact" />
              <el-option label="前缀匹配 (Prefix)" value="prefix" />
            </el-select>
          </div>
        </div>
        <div class="form-group mt-1">
          <label>URL (支持 http/https)</label>
          <el-input
            v-model="rule.url"
            placeholder="例如: http://api.com/user"
          />
        </div>
      </section>

      <section>
        <el-collapse v-model="activeCollapse">
          <el-collapse-item name="mock">
            <template #title>
              <div class="section-title mb-0">响应 Mock</div>
            </template>

            <div class="grid-2">
              <div class="form-group">
                <label>状态码</label>
                <el-input-number
                  v-model="rule.response.statusCode"
                  :min="100"
                  :max="599"
                  controls-position="right"
                  style="width: 100%"
                />
              </div>
              <div class="form-group">
                <label>Content-Type</label>
                <el-select
                  v-model="rule.response.headers['Content-Type']"
                  placeholder="选择或输入 Content-Type"
                  filterable
                  allow-create
                  default-first-option
                  clearable
                >
                  <el-option
                    label="JSON (application/json)"
                    value="application/json"
                  />
                  <el-option label="HTML (text/html)" value="text/html" />
                  <el-option label="Text (text/plain)" value="text/plain" />
                  <el-option
                    label="XML (application/xml)"
                    value="application/xml"
                  />
                  <el-option
                    label="JavaScript (application/javascript)"
                    value="application/javascript"
                  />
                  <el-option
                    label="FormData (multipart/form-data)"
                    value="multipart/form-data"
                  />
                </el-select>
              </div>
            </div>

            <!-- Advanced Options -->
            <div class="advanced-section">
              <div
                @click="isAdvancedCollapsed = !isAdvancedCollapsed"
                class="advanced-toggle"
              >
                <span>高级选项 (Headers, Delay)</span>
                <ChevronDown
                  :size="14"
                  :class="{ 'rotate-180': !isAdvancedCollapsed }"
                  style="transition: transform 0.2s"
                />
              </div>

              <div v-show="!isAdvancedCollapsed" class="advanced-content">
                <div class="form-group mb-1">
                  <label>响应延迟 (ms)</label>
                  <el-input-number
                    v-model="rule.response.delay"
                    :min="0"
                    placeholder="0 表示无延迟"
                    controls-position="right"
                    style="width: 200px"
                  />
                </div>

                <div class="form-group">
                  <div class="headers-header">
                    <label>响应头 (Headers)</label>
                    <el-button size="small" @click="addHeader">
                      <Plus :size="12" style="margin-right: 4px" /> 添加
                    </el-button>
                  </div>
                  <div class="headers-list">
                    <div
                      v-for="(header, index) in headerList"
                      :key="index"
                      class="header-row"
                    >
                      <el-input v-model="header.key" placeholder="Key" />
                      <el-input v-model="header.value" placeholder="Value" />
                      <el-button
                        type="danger"
                        size="small"
                        circle
                        @click="removeHeader(index)"
                      >
                        <X :size="12" />
                      </el-button>
                    </div>
                    <div v-if="headerList.length === 0" class="no-headers">
                      无自定义 Header
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="form-group mt-1-5">
              <label>响应体 (Body)</label>
              <div ref="editorRef" class="ace-editor"></div>
            </div>
          </el-collapse-item>
        </el-collapse>
      </section>
    </el-scrollbar>

    <div class="editor-footer">
      <el-button type="danger" @click="emit('delete', rule.id)">
        <Trash2 :size="14" style="margin-right: 4px" /> 删除此规则
      </el-button>
      <el-button type="primary" @click="emit('save')">
        <Save :size="14" style="margin-right: 4px" /> 保存全部配置
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick, onBeforeUnmount } from "vue";
import { ChevronDown, Plus, X, Trash2, Save } from "lucide-vue-next";
import ace from "ace-builds";
import "ace-builds/src-noconflict/theme-tomorrow";
import "ace-builds/src-noconflict/mode-json";
import "ace-builds/src-noconflict/mode-javascript";
import "ace-builds/src-noconflict/mode-html";
import "ace-builds/src-noconflict/mode-xml";
import "ace-builds/src-noconflict/mode-text";

// Worker setup for Ace usually requires configuring paths if we want syntax checking workers
// For simplicity in this setup, we might skip worker configuration or rely on defaults.
// FIX: Disable workers to prevent 404 errors for worker scripts in Vite environment
ace.config.set("useWorker", false);
ace.config.set("basePath", ""); // Disable base path auto-detection

const props = defineProps(["rule"]);
const emit = defineEmits(["delete", "save"]);

const activeCollapse = ref(["mock"]);
const isAdvancedCollapsed = ref(true);
const headerList = ref([]);
const editorRef = ref(null);
let editorInstance = null;
let isSyncingHeaders = false;

// Sync Header List
const syncHeadersToList = () => {
  if (!props.rule) return;
  const headers = props.rule.response.headers || {};
  const list = [];
  for (const [key, value] of Object.entries(headers)) {
    list.push({ key, value });
  }
  headerList.value = list;
};

const syncListToHeaders = () => {
  if (!props.rule) return;
  const headers = {};
  headerList.value.forEach((h) => {
    if (h.key) headers[h.key] = h.value;
  });
  props.rule.response.headers = headers;
};

const addHeader = () => headerList.value.push({ key: "", value: "" });
const removeHeader = (idx) => headerList.value.splice(idx, 1);

watch(
  () => props.rule?.response.headers,
  () => {
    if (isSyncingHeaders) return;
    isSyncingHeaders = true;
    syncHeadersToList();
    nextTick(() => (isSyncingHeaders = false));
  },
  { deep: true },
);

watch(
  headerList,
  () => {
    if (isSyncingHeaders) return;
    isSyncingHeaders = true;
    syncListToHeaders();
    nextTick(() => (isSyncingHeaders = false));
  },
  { deep: true },
);

// Editor Logic
const initEditor = () => {
  if (!editorRef.value) return;
  if (editorInstance) editorInstance.destroy();

  editorInstance = ace.edit(editorRef.value);
  editorInstance.setTheme("ace/theme/tomorrow");
  editorInstance.setFontSize(14);
  // FIX: Disable worker for this session to avoid 404s
  editorInstance.session.setOption("useWorker", false);

  if (props.rule) {
    editorInstance.setValue(props.rule.response.body || "", -1);
    updateEditorMode();
  }

  editorInstance.session.on("change", () => {
    if (props.rule) {
      props.rule.response.body = editorInstance.getValue();
    }
  });
};

const updateEditorMode = () => {
  if (!props.rule || !editorInstance) return;
  const contentType =
    props.rule.response.headers["Content-Type"] || "text/plain";
  let mode = "ace/mode/text";
  if (contentType.includes("json")) mode = "ace/mode/json";
  else if (contentType.includes("html")) mode = "ace/mode/html";
  else if (contentType.includes("xml")) mode = "ace/mode/xml";
  else if (contentType.includes("javascript")) mode = "ace/mode/javascript";
  editorInstance.session.setMode(mode);
};

watch(
  () => props.rule,
  (newRule, oldRule) => {
    if (newRule?.id !== oldRule?.id) {
      if (editorInstance) {
        editorInstance.setValue(newRule.response.body || "", -1);
        updateEditorMode();
        syncHeadersToList();
      }
    }
  },
);

watch(() => props.rule?.response.headers["Content-Type"], updateEditorMode);

onMounted(() => {
  syncHeadersToList();
  nextTick(initEditor);
});

onBeforeUnmount(() => {
  if (editorInstance) editorInstance.destroy();
});
</script>

<style scoped>
.editor-content {
  height: 100%;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.editor-scroll-area {
  flex: 1;
  overflow-y: auto;
  padding-right: 0.5rem;
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.section-title {
  font-size: 0.9rem;
  font-weight: 700;
  border-left: 4px solid var(--blue-main);
  padding-left: 0.75rem;
  margin-bottom: 1rem;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

label {
  font-size: 0.8rem;
  font-weight: 600;
  color: var(--text-secondary);
}

input,
select {
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-color);
  border-radius: var(--radius);
  font-size: 0.85rem;
  outline: none;
}

input:focus,
select:focus {
  border-color: var(--blue-main);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.method-url-container {
  display: flex;
  gap: 1rem;
  margin-bottom: 1rem;
}

.method-group {
  width: 120px;
  flex-shrink: 0;
}

.match-type-group {
  flex: 1;
}

.mt-1 {
  margin-top: 1rem;
}

/* Switch */
.switch {
  position: relative;
  display: inline-block;
  width: 34px;
  height: 18px;
}
.switch input {
  display: none;
}
.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: #cbd5e1;
  transition: 0.4s;
  border-radius: 20px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 14px;
  width: 14px;
  left: 2px;
  bottom: 2px;
  background-color: white;
  transition: 0.4s;
  border-radius: 50%;
}
input:checked + .slider {
  background-color: var(--blue-main);
}
input:checked + .slider:before {
  transform: translateX(16px);
}

.status-text {
  font-size: 0.8rem;
  color: var(--text-secondary);
}

/* Advanced Section */
.advanced-section {
  margin-top: 1rem;
}
.advanced-toggle {
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 0.85rem;
  color: var(--blue-main);
  font-weight: 600;
}
.advanced-content {
  margin-top: 1rem;
  padding: 1rem;
  background: #f8fafc;
  border-radius: 8px;
  border: 1px solid var(--border-color);
}
.headers-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.5rem;
}
.headers-list {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}
.header-row {
  display: flex;
  gap: 0.5rem;
}
.header-row input {
  flex: 1;
}
.no-headers {
  font-size: 0.8rem;
  color: var(--text-secondary);
  font-style: italic;
}

.btn-xs {
  padding: 2px 8px;
  font-size: 0.7rem;
}
.mb-1 {
  margin-bottom: 1rem;
}
.mt-1-5 {
  margin-top: 1.5rem;
}

.ace-editor {
  height: 500px;
  border-radius: 8px;
  border: 1px solid var(--border-color);
}

.header-toggle {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.toggle-icon {
  cursor: pointer;
}

.editor-footer {
  flex-shrink: 0;
  display: flex;
  justify-content: space-between;
  margin-top: 1rem;
  padding-top: 1rem;
  border-top: 1px solid var(--border-color);
  background: white;
}
</style>
