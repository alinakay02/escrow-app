import { createRouter, createWebHistory } from 'vue-router';
import Home from '@/views/Home.vue';
import DealDetails from '@/views/DealDetails.vue';

const routes = [
  { path: '/', component: Home },
  { path: '/deals/:id', component: DealDetails, props: true }
];

export default createRouter({
  history: createWebHistory(),
  routes
});
