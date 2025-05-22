<template>
  <el-config-provider namespace="ep">
    <div class="app-container">
      <NetworkStatus />
      <NavBar />
      <router-view v-slot="{ Component }">
        <transition name="fade" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </div>
  </el-config-provider>
</template>

<script setup>
import { onMounted } from 'vue';
import { useWeb3Store } from '@/store';
import NetworkStatus from '@/components/NetworkStatus.vue';
import NavBar from '@/components/NavBar.vue';

const store = useWeb3Store();

onMounted(async () => {
  // Try to connect if user was previously connected
  if (window.ethereum && window.ethereum.selectedAddress) {
    try {
      await store.connect();
    } catch (error) {
      console.error('Failed to reconnect:', error);
    }
  }
});
</script>

<style>
.app-container {
  min-height: 100vh;
  background-color: #f5f7fa;
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.15s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
