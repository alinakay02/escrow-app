<template>
  <el-header height="60px" class="flex items-center px-6 bg-gray-800 text-white">
    <router-link to="/" class="text-xl font-bold">Escrow DApp</router-link>
    <div class="ml-auto">
      <el-button
        v-if="!address"
        type="primary"
        @click="connect"
      >Connect Wallet</el-button>
      <span v-else>Account: {{ addressShort }}</span>
    </div>
  </el-header>
</template>

<script setup>
import { computed } from 'vue';
import { useWeb3Store } from '@/store';

const store = useWeb3Store();
const address = computed(() => store.address);
const addressShort = computed(() =>
  address.value
    ? address.value.slice(0,6) + '…' + address.value.slice(-4)
    : ''
);

async function connect() {
  await store.connect();
}
</script>

<style scoped>
.el-header { display: flex; }
</style>
