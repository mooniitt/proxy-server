<template>
  <div class="sidebar-content">
    <div class="rule-header">
      <input type="text" v-model="search" placeholder="搜索规则..." class="search-input">
      <button class="btn btn-primary btn-sm" @click="emit('add')">+ 新增</button>
      <button class="btn btn-secondary btn-sm" @click="toggleAll">
        {{ anyEnabled ? '一键关闭' : '一键开启' }}
      </button>
    </div>
    
    <div v-for="rule in filteredRules" :key="rule.id" class="list-item"
         :class="{ active: currentId === rule.id }" @click="emit('select', rule)">
      <div class="item-info">
        <div class="item-title">{{ rule.name }}</div>
        <div class="item-sub">{{ rule.url }}</div>
      </div>
      <label class="switch" @click.stop>
        <input type="checkbox" v-model="rule.enabled" @change="emit('update')">
        <span class="slider"></span>
      </label>
    </div>
    
    <div v-if="filteredRules.length === 0" class="empty-msg">暂无匹配规则</div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps(['rules', 'currentId'])
const emit = defineEmits(['add', 'select', 'update', 'toggleAll'])
const search = ref('')

const filteredRules = computed(() => {
  const s = search.value.toLowerCase()
  return props.rules.filter(r =>
    r.name.toLowerCase().includes(s) ||
    r.url.toLowerCase().includes(s)
  )
})

const anyEnabled = computed(() => props.rules.some(r => r.enabled))

const toggleAll = () => {
  emit('toggleAll', !anyEnabled.value)
}
</script>

<style scoped>
.sidebar-content {
  flex: 1;
  overflow-y: auto;
}

.rule-header {
  padding: 1rem;
  border-bottom: 1px solid var(--border-color);
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.search-input {
  flex: 1;
  font-size: 0.8rem;
  padding: 0.4rem 0.6rem;
  border: 1px solid var(--border-color);
  border-radius: var(--radius);
  outline: none;
}
.search-input:focus {
    border-color: var(--blue-main);
}

.btn-sm {
  padding: 0.4rem 0.8rem;
  flex-shrink: 0;
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

.list-item:hover { background-color: #f1f5f9; }
.list-item.active {
  background-color: var(--blue-light);
  box-shadow: inset 4px 0 0 var(--blue-main);
}

.item-title {
  font-size: 0.85rem;
  font-weight: 600;
  margin-bottom: 0.2rem;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.item-sub {
  font-size: 0.7rem;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
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

.empty-msg {
  padding: 2rem;
  text-align: center;
  color: #94a3b8;
  font-size: 0.8rem;
}
</style>