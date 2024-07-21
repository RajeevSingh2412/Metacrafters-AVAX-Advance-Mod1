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
