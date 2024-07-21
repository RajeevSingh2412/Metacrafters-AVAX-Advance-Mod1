# DINOWORLD VAULT AND ERC20 CONTRACTS

This repository contains Solidity smart contracts for the Dinoworld game, including an ERC20 token contract and a Vault contract for managing dinosaurs and user levels.

## DESCRIPTION

This project consists of two main contracts:

1. **ERC20 Contract**: Implements a basic ERC20 token with minting, burning, transferring, and approval functionalities. It represents a token named "Ultratech" with the symbol "UTH".

2. **Vault Contract**: Manages the interaction between users and dinosaurs. It allows users to deposit and withdraw tokens, buy and send dinosaurs, burn tokens, and level up based on their tokens and dinosaurs' power.

## Getting Started

### Steps

1. ***Set up your EVM subnet***: You can use our guide and the Avalanche documentation to create a custom EVM subnet on the Avalanche network.

2. ***Define your native currency***: You can set up your own native currency, which can be used as the in-game currency for your DeFi Kingdom clone.

3. ***Connect to Metamask***: Connect you EVM Subnet to metamask, this can be done by following the steps laid out in our guide.

4. ***Deploy basic building blocks***: You can use Solidity and Remix to deploy the basic building blocks of your game, such as smart contracts for battling, exploring, and trading. These contracts will define the game rules, such as liquidity pools, tokens, and more.


### Executing Program

To run these contracts, you can use Remix, an online Solidity IDE. Follow the steps below to get started:

1. **Open Remix IDE**:
   - Go to [Remix Ethereum IDE](https://remix.ethereum.org/).

2. **Create and Save Files**:
   - Create new files for each contract by clicking on the "+" icon in the left-hand sidebar.
   - Save the files with `.sol` extensions (e.g., `ERC20.sol`, `Vault.sol`).

3. **Paste the Code**:
   - Copy and paste the respective code into each file.

#### ERC20.sol

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "Ultratech";
    string public symbol = "UTH";
    uint8 public decimals = 18;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function transfer(address recipient, uint amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient Balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient Balance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient Balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
```
#### Vault.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Vault {
    IERC20 public immutable token;

    uint public totalSupply;
    mapping(address => uint) public balanceOf;

    struct Dinosaur {
        string name;
        uint power;
        uint price;
    }

    Dinosaur[] public dinosaurs;
    mapping(address => uint[]) public userDinosaurs;
    mapping(address => uint) public userLevel;

    event DinosaurPurchased(address indexed user, uint dinosaurId);
    event DinosaurSent(address indexed from, address indexed to, uint dinosaurId);
    event TokensBurned(address indexed user, uint amount);
    event LevelUp(address indexed user, uint newLevel);

    constructor(address _token) {
        token = IERC20(_token);
        dinosaurs.push(Dinosaur("T-Rex", 100,100));
        dinosaurs.push(Dinosaur("Stegosaurus",80, 80));
        dinosaurs.push(Dinosaur("Velociraptor",90, 90));
        dinosaurs.push(Dinosaur("Triceratops",85, 85));
        dinosaurs.push(Dinosaur("Spinosaurus",110, 110));
        dinosaurs.push(Dinosaur("Brachiosaurus",95, 95));
    }

    function _mint(address _to, uint _shares) private {
        totalSupply += _shares;
        balanceOf[_to] += _shares;
    }

    function _burn(address _from, uint _shares) private {
        totalSupply -= _shares;
        balanceOf[_from] -= _shares;
    }

    function deposit(uint _amount) external {
        uint shares;
        if (totalSupply == 0) {
            shares = _amount;
        } else {
            shares = (_amount * totalSupply) / token.balanceOf(address(this));
        }

        _mint(msg.sender, shares);
        token.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint _shares) external {
        uint amount = (_shares * token.balanceOf(address(this))) / totalSupply;
        _burn(msg.sender, _shares);
        token.transfer(msg.sender, amount);
    }

    function buyDinosaur(uint dinosaurId) external {
        Dinosaur memory dino = dinosaurs[dinosaurId];
        require(token.balanceOf(msg.sender) >= dino.price, "Not enough UTH");

        token.transferFrom(msg.sender, address(this), dino.price);
        userDinosaurs[msg.sender].push(dinosaurId);
        emit DinosaurPurchased(msg.sender, dinosaurId);
    }

    function sendDinosaur(address to, uint dinosaurId) external {
        require(dinosaurId < 6, "Invalid dinosaurId");
        userDinosaurs[to].push(dinosaurId);

        uint[] storage dinos = userDinosaurs[msg.sender];
        for (uint i = 0; i < dinos.length; i++) {
            if (dinos[i] == dinosaurId) {
                dinos[i] = dinos[dinos.length - 1];
                dinos.pop();
                break;
            }
        }
        emit DinosaurSent(msg.sender, to, dinosaurId);
    }

    function burnTokens(uint amount) external {
        token.transferFrom(msg.sender, address(0), amount);
        emit TokensBurned(msg.sender, amount);
    }

    function getAllDinosaurs() external view returns (Dinosaur[] memory) {
        return dinosaurs;
    }
    function levelUp() external {
        uint tokenShare=(balanceOf[msg.sender])/totalSupply;
        uint dinoPower=0;
        uint[] memory userDinos = userDinosaurs[msg.sender];
        for (uint i=0; i<userDinos.length;i++) {
            Dinosaur memory dino=dinosaurs[userDinos[i]];
            dinoPower+=dino.power;
        }
        uint powerShare = (dinoPower) / userDinos.length;

        uint newLevel=tokenShare + powerShare;
        userLevel[msg.sender]=newLevel;
        emit LevelUp(msg.sender, newLevel);
    }

    function getLevel(address _user) view  public returns(uint){
         return userLevel[_user];         
    }

        function getUserDinosaurs(address _user) external view returns (string[] memory) {
        uint[] memory dinoIds = userDinosaurs[_user];
        string[] memory dinoNames = new string[](dinoIds.length);

        for (uint i = 0; i < dinoIds.length; i++) {
            uint dinoId = dinoIds[i];
            dinoNames[i] = dinosaurs[dinoId].name;
        }

        return dinoNames;
    }
}
```

### Compiling the Code

#### Select Compiler Version:
    1. Click on the "Solidity Compiler" tab in the left-hand sidebar.
    2. Ensure the "Compiler" option is set to "0.8.17" (or the version specified).
#### Compile Contracts:
    1. Click on the "Compile ERC20.sol" button.
    2. Click on the "Compile Vault.sol" button.

### Deploying the Contract

#### Deploy ERC20 Contract:
    1. Go to the "Deploy & Run Transactions" tab.
    2. Select "ERC20" from the dropdown menu.
    3. Click "Deploy".
#### Deploy Vault Contract:
    1. After deploying the ERC20 contract, copy its address.
    2. Go to the "Deploy & Run Transactions" tab.
    3. Select "Vault" from the dropdown menu.
    4. Enter the ERC20 contract address in the constructor parameter.
    5. Click "Deploy".

### Interacting with the Contract
1. **Mint Tokens**:
    - Select the mint function.
    - Enter the amount to mint.
    - Click "transact".

2. **Transfer Tokens**:
    - Select the transfer function.
    - Enter the recipient address and amount.
    - Click "transact".
      
3. **Deposit Tokens**:
   - Select the `deposit` function.
   - Enter the amount to deposit.
   - Click "transact".

4. **Withdraw Tokens**:
   - Select the `withdraw` function.
   - Enter the number of shares to withdraw.
   - Click "transact".

5. **Buy Dinosaur**:
   - Select the `buyDinosaur` function.
   - Enter the dinosaur ID.
   - Click "transact".

6. **Send Dinosaur**:
   - Select the `sendDinosaur` function.
   - Enter the recipient address and dinosaur ID.
   - Click "transact".

7. **Burn Tokens**:
   - Select the `burnTokens` function.
   - Enter the amount of tokens to burn.
   - Click "transact".

8. **Level Up**:
   - Select the `levelUp` function.
   - Click "transact".

9. **Get User Dinosaurs**:
   - Select the `getUserDinosaurs` function.
   - Enter the user address.
   - Click "call".

10. **Get User Level**:
    - Select the `getLevel` function.
    - Enter the user address.
    - Click "call".
   
## Authors

Rajeev Singh
[[@rajeevsingh]()](https://www.linkedin.com/in/rajeevsingh2412/)

