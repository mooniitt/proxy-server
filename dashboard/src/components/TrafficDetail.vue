<template>
  <div v-if="log" class="editor-content">
    <div class="section-title">请求详情</div>
    <div class="detail-card">
      <div class="url-line"><b>URL:</b> <span>{{ log.url }}</span></div>
      <div class="grid-2 mt-1">
        <div><b>方法:</b> {{ log.method }}</div>
        <div><b>状态码:</b> <span :style="{ color: log.statusCode >= 400 ? 'red' : 'green' }">{{ log.statusCode }}</span></div>
        <div><b>时间:</b> {{ new Date(log.time).toLocaleString() }}</div>
        <div><b>响应耗时:</b> {{ log.duration }}</div>
      </div>
      <div class="detail-footer">
        <div><b>处理类型:</b> {{ log.mocked ? 'MOCK 响应' : '网络透传' }}</div>
      </div>
    </div>
    <div class="mt-1-5">
      <button class="btn btn-primary" @click="emit('createRule', log)">⚡ 基于此请求创建 Mock 规则</button>
    </div>
  </div>
</template>

<script setup>
defineProps(['log'])
const emit = defineEmits(['createRule'])
</script>

<style scoped>
.editor-content {
    flex: 1;
    overflow-y: auto;
}
.section-title {
    font-size: 0.9rem;
    font-weight: 700;
    border-left: 4px solid var(--blue-main);
    padding-left: 0.75rem;
    margin-bottom: 1rem;
}
.detail-card {
    background: #f1f5f9; 
    padding: 1.5rem; 
    border-radius: 8px; 
    font-family: monospace; 
    font-size: 0.85rem; 
    line-height: 1.8;
}
.url-line { word-break: break-all; }
.url-line span { color: var(--blue-dark); }
.grid-2 {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}
.mt-1 { margin-top: 1rem; }
.mt-1-5 { margin-top: 1.5rem; }
.detail-footer {
    margin-top: 1rem; 
    border-top: 1px solid #cbd5e1; 
    padding-top: 1rem;
}
</style>