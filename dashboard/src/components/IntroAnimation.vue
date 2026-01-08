<template>
  <div v-if="show" class="intro-overlay" :class="{ 'fade-out': startExit }">
    <div class="intro-text">
      <div v-for="(group, gIdx) in introData" :key="gIdx" class="intro-word-group" :style="{ color: group.color }">
        <span v-for="(char, cIdx) in group.text" 
              :key="cIdx" 
              class="intro-char"
              :style="{ animationDelay: (group.offset + cIdx) * 0.05 + 's' }">
          {{ char }}
        </span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const show = ref(true)
const startExit = ref(false)

const introData = [
  { text: 'Proxy', color: 'var(--blue-dark)', offset: 0 },
  { text: 'Mock', color: 'var(--blue-main)', offset: 6 }, 
  { text: 'Dashboard', color: 'var(--text-main)', offset: 11 }
]

onMounted(() => {
  setTimeout(() => {
    startExit.value = true
    setTimeout(() => {
      show.value = false
    }, 500)
  }, 1500)
})
</script>

<style scoped>
.intro-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: radial-gradient(circle at center, #ffffff 0%, #f1f5f9 100%);
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
}

.intro-overlay.fade-out {
  opacity: 0;
  transition: opacity 0.5s ease;
  pointer-events: none;
}

.intro-text {
  display: flex;
  gap: 1.5rem;
  font-size: 5.5vw;
  font-weight: 900;
  text-transform: uppercase;
  letter-spacing: -2px;
  line-height: 1;
}

.intro-word-group {
  display: flex;
  white-space: nowrap;
}

.intro-char {
  opacity: 0;
  display: inline-block;
  transform: translateY(40px) scale(0.8);
  animation: intro-reveal 0.6s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
  text-shadow: 0 10px 20px rgba(14, 165, 233, 0.2);
}

@keyframes intro-reveal {
  to {
      opacity: 1;
      transform: translateY(0) scale(1);
  }
}
</style>