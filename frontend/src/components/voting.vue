<template>
  <div class="voting-container">
    <div class="card">
      <div class="header">
        <div class="status-badge" :class="{ 'connected': isConnected }">
          <span class="status-dot"></span>
          <span>{{ isConnected ? "已连接" : "未连接" }}</span>
        </div>
        <div class="account-badge">
          {{ currentAccount ? currentAccount.substring(0, 6) + '...' + currentAccount.substring(currentAccount.length - 4) : '未连接' }}
        </div>
      </div>
      <div class="content">
        <h1 class="title">区块链接票</h1>
        <p class="subtitle">去中心化、透明、不可篡改</p>
        <div class="section">
          <div class="section-header">
            当前票数统计
          </div>
          <div v-if="loading" class="loading-state">
            <div class="spinner"></div>
            <span>加载数据中...</span>
          </div>
          <div v-else class="candidates-list">
            <div v-for="candidate in candidates" :key="candidate.id" class="candidates-row">
              <span class="candidate-name">{{ candidate.name }}</span>
              <div class="vote-count-pill">{{ candidate.voteCount }} 票</div>
            </div>
          </div>
        </div>
        <div class="section vote-action-area">
          <div class="section-header">
            投票操作
          </div>
          <div class="form-group">
            <select v-model="selectedCandidate" class="modern-select" :disabled="!isConnected || isVoted">
              <option value="" disabled>--选择候选人--</option>
              <option v-for="candidate in candidates" :key="candidate.id" :value="candidate.id">{{ candidate.name }}</option>
            </select>
          </div>
          <button class="btn-primary" @click="vote" :disabled="!canVote">确认投票</button>
          <div class="footer-action">
            <button class="btn-outline" @click="connectMetaMask">连接MetaMask钱包</button>
          </div>
        </div>
        <transition name="fade">
          <div v-if="message" class="alert" :class="messageType">
            {{ message }}
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import { ethers } from 'ethers';
import { VotingABI, CONTRACT_ADDRESS } from '../contracts/VotingABI';

const isConnected = ref(false);
const loading = ref(false);
const selectedCandidate = ref('');
const isVoted = ref(false);
const message = ref('');
const messageType = ref('');
const currentAccount = ref('');

const candidates = ref([]);
let contract = null;
let provider = null;
let signer = null;

const canVote = computed(() => {
  return isConnected.value && selectedCandidate.value && !isVoted.value;
});

const connectMetaMask = async () => {
  try {
    if (window.ethereum) {
      provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("eth_requestAccounts", []);
      
      // 获取签名者
      signer = provider.getSigner();
      const address = await signer.getAddress();
      currentAccount.value = address;
      
      // 初始化合约实例
      contract = new ethers.Contract(CONTRACT_ADDRESS, VotingABI, signer);
      
      isConnected.value = true;
      showMessage('已成功连接到MetaMask钱包', 'success');
      
      // 连接后获取候选人数据
      await fetchCandidates();
      
      // 检查用户是否已经投票
      await checkIfVoted();
    } else {
      showMessage('请安装MetaMask钱包', 'error');
    }
  } catch (error) {
    console.error('连接MetaMask失败:', error);
    showMessage('连接MetaMask失败', error.message, 'error');
  }
};

// 获取候选人数据
const fetchCandidates = async () => {
  try {
    loading.value = true;
    if (!contract) return;
    
    // 获取候选人数
    const count = await contract.getCandidatesCount();
    const candidatesList = [];
    
    // 获取每个候选人的信息
    for (let i = 0; i < count; i++) {
      const candidateData = await contract.getCandidate(i);
      candidatesList.push({
        id: candidateData[0].toNumber(),
        name: candidateData[1],
        voteCount: candidateData[2].toNumber()
      });
    }
    
    candidates.value = candidatesList;
  } catch (error) {
    console.error('获取候选人数据失败:', error);
    showMessage('获取候选人数据失败', 'error');
  } finally {
    loading.value = false;
  }
};

// 检查用户是否已经投票
const checkIfVoted = async () => {
  try {
    if (!contract || !currentAccount.value) return;
    
    const hasVoted = await contract.voters(currentAccount.value);
    isVoted.value = hasVoted;
    
    if (hasVoted) {
      showMessage('您已经投过票了', 'info');
    }
  } catch (error) {
    console.error('检查投票状态失败:', error);
  }
};

// 投票功能
const vote = async () => {
  try {
    loading.value = true;
    showMessage('正在提交投票...', 'info');
    
    if (!contract || !selectedCandidate.value) return;
    
    // 调用智能合约的vote函数
    const tx = await contract.vote(selectedCandidate.value);
    await tx.wait();
    
    showMessage('投票成功！', 'success');
    isVoted.value = true;
    
    // 更新候选人票数
    await fetchCandidates();
  } catch (error) {
    console.error('投票失败:', error);
    showMessage(`投票失败: ${error.message}`, 'error');
  } finally {
    loading.value = false;
  }
};

const showMessage = (msg, type) => {
  message.value = msg;
  messageType.value = type;
  setTimeout(() => {
    message.value = '';
  }, 3000);
};
</script>

<style scoped>
.voting-container {
  max-width: 800px;
  margin: 0 auto;
  padding: 20px;
  font-family: 'Arial', sans-serif;
}

.card {
  background-color: #fff;
  border-radius: 12px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
  overflow: hidden;
}

.header {
  background-color: #f8f9fa;
  padding: 16px 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #e9ecef;
}

.status-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 12px;
  background-color: #e9ecef;
  border-radius: 20px;
  font-size: 14px;
  color: #6c757d;
}

.status-badge.connected {
  background-color: #d4edda;
  color: #155724;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background-color: #6c757d;
}

.status-badge.connected .status-dot {
  background-color: #28a745;
}

.account-badge {
  font-family: 'Courier New', monospace;
  font-size: 14px;
  color: #495057;
  background-color: #e9ecef;
  padding: 6px 12px;
  border-radius: 4px;
}

.content {
  padding: 24px;
}

.title {
  margin: 0 0 8px 0;
  font-size: 28px;
  color: #212529;
}

.subtitle {
  margin: 0 0 24px 0;
  font-size: 16px;
  color: #6c757d;
}

.section {
  margin-bottom: 24px;
  padding: 20px;
  background-color: #f8f9fa;
  border-radius: 8px;
}

.section-header {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 16px;
  color: #212529;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 20px;
  color: #6c757d;
}

.spinner {
  width: 30px;
  height: 30px;
  border: 3px solid #e9ecef;
  border-top: 3px solid #007bff;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.candidates-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.candidates-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  background-color: #fff;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
}

.candidate-name {
  font-size: 16px;
  color: #212529;
  font-weight: 500;
}

.vote-count-pill {
  background-color: #007bff;
  color: white;
  padding: 4px 12px;
  border-radius: 20px;
  font-size: 14px;
  font-weight: 600;
}

.vote-action-area {
  background-color: #f8f9fa;
}

.form-group {
  margin-bottom: 16px;
}

.modern-select {
  width: 100%;
  padding: 12px;
  border: 1px solid #ced4da;
  border-radius: 12px;
  font-size: 16px;
  color: #495057;
  background-color: #fff;
  outline: none;
  cursor: pointer;
  transition: border-color 0.5s;
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' viewBox='0 0 24 24' fill='none' stroke='%236c757d' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpolyline points='6 9 12 15 18 9'%3E%3C/polyline%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 12px center;
}

.modern-select:focus {
  border-color: #007bff;
  box-shadow: 0 0 0 3px rgba(0, 123, 255, 0.1);
}

.modern-select:hover:not(:disabled) {
  border-color: #007bff;
}

.btn-primary {
  width: 100%;
  padding: 12px;
  background-color: #007bff;
  color: white;
  border: none;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  box-shadow: 0 4px 6px -1px rgba(0, 123, 255, 0.2);
}

.btn-primary:hover:not(:disabled) {
  background-color: #0069d9;
  transform: translateY(-1px);
  box-shadow: 0 8px 8px -1px rgba(0, 123, 255, 0.3);
}

.btn-primary:disabled {
  background-color: #6c757d;
  cursor: not-allowed;
  box-shadow: none;
}

.footer-action {
  margin-top: 16px;
}

.btn-outline {
  width: 100%;
  padding: 10px;
  background-color: transparent;
  color: #007bff;
  border: 2px solid #007bff;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-outline:hover {
  border-color: #007bff;
  background-color: #e3f2fd;
}

.alert {
  margin-top: 16px;
  padding: 12px;
  border-radius: 8px;
  font-size: 14px;
  text-align: center;
}

.alert.success {
  background-color: #d4edda;
  color: #155724;
  border: 1px solid #c3e6cb;
}

.alert.error {
  background-color: #f8d7da;
  color: #721c24;
  border: 1px solid #f5c6cb;
}

.alert.info {
  background-color: #d1ecf1;
  color: #0c5460;
  border: 1px solid #bee5eb;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>