<template>
  <div class="sidebar-content">
    <div class="rule-header">
      <el-input
        v-model="search"
        placeholder="搜索规则..."
        prefix-icon="Search"
        clearable
        class="search-input"
      />
      <el-button-group>
        <el-button type="primary" size="small" @click="emit('add')"
          >+ 新增</el-button
        >
        <el-button size="small" @click="toggleAll">
          {{ anyEnabled ? "一键关闭" : "一键开启" }}
        </el-button>
      </el-button-group>
    </div>

    <div
      v-for="rule in filteredRules"
      :key="rule.id"
      class="list-item"
      :class="{ active: currentId === rule.id }"
      @click="emit('select', rule)"
    >
      <div class="item-info">
        <div class="item-title-row">
          <span
            v-if="rule.method && rule.method !== 'ALL'"
            class="method-badge"
            >{{ rule.method }}</span
          >
          <div class="item-title">{{ rule.name }}</div>
        </div>
        <div class="item-sub" :title="rule.url">{{ rule.url }}</div>
      </div>
      <el-switch v-model="rule.enabled" @change="emit('update')" @click.stop />
    </div>

    <div v-if="filteredRules.length === 0" class="empty-msg">暂无匹配规则</div>
  </div>
</template>

<script setup>
import { ref, computed } from "vue";

const props = defineProps(["rules", "currentId"]);
const emit = defineEmits(["add", "select", "update", "toggleAll"]);
const search = ref("");

const filteredRules = computed(() => {
  const s = search.value.toLowerCase();
  return props.rules.filter(
    (r) => r.name.toLowerCase().includes(s) || r.url.toLowerCase().includes(s),
  );
});

const anyEnabled = computed(() => props.rules.some((r) => r.enabled));

const toggleAll = () => {
  emit("toggleAll", !anyEnabled.value);
};
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

.rule-header .search-input {
  flex: 1;
  min-width: 0; /* Prevent flex item from overflowing */
}

.rule-header .el-button-group {
  flex-shrink: 0; /* Prevent buttons from shrinking */
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
.list-item.active {
  background-color: var(--blue-light);
  box-shadow: inset 4px 0 0 var(--blue-main);
}

.item-info {
  flex: 1;
  min-width: 0; /* Important for flex truncation */
  display: flex;
  flex-direction: column;
}

.item-title-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.2rem;
  min-width: 0;
}

.item-title {
  font-size: 0.85rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
}

.item-sub {
  font-size: 0.7rem;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.method-badge {
  font-size: 0.6rem;
  padding: 1px 4px;
  background: #e2e8f0;
  color: #475569;
  border-radius: 4px;
  font-weight: 700;
  line-height: 1;
}

.empty-msg {
  padding: 2rem;
  text-align: center;
  color: #94a3b8;
  font-size: 0.8rem;
}
</style>
