<template>
  <div v-if="rule" class="editor-content">
    <div class="editor-scroll-area">
      <section>
        <div class="section-title">基础配置</div>
        <div class="grid-2">
          <div class="form-group">
            <label>规则名称</label>
            <input type="text" v-model="rule.name">
          </div>
          <div class="form-group">
            <label>激活状态</label>
            <div style="display: flex; align-items: center; gap: 0.5rem; height: 100%;">
              <label class="switch">
                <input type="checkbox" v-model="rule.enabled">
                <span class="slider"></span>
              </label>
              <span class="status-text">{{ rule.enabled ? '已启用' : '已禁用' }}</span>
            </div>
          </div>
        </div>
      </section>
      
      <section>
        <div class="section-title">匹配逻辑</div>
        <div class="grid-2">
          <div class="form-group">
            <label>匹配方式</label>
            <select v-model="rule.matchType">
              <option value="regex">正则匹配 (Regex)</option>
              <option value="exact">精确匹配 (Exact)</option>
              <option value="prefix">前缀匹配 (Prefix)</option>
            </select>
          </div>
          <div class="form-group">
            <label>URL (支持 http/https)</label>
            <input type="text" v-model="rule.url" placeholder="例如: http://api.com/user">
          </div>
        </div>
      </section>
      
      <section>
        <div class="section-title header-toggle">
          <span>响应 Mock</span>
          <span @click="isResponseMockCollapsed = !isResponseMockCollapsed" class="toggle-icon">
            {{ isResponseMockCollapsed ? '▼' : '▲' }}
          </span>
        </div>
        
        <div v-show="!isResponseMockCollapsed">
          <div class="grid-2">
            <div class="form-group">
              <label>状态码</label>
              <input type="number" v-model.number="rule.response.statusCode">
            </div>
            <div class="form-group">
              <label>Content-Type</label>
              <input type="text" list="content-type-options" 
                     v-model="rule.response.headers['Content-Type']"
                     placeholder="application/json">
              <datalist id="content-type-options">
                <option value="application/json">JSON</option>
                <option value="text/plain">Text</option>
                <option value="text/html">HTML</option>
                <option value="application/xml">XML</option>
                <option value="application/javascript">JavaScript</option>
                <option value="text/css">CSS</option>
              </datalist>
            </div>
          </div>

          <!-- Advanced Options -->
          <div class="advanced-section">
            <div @click="isAdvancedCollapsed = !isAdvancedCollapsed" class="advanced-toggle">
              <span>高级选项 (Headers, Delay)</span>
              <span :style="{ transform: isAdvancedCollapsed ? 'rotate(0deg)' : 'rotate(180deg)' }">▼</span>
            </div>

            <div v-show="!isAdvancedCollapsed" class="advanced-content">
              <div class="form-group mb-1">
                <label>响应延迟 (ms)</label>
                <input type="number" v-model.number="rule.response.delay" min="0" placeholder="0 表示无延迟">
              </div>

              <div class="form-group">
                <div class="headers-header">
                  <label>响应头 (Headers)</label>
                  <button class="btn btn-secondary btn-xs" @click="addHeader">+ 添加</button>
                </div>
                <div class="headers-list">
                  <div v-for="(header, index) in headerList" :key="index" class="header-row">
                    <input type="text" v-model="header.key" placeholder="Key">
                    <input type="text" v-model="header.value" placeholder="Value">
                    <button class="btn btn-danger btn-xs" @click="removeHeader(index)">×</button>
                  </div>
                  <div v-if="headerList.length === 0" class="no-headers">无自定义 Header</div>
                </div>
              </div>
            </div>
          </div>

          <div class="form-group mt-1-5">
            <label>响应体 (Body)</label>
            <div ref="editorRef" class="ace-editor"></div>
          </div>
        </div>
      </section>
    </div>
    
    <div class="editor-footer">
      <button class="btn btn-danger" @click="emit('delete', rule.id)">删除此规则</button>
      <button class="btn btn-primary" @click="emit('save')">保存全部配置</button>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onMounted, nextTick, onBeforeUnmount } from 'vue'
import ace from 'ace-builds'
import 'ace-builds/src-noconflict/theme-tomorrow'
import 'ace-builds/src-noconflict/mode-json'
import 'ace-builds/src-noconflict/mode-javascript'
import 'ace-builds/src-noconflict/mode-html'
import 'ace-builds/src-noconflict/mode-xml'
import 'ace-builds/src-noconflict/mode-text'

// Worker setup for Ace usually requires configuring paths if we want syntax checking workers
// For simplicity in this setup, we might skip worker configuration or rely on defaults.
// FIX: Disable workers to prevent 404 errors for worker scripts in Vite environment
ace.config.set("useWorker", false);
ace.config.set("basePath", ""); // Disable base path auto-detection

const props = defineProps(['rule'])
const emit = defineEmits(['delete', 'save'])

const isResponseMockCollapsed = ref(false)
const isAdvancedCollapsed = ref(true)
const headerList = ref([])
const editorRef = ref(null)
let editorInstance = null
let isSyncingHeaders = false

// Sync Header List
const syncHeadersToList = () => {
  if (!props.rule) return
  const headers = props.rule.response.headers || {}
  const list = []
  for (const [key, value] of Object.entries(headers)) {
    list.push({ key, value })
  }
  headerList.value = list
}

const syncListToHeaders = () => {
  if (!props.rule) return
  const headers = {}
  headerList.value.forEach(h => {
    if (h.key) headers[h.key] = h.value
  })
  props.rule.response.headers = headers
}

const addHeader = () => headerList.value.push({ key: '', value: '' })
const removeHeader = (idx) => headerList.value.splice(idx, 1)

watch(() => props.rule?.response.headers, () => {
  if (isSyncingHeaders) return
  isSyncingHeaders = true
  syncHeadersToList()
  nextTick(() => isSyncingHeaders = false)
}, { deep: true })

watch(headerList, () => {
  if (isSyncingHeaders) return
  isSyncingHeaders = true
  syncListToHeaders()
  nextTick(() => isSyncingHeaders = false)
}, { deep: true })

// Editor Logic
const initEditor = () => {
  if (!editorRef.value) return
  if (editorInstance) editorInstance.destroy()

  editorInstance = ace.edit(editorRef.value)
  editorInstance.setTheme("ace/theme/tomorrow")
  editorInstance.setFontSize(14)
  // FIX: Disable worker for this session to avoid 404s
  editorInstance.session.setOption("useWorker", false);
  
  if (props.rule) {
    editorInstance.setValue(props.rule.response.body || '', -1)
    updateEditorMode()
  }

  editorInstance.session.on('change', () => {
    if (props.rule) {
      props.rule.response.body = editorInstance.getValue()
    }
  })
}

const updateEditorMode = () => {
  if (!props.rule || !editorInstance) return
  const contentType = props.rule.response.headers['Content-Type'] || 'text/plain'
  let mode = 'ace/mode/text'
  if (contentType.includes('json')) mode = 'ace/mode/json'
  else if (contentType.includes('html')) mode = 'ace/mode/html'
  else if (contentType.includes('xml')) mode = 'ace/mode/xml'
  else if (contentType.includes('javascript')) mode = 'ace/mode/javascript'
  editorInstance.session.setMode(mode)
}

watch(() => props.rule, (newRule, oldRule) => {
  if (newRule?.id !== oldRule?.id) {
    if (editorInstance) {
      editorInstance.setValue(newRule.response.body || '', -1)
      updateEditorMode()
      syncHeadersToList()
    }
  }
})

watch(() => props.rule?.response.headers['Content-Type'], updateEditorMode)

onMounted(() => {
  syncHeadersToList()
  nextTick(initEditor)
})

onBeforeUnmount(() => {
  if (editorInstance) editorInstance.destroy()
})
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

input, select {
  padding: 0.6rem 0.8rem;
  border: 1px solid var(--border-color);
  border-radius: var(--radius);
  font-size: 0.85rem;
  outline: none;
}

input:focus, select:focus {
  border-color: var(--blue-main);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.1);
}

.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

/* Switch */
.switch {
  position: relative;
  display: inline-block;
  width: 34px;
  height: 18px;
}
.switch input { display: none; }
.slider {
  position: absolute;
  cursor: pointer;
  top: 0; left: 0; right: 0; bottom: 0;
  background-color: #cbd5e1;
  transition: .4s;
  border-radius: 20px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 14px; width: 14px;
  left: 2px; bottom: 2px;
  background-color: white;
  transition: .4s;
  border-radius: 50%;
}
input:checked + .slider { background-color: var(--blue-main); }
input:checked + .slider:before { transform: translateX(16px); }

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
.header-row input { flex: 1; }
.no-headers {
    font-size: 0.8rem; 
    color: var(--text-secondary); 
    font-style: italic;
}

.btn-xs {
    padding: 2px 8px; 
    font-size: 0.7rem;
}
.mb-1 { margin-bottom: 1rem; }
.mt-1-5 { margin-top: 1.5rem; }

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
.toggle-icon { cursor: pointer; }

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