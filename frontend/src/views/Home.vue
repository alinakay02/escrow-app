<template>
  <el-main class="p-6">
    <h1 class="text-2xl font-bold mb-4">Мои сделки</h1>
    <el-row :gutter="16">
      <el-col :span="12" v-for="deal in deals" :key="deal.id">
        <DealCard :deal="deal" />
      </el-col>
    </el-row>
  </el-main>
</template>

<script setup>
import { onMounted, ref } from 'vue';
import { useWeb3Store } from '@/store';
import DealCard from '@/components/DealCard.vue';
import { getEscrow } from '@/utils/ethers';

const store = useWeb3Store();
const deals = ref([]);

onMounted(async () => {
  await store.connect();
  const ids = await store.factory.getDealsOfBuyer(store.address);
  deals.value = await Promise.all(
    ids.map(async bn => {
      const id = bn.toNumber();
      const addr = await store.factory.escrows(id);
      const esc = getEscrow(addr, store.provider);
      const raw = await esc.getDetails();
      return {
        id,
        address: addr,
        details: {
          buyer: raw[0],
          seller: raw[1],
          arbiter: raw[2],
          dealId: raw[3].toNumber(),
          amount: raw[4],
          currentState: raw[5],
          disputeRaisedAt: raw[6].toNumber(),
        }
      };
    })
  );
});
</script>
