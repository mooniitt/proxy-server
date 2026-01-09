<template>
  <div v-if="show" class="intro-overlay" :style="containerStyle">
    <div class="intro-container">
      <div class="intro-text">
        <div class="word">
          <span 
            v-for="(style, index) in proxyStyles" 
            :key="'p'+index" 
            class="char highlight"
            :style="style"
          >{{ proxyChars[index] }}</span>
        </div>
        <div class="word">
          <span 
            v-for="(style, index) in mockStyles" 
            :key="'m'+index" 
            class="char"
            :style="style"
          >{{ mockChars[index] }}</span>
        </div>
      </div>
      <div class="intro-sub" :style="subStyle">DASHBOARD</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed } from 'vue'

const show = ref(false)
const proxyChars = 'PROXY'.split('')
const mockChars = 'MOCK'.split('')

// Animation State
const progress = ref(0)
const startTime = ref(0)
const duration = 1500 // Total sequence duration

// Frequency Limit Logic
const checkFrequency = () => {
  const MAX_DAILY_VIEWS = 20
  const STORAGE_KEY = 'intro_stats'
  const today = new Date().toISOString().split('T')[0]
  
  try {
    const statsStr = localStorage.getItem(STORAGE_KEY)
    let stats = statsStr ? JSON.parse(statsStr) : { date: today, count: 0 }
    
    // Reset if date changed
    if (stats.date !== today) {
      stats = { date: today, count: 0 }
    }
    
    if (stats.count < MAX_DAILY_VIEWS) {
      stats.count++
      localStorage.setItem(STORAGE_KEY, JSON.stringify(stats))
      return true
    }
    return false
  } catch (e) {
    console.error('Intro limit check failed', e)
    return true // Fallback to showing
  }
}

// Easing: Elastic Out for "pop" effect
const easeOutElastic = (t) => {
  const c4 = (2 * Math.PI) / 3;
  return t === 0 ? 0 : t === 1 ? 1 : Math.pow(2, -10 * t) * Math.sin((t * 10 - 0.75) * c4) + 1;
}

const getCharStyle = (globalProgress, charIndex, baseDelay) => {
  const startAt = baseDelay + (charIndex * 0.05) // Start time percent (0-1)
  const duration = 0.4 // Duration percent
  
  if (globalProgress < startAt) {
    return { opacity: 0, transform: 'scale(0)' }
  }
  
  const localP = Math.min((globalProgress - startAt) / duration, 1)
  const easeVal = easeOutElastic(localP)
  
  // Exit phase (fade out at the end)
  let opacity = 1
  if (globalProgress > 0.85) {
     opacity = 1 - (globalProgress - 0.85) / 0.15
  }

  return {
    opacity: opacity,
    transform: `scale3d(${easeVal}, ${easeVal}, 1) translateZ(0)`,
  }
}

const proxyStyles = computed(() => {
  return proxyChars.map((_, i) => getCharStyle(progress.value, i, 0.1))
})

const mockStyles = computed(() => {
  return mockChars.map((_, i) => getCharStyle(progress.value, i, 0.4)) // Start 'MOCK' later
})

const subStyle = computed(() => {
  // Subtitle fades in late
  const p = progress.value
  let opacity = 0
  let translateY = 20
  
  if (p > 0.6) {
    const localP = Math.min((p - 0.6) / 0.2, 1)
    opacity = localP
    translateY = 20 * (1 - localP)
  }
  
  // Fade out phase
  if (p > 0.85) {
    opacity = 1 - (p - 0.85) / 0.15
  }
  
  return {
    opacity,
    transform: `translate3d(0, ${translateY}px, 0)`
  }
})

const containerStyle = computed(() => {
  const p = progress.value
  let opacity = 1
  if (p > 0.9) {
    opacity = 1 - ((p - 0.9) / 0.1)
  }
  return { opacity }
})

const animate = (timestamp) => {
  if (!startTime.value) startTime.value = timestamp
  const elapsed = timestamp - startTime.value
  const rawProgress = Math.min(elapsed / duration, 1)
  
  progress.value = rawProgress

  if (rawProgress < 1) {
    requestAnimationFrame(animate)
  } else {
    show.value = false
  }
}

onMounted(() => {
  if (checkFrequency()) {
    show.value = true
    requestAnimationFrame(animate)
  }
})
</script>

<style scoped>
.intro-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  /* Light Gray Background */
  background-color: #f8fafc;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  perspective: 1000px;
  will-change: opacity;
}

.intro-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}

.intro-text {
  font-family: 'Inter', system-ui, sans-serif;
  font-size: 8vw;
  font-weight: 900;
  line-height: 0.9;
  display: flex;
  gap: 1.5rem; /* Space between words */
}

.word {
  display: flex;
}

.char {
  display: inline-block;
  color: #1e293b; /* Dark Slate for MOCK */
  text-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  will-change: transform, opacity;
}

.highlight {
  color: #0ea5e9; /* Blue for PROXY */
}

.intro-sub {
  margin-top: 2rem;
  font-size: 1.5vw;
  font-weight: 700;
  letter-spacing: 0.8em;
  color: #64748b;
  text-transform: uppercase;
  will-change: transform, opacity;
}
</style>