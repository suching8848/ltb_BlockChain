<template>
  <div id="app">
    <Voting />
  </div>
</template>

<script setup>
import Voting from './components/voting.vue';
</script>

<style>
#app {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  padding: 20px;
}
</style>