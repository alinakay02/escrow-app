<template>
  <el-card class="mb-4">
    <h3 class="text-lg font-semibold mb-2">Сделка #{{ deal.id }}</h3>
    <p>Сумма: {{ formatEther(deal.details.amount) }} ETH</p>
    <p>Статус: <code>{{ states[deal.details.currentState] }}</code></p>
    <template v-if="isBuyer && deal.details.currentState === 0">
      <el-button type="success" @click="confirm" :loading="loading">Подтвердить</el-button>
      <el-button type="danger" @click="dispute" :loading="loading">Оспорить</el-button>
    </template>
    <template v-if="deal.details.currentState === 2 && isBuyer">
      <el-input-number v-model="rating" :min="1" :max="5" @change="leaveRating" />
    </template>
  </el-card>
</template>

<script setup>
import { ref, computed } from 'vue';
import { ethers } from 'ethers';
import { getEscrow } from '@/utils/ethers';
import { useWeb3Store } from '@/store';

const props = defineProps({
  deal: Object
});
const store = useWeb3Store();
const loading = ref(false);
const rating = ref(5);
const states = ["AWAITING_DELIVERY","DISPUTED","COMPLETE","REFUNDED"];
const isBuyer = computed(() =>
  store.address?.toLowerCase() === props.deal.details.buyer.toLowerCase()
);

function formatEther(amount) {
  return ethers.formatEther(amount);
}

async function confirm() {
  loading.value = true;
  const esc = getEscrow(props.deal.address, store.signer);
  await esc.confirmDelivery();
  window.location.reload();
}

async function dispute() {
  loading.value = true;
  const esc = getEscrow(props.deal.address, store.signer);
  await esc.raiseDispute();
  window.location.reload();
}

async function leaveRating(val) {
  loading.value = true;
  const esc = getEscrow(props.deal.address, store.signer);
  await esc.leaveRating(val);
  window.location.reload();
}
</script>
