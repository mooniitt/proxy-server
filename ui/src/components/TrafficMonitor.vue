<template>
  <div class="sidebar-content">
    <div class="traffic-header">
      <div class="header-top">
        <span class="title">实时流量 (最近 100 条)</span>
        <div class="controls">
          <el-button-group>
            <el-button size="small" @click="emit('refresh')" title="刷新">
              <RefreshCcw :size="12" style="margin-right: 4px;" /> 刷新
            </el-button>
            <el-button size="small" type="danger" @click="emit('clear')" title="清除列表">
              <Trash2 :size="12" style="margin-right: 4px;" /> 清除
            </el-button>
            <el-button size="small" @click="emit('togglePause')" :type="isPaused ? 'warning' : 'info'" :title="isPaused ? '继续' : '暂停'">
              <component :is="isPaused ? Play : Pause" :size="12" style="margin-right: 4px;" /> 
              {{ isPaused ? "继续" : "暂停" }}
            </el-button>
          </el-button-group>
        </div>
      </div>
      <el-input
        v-model="search"
        placeholder="搜索流量 (方法, URL)..."
        prefix-icon="Search"
        clearable
        class="mt-2"
      />
    </div>

    <el-scrollbar class="traffic-list-scroll">
      <div>
        <div
          v-for="log in filteredTraffic"
          :key="log.id"
          class="list-item"
          @click="emit('select', log)"
          :style="{ borderLeft: `6px solid ${getColorForString(log.url)}` }"
        >
          <div class="item-info">
            <div class="item-title">
              <span
                class="badge-traffic"
                :style="{ color: log.method === 'POST' ? '#f59e0b' : '#0ea5e9' }"
              >
                {{ log.method }}
              </span>
              <span
                class="status-badge"
                :class="log.statusCode >= 400 ? 'status-4xx' : 'status-2xx'"
              >
                {{ log.statusCode }}
              </span>
              <span v-if="log.mocked" class="status-badge status-mock">MOCK</span>
            </div>
            <div class="item-sub">{{ log.url }}</div>
          </div>
          <div class="item-meta">
            <div>{{ formatTime(log.time) }}</div>
          </div>
        </div>
      </div>

      <div v-if="traffic.length === 0" class="empty-msg">等待请求进入...</div>
    </el-scrollbar>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";
import { RefreshCcw, Trash2, Pause, Play } from 'lucide-vue-next';

const props = defineProps(["traffic", "isPaused"]);
const emit = defineEmits(["refresh", "clear", "togglePause", "select"]);
const search = ref("");

const filteredTraffic = computed(() => {
  const s = search.value.toLowerCase();
  if (!s) return props.traffic;
  return props.traffic.filter(
    (log) =>
      log.method.toLowerCase().includes(s) ||
      log.url.toLowerCase().includes(s) ||
      String(log.statusCode).includes(s)
  );
});

const getColorForString = (str) => {
  let hash = 0;
  if (!str) return `hsl(0, 0%, 90%)`;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  return `hsl(${hash % 360}, 60%, 85%)`;
};

const formatTime = (t) =>
  new Date(t).toLocaleTimeString([], {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
</script>

<style scoped>
.sidebar-content {
  flex: 1;
  overflow-y: auto;
  display: flex;
  flex-direction: column;
}

.traffic-header {
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  gap: 0.8rem;
  flex-shrink: 0;
}

.header-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.title {
  font-size: 0.75rem;
  font-weight: 700;
  color: var(--text-secondary);
}

.controls {
  display: flex;
  gap: 0.5rem;
}

.list-item {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--border-color);
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.list-item:hover {
  background-color: #f1f5f9;
}

.item-info {
  flex: 1;
  min-width: 0;
}

.item-title {
  display: flex;
  align-items: center;
  gap: 4px;
  margin-bottom: 0.2rem;
}

.item-sub {
  font-size: 0.7rem;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-meta {
  font-size: 0.6rem;
  color: #94a3b8;
  text-align: right;
}

.badge-traffic {
  font-size: 0.6rem;
  padding: 1px 4px;
  border-radius: 3px;
  font-weight: bold;
}

.status-badge {
  font-size: 0.65rem;
  padding: 2px 6px;
  border-radius: 4px;
  font-weight: 700;
}

.status-2xx {
  background: #dcfce7;
  color: #166534;
}
.status-4xx,
.status-5xx {
  background: #fee2e2;
  color: #991b1b;
}
.status-mock {
  border: 1px solid var(--blue-main);
  color: var(--blue-main);
}

.empty-msg {
  padding: 2rem;
  text-align: center;
  color: #94a3b8;
  font-size: 0.8rem;
}
</style>
