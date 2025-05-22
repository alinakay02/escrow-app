<template>
  <div class="network-status">
    <el-alert
      v-if="!store.isConnected"
      type="warning"
      :closable="false"
      show-icon
    >
      <template #title>
        Wallet not connected
      </template>
      <el-button type="primary" size="small" @click="connect" :loading="store.isConnecting">
        Connect Wallet
      </el-button>
    </el-alert>

    <el-alert
      v-else-if="!store.isCorrectNetwork"
      type="warning"
      :closable="false"
      show-icon
    >
      <template #title>
        Wrong Network
      </template>
      <div class="flex items-center gap-2">
        <span>Please switch to Custom Testnet</span>
        <el-button type="primary" size="small" @click="switchNetwork">
          Switch Network
        </el-button>
      </div>
    </el-alert>

    <el-alert
      v-else
      type="success"
      :closable="false"
      show-icon
    >
      <template #title>
        Connected to Custom Testnet
      </template>
      <div class="flex items-center gap-2">
        <span class="text-sm">{{ truncateAddress(store.address) }}</span>
        <el-button type="danger" size="small" @click="disconnect">
          Disconnect
        </el-button>
      </div>
    </el-alert>
  </div>
</template>

<script setup>
import { useWeb3Store } from '@/store';
import { setupNetwork } from '@/config/networks';

const store = useWeb3Store();

async function connect() {
  try {
    await store.connect();
  } catch (error) {
    ElMessage.error(error.message);
  }
}

async function disconnect() {
  store.disconnect();
}

async function switchNetwork() {
  try {
    await setupNetwork();
  } catch (error) {
    ElMessage.error('Failed to switch network');
  }
}

function truncateAddress(address) {
  if (!address) return '';
  return address.slice(0, 6) + '...' + address.slice(-4);
}
</script>

<style scoped>
.network-status {
  position: fixed;
  top: 1rem;
  right: 1rem;
  z-index: 100;
  width: 300px;
}
</style> 