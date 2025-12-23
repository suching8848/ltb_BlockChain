// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Voting {
    // 候选人结构体
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
    }

    // 候选人数组
    Candidate[] public candidates;
    
    // 已投票地址映射
    mapping(address => bool) public voters;

    // 投票事件
    event Voted(address indexed voter, uint256 indexed candidateIndex);

    // 构造函数，初始化候选人
    constructor() {
        // 初始化一些默认候选人
        addCandidate("候选人 A");
        addCandidate("候选人 B");
        addCandidate("候选人 C");
    }

    // 添加候选人
    function addCandidate(string memory _name) private {
        candidates.push(Candidate(candidates.length, _name, 0));
    }

    // 获取候选人数
    function getCandidatesCount() public view returns (uint256) {
        return candidates.length;
    }

    // 获取候选人信息
    function getCandidate(uint256 _index) public view returns (uint256, string memory, uint256) {
        require(_index < candidates.length, "候选人不存在");
        Candidate memory candidate = candidates[_index];
        return (candidate.id, candidate.name, candidate.voteCount);
    }

    // 投票函数
    function vote(uint256 _candidateIndex) public {
        // 检查是否已经投票
        require(!voters[msg.sender], "你已经投过票了");
        
        // 检查候选人是否存在
        require(_candidateIndex < candidates.length, "候选人不存在");
        
        // 记录投票
        voters[msg.sender] = true;
        
        // 更新候选人票数
        candidates[_candidateIndex].voteCount++;
        
        // 触发投票事件
        emit Voted(msg.sender, _candidateIndex);
    }
}
