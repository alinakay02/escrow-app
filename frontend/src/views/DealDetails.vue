<template>
  <el-main class="p-6">
    <h1 class="text-2xl font-bold mb-4">Сделка #{{ details.dealId }}</h1>
    <el-card>
      <p><strong>Адрес:</strong> {{ dealAddr }}</p>
      <p><strong>Сумма:</strong> {{ formatEther(details.amount) }} ETH</p>
      <p><strong>Покупатель:</strong> {{ details.buyer }}</p>
      <p><strong>Продавец:</strong> {{ details.seller }}</p>
      <p><strong>Арбитр:</strong> {{ details.arbiter || 'не назначен' }}</p>
      <p><strong>Статус:</strong> <code>{{ states[details.currentState] }}</code></p>
      <div class="mt-4 space-x-2">
        <!-- аналогично DealCard: кнопки по состоянию и роли -->
      </div>
    </el-card>
  </el-main>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useWeb3Store } from '@/store';
import { getEscrow } from '@/utils/ethers';
import { ethers } from 'ethers';

const route = useRoute();
const store = useWeb3Store();
const dealAddr = ref('');
const details = ref({});
const states = ["AWAITING_DELIVERY","DISPUTED","COMPLETE","REFUNDED"];

function formatEther(amount) {
  return ethers.formatEther(amount);
}

onMounted(async () => {
  await store.connect();
  const id = Number(route.params.id);
  const addr = await store.factory.escrows(id);
  dealAddr.value = addr;
  const esc = getEscrow(addr, store.provider);
  const raw = await esc.getDetails();
  details.value = {
    buyer: raw[0],
    seller: raw[1],
    arbiter: raw[2],
    dealId: raw[3].toNumber(),
    amount: raw[4],
    currentState: raw[5],
    disputeRaisedAt: raw[6].toNumber(),
  };
});
</script>
